import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/todo_list.dart';
import '../models/todo_item.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();
  
  SupabaseService._();
  
  SupabaseClient get client => Supabase.instance.client;
  
  // =====================================================
  // INITIALIZATION
  // =====================================================
  
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      debug: true, // Set to false in production
    );
  }
  
  // =====================================================
  // TODO LISTS OPERATIONS
  // =====================================================
  
  /// Get all todo lists (public and shared ones)
  Future<List<TodoList>> getAllTodoLists() async {
    try {
      final response = await client
          .from('todo_lists')
          .select('''
            *,
            todo_items(*)
          ''')
          .eq('is_archived', false)
          .order('created_at', ascending: false);
      
      return (response as List).map((json) => _todoListFromSupabase(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch todo lists: $e');
    }
  }
  
  /// Get a specific todo list by ID
  Future<TodoList?> getTodoListById(String id) async {
    try {
      final response = await client
          .from('todo_lists')
          .select('''
            *,
            todo_items(*),
            source_links:todo_list_links!source_list_id(target_list_id),
            target_links:todo_list_links!target_list_id(source_list_id)
          ''')
          .eq('id', id)
          .eq('is_archived', false)
          .maybeSingle();
      
      if (response == null) return null;
      return _todoListFromSupabase(response);
    } catch (e) {
      throw Exception('Failed to fetch todo list: $e');
    }
  }
  
  /// Get a todo list by share token (for public access)
  Future<TodoList?> getTodoListByShareToken(String shareToken) async {
    try {
      final response = await client
          .from('todo_lists')
          .select('''
            *,
            todo_items(*)
          ''')
          .eq('share_token', shareToken)
          .eq('is_shared', true)
          .eq('is_archived', false)
          .maybeSingle();
      
      if (response == null) return null;
      
      // Log the access
      await _logShareAccess(shareToken, 'view');
      
      return _todoListFromSupabase(response);
    } catch (e) {
      throw Exception('Failed to fetch shared todo list: $e');
    }
  }
  
  /// Create a new todo list
  Future<TodoList> createTodoList({
    required String title,
    String description = '',
    DateTime? scheduledDate,
    String? scheduleType = 'none',
    bool isShared = false,
    bool allowAnonymousEdit = false,
  }) async {
    try {
      final data = {
        'title': title,
        'description': description,
        'scheduled_date': scheduledDate?.toIso8601String(),
        'schedule_type': scheduleType,
        'is_shared': isShared,
        'allow_anonymous_edit': allowAnonymousEdit,
      };
      
      final response = await client
          .from('todo_lists')
          .insert(data)
          .select()
          .single();
      
      return _todoListFromSupabase(response);
    } catch (e) {
      throw Exception('Failed to create todo list: $e');
    }
  }
  
  /// Update a todo list
  Future<TodoList> updateTodoList(TodoList todoList) async {
    try {
      final data = {
        'title': todoList.title,
        'description': todoList.description,
        'scheduled_date': todoList.scheduledDate?.toIso8601String(),
        'is_shared': todoList.isShared,
      };
      
      final response = await client
          .from('todo_lists')
          .update(data)
          .eq('id', todoList.id)
          .select()
          .single();
      
      return _todoListFromSupabase(response);
    } catch (e) {
      throw Exception('Failed to update todo list: $e');
    }
  }
  
  /// Delete a todo list
  Future<void> deleteTodoList(String id) async {
    try {
      await client
          .from('todo_lists')
          .update({'is_archived': true})
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete todo list: $e');
    }
  }
  
  /// Generate or update share token for a todo list
  Future<String> generateShareToken(String todoListId) async {
    try {
      final response = await client
          .from('todo_lists')
          .update({
            'is_shared': true,
            'share_token': null, // Will trigger auto-generation
          })
          .eq('id', todoListId)
          .select('share_token')
          .single();
      
      return response['share_token'] as String;
    } catch (e) {
      throw Exception('Failed to generate share token: $e');
    }
  }
  
  // =====================================================
  // TODO ITEMS OPERATIONS
  // =====================================================
  
  /// Add item to todo list
  Future<TodoItem> addItemToList(String listId, TodoItem item) async {
    try {
      final data = {
        'todo_list_id': listId,
        'title': item.title,
        'description': item.description,
        'priority': item.priority.name,
        'due_date': item.dueDate?.toIso8601String(),
        'is_completed': item.isCompleted,
      };
      
      final response = await client
          .from('todo_items')
          .insert(data)
          .select()
          .single();
      
      return _todoItemFromSupabase(response);
    } catch (e) {
      throw Exception('Failed to add item to list: $e');
    }
  }
  
  /// Update todo item
  Future<TodoItem> updateTodoItem(TodoItem item) async {
    try {
      final data = {
        'title': item.title,
        'description': item.description,
        'priority': item.priority.name,
        'due_date': item.dueDate?.toIso8601String(),
        'is_completed': item.isCompleted,
      };
      
      if (item.isCompleted) {
        data['completed_at'] = DateTime.now().toIso8601String();
      }
      
      final response = await client
          .from('todo_items')
          .update(data)
          .eq('id', item.id)
          .select()
          .single();
      
      return _todoItemFromSupabase(response);
    } catch (e) {
      throw Exception('Failed to update todo item: $e');
    }
  }
  
  /// Update todo item in a shared list using share token for permission validation
  Future<TodoItem> updateTodoItemInSharedList(TodoItem item, String shareToken) async {
    try {
      // First verify the share token is valid and allows anonymous edit
      final shareCheckResponse = await client
          .from('todo_lists')
          .select('id, allow_anonymous_edit')
          .eq('share_token', shareToken)
          .eq('is_shared', true)
          .eq('is_archived', false)
          .maybeSingle();
      
      if (shareCheckResponse == null) {
        throw Exception('Invalid share token or list not found');
      }
      
      if (shareCheckResponse['allow_anonymous_edit'] != true) {
        throw Exception('This shared list does not allow editing');
      }
      
      // Update the todo item
      final data = {
        'title': item.title,
        'description': item.description,
        'priority': item.priority.name,
        'due_date': item.dueDate?.toIso8601String(),
        'is_completed': item.isCompleted,
      };
      
      if (item.isCompleted) {
        data['completed_at'] = DateTime.now().toIso8601String();
      }
      
      final response = await client
          .from('todo_items')
          .update(data)
          .eq('id', item.id)
          .eq('todo_list_id', shareCheckResponse['id']) // Extra security check
          .select()
          .single();
      
      // Log the edit action
      await _logShareAccess(shareToken, 'edit');
      
      return _todoItemFromSupabase(response);
    } catch (e) {
      throw Exception('Failed to update todo item in shared list: $e');
    }
  }
  
  /// Delete todo item
  Future<void> deleteTodoItem(String itemId) async {
    try {
      await client
          .from('todo_items')
          .delete()
          .eq('id', itemId);
    } catch (e) {
      throw Exception('Failed to delete todo item: $e');
    }
  }
  
  // =====================================================
  // TODO LIST LINKING
  // =====================================================
  
  /// Link two todo lists
  Future<void> linkTodoLists(String sourceListId, String targetListId) async {
    try {
      await client
          .from('todo_list_links')
          .insert({
            'source_list_id': sourceListId,
            'target_list_id': targetListId,
          });
    } catch (e) {
      throw Exception('Failed to link todo lists: $e');
    }
  }
  
  /// Get linked todo lists
  Future<List<TodoList>> getLinkedTodoLists(String listId) async {
    try {
      // Get both source and target links
      final links = await client
          .from('todo_list_links')
          .select('source_list_id, target_list_id')
          .or('source_list_id.eq.$listId,target_list_id.eq.$listId');
      
      // Extract linked list IDs
      final linkedIds = <String>{};
      for (final link in links) {
        if (link['source_list_id'] == listId) {
          linkedIds.add(link['target_list_id']);
        } else {
          linkedIds.add(link['source_list_id']);
        }
      }
      
      if (linkedIds.isEmpty) return [];
      
      // Fetch the linked lists
      final response = await client
          .from('todo_lists')
          .select('''
            *,
            todo_items(*)
          ''')
          .inFilter('id', linkedIds.toList())
          .eq('is_archived', false);
      
      return (response as List).map((json) => _todoListFromSupabase(json)).toList();
    } catch (e) {
      throw Exception('Failed to get linked todo lists: $e');
    }
  }
  
  /// Remove link between todo lists
  Future<void> unlinkTodoLists(String sourceListId, String targetListId) async {
    try {
      await client
          .from('todo_list_links')
          .delete()
          .or('and(source_list_id.eq.$sourceListId,target_list_id.eq.$targetListId),and(source_list_id.eq.$targetListId,target_list_id.eq.$sourceListId)');
    } catch (e) {
      throw Exception('Failed to unlink todo lists: $e');
    }
  }
  
  // =====================================================
  // SCHEDULING AND CALENDAR
  // =====================================================
  
  /// Get scheduled todo lists for a specific date
  Future<List<TodoList>> getScheduledTodoListsForDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final response = await client
          .from('todo_lists')
          .select('''
            *,
            todo_items(*)
          ''')
          .gte('scheduled_date', startOfDay.toIso8601String())
          .lt('scheduled_date', endOfDay.toIso8601String())
          .eq('is_archived', false)
          .order('scheduled_date', ascending: true);
      
      return (response as List).map((json) => _todoListFromSupabase(json)).toList();
    } catch (e) {
      throw Exception('Failed to get scheduled todo lists: $e');
    }
  }
  
  /// Get overdue todo lists
  Future<List<TodoList>> getOverdueTodoLists() async {
    try {
      final now = DateTime.now();
      final response = await client
          .from('todo_lists_with_stats')
          .select()
          .lt('scheduled_date', now.toIso8601String())
          .eq('is_overdue', true);
      
      return (response as List).map((json) => _todoListFromSupabase(json)).toList();
    } catch (e) {
      throw Exception('Failed to get overdue todo lists: $e');
    }
  }
  
  // =====================================================
  // ANALYTICS AND LOGGING
  // =====================================================
  
  /// Log share access for analytics
  Future<void> _logShareAccess(String shareToken, String action) async {
    try {
      await client
          .from('share_access_log')
          .insert({
            'share_token': shareToken,
            'action': action,
            'access_time': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      // Don't throw error for logging failures
      print('Failed to log share access: $e');
    }
  }
  
  /// Get share access statistics
  Future<Map<String, dynamic>> getShareAccessStats(String todoListId) async {
    try {
      final response = await client
          .from('share_access_log')
          .select('action, access_time')
          .eq('todo_list_id', todoListId)
          .order('access_time', ascending: false);
      
      return {
        'total_views': response.length,
        'recent_accesses': response.take(10).toList(),
      };
    } catch (e) {
      throw Exception('Failed to get share access stats: $e');
    }
  }
  
  // =====================================================
  // HELPER METHODS
  // =====================================================
  
  /// Convert Supabase response to TodoList object
  TodoList _todoListFromSupabase(Map<String, dynamic> json) {
    final items = (json['todo_items'] as List<dynamic>?)
        ?.map((item) => _todoItemFromSupabase(item))
        .toList() ?? [];
    
    // Extract linked list IDs
    final sourceLinks = json['source_links'] as List<dynamic>? ?? [];
    final targetLinks = json['target_links'] as List<dynamic>? ?? [];
    final linkedIds = <String>[];
    
    for (final link in sourceLinks) {
      linkedIds.add(link['target_list_id'] as String);
    }
    for (final link in targetLinks) {
      linkedIds.add(link['source_list_id'] as String);
    }
    
    return TodoList(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      items: items,
      createdAt: DateTime.parse(json['created_at']),
      scheduledDate: json['scheduled_date'] != null 
          ? DateTime.parse(json['scheduled_date']) 
          : null,
      shareableLink: json['share_token'] != null 
          ? _generateShareableUrl(json['share_token'])
          : null,
      isShared: json['is_shared'] ?? false,
      linkedTodoListIds: linkedIds,
    );
  }
  
  /// Convert Supabase response to TodoItem object
  TodoItem _todoItemFromSupabase(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      isCompleted: json['is_completed'] ?? false,
      dueDate: json['due_date'] != null 
          ? DateTime.parse(json['due_date']) 
          : null,
      priority: Priority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => Priority.medium,
      ),
    );
  }
  
  /// Generate shareable URL from token
  String _generateShareableUrl(String token) {
    // Use configured domain from SupabaseConfig
    return '${SupabaseConfig.appDomain}#/shared/$token';
  }
}
