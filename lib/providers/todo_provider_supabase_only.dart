import 'package:flutter/foundation.dart';
import '../models/todo_list.dart';
import '../models/todo_item.dart';
import '../services/supabase_service.dart';
import '../config/supabase_config.dart';

class TodoProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService.instance;
  
  List<TodoList> _todoLists = [];
  TodoList? _currentTodoList;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  List<TodoList> get todoLists => _todoLists;
  TodoList? get currentTodoList => _currentTodoList;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;

  List<TodoList> get scheduledTodoLists => _todoLists
      .where((list) => list.isScheduled)
      .toList()
      ..sort((a, b) => a.scheduledDate!.compareTo(b.scheduledDate!));

  List<TodoList> get unscheduledTodoLists => _todoLists
      .where((list) => !list.isScheduled)
      .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<TodoList> get overdueTodoLists => _todoLists
      .where((list) => list.isOverdue)
      .toList();

  // Check if Supabase is properly configured
  bool get isSupabaseConfigured {
    final isConfigured = SupabaseConfig.supabaseUrl != 'YOUR_SUPABASE_URL' &&
        SupabaseConfig.supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY';
    debugPrint('Supabase configuration check:');
    debugPrint('URL: ${SupabaseConfig.supabaseUrl}');
    debugPrint('Key: ${SupabaseConfig.supabaseAnonKey.substring(0, 20)}...');
    debugPrint('Is configured: $isConfigured');
    return isConfigured;
  }

  // Initialize and load all todo lists from Supabase
  Future<void> loadTodoLists() async {
    if (!isSupabaseConfigured) {
      debugPrint('Supabase is not properly configured. Please check your credentials.');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _todoLists = await _supabaseService.getAllTodoLists();
      debugPrint('Successfully loaded ${_todoLists.length} todo lists from Supabase');
    } catch (e) {
      debugPrint('Error loading todo lists from Supabase: $e');
      _todoLists = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new todo list
  Future<TodoList> createTodoList({
    required String title,
    String description = '',
    DateTime? scheduledDate,
    bool generateShareableLink = false,
  }) async {
    if (!isSupabaseConfigured) {
      throw Exception('Supabase is not properly configured. Please check your credentials.');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final newTodoList = await _supabaseService.createTodoList(
        title: title,
        description: description,
        scheduledDate: scheduledDate,
        isShared: generateShareableLink,
        allowAnonymousEdit: generateShareableLink,
      );

      _todoLists.add(newTodoList);
      debugPrint('Created todo list: ${newTodoList.title}');
      return newTodoList;
    } catch (e) {
      debugPrint('Error creating todo list: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update todo list
  Future<void> updateTodoList(TodoList updatedList) async {
    if (!isSupabaseConfigured) {
      throw Exception('Supabase is not properly configured.');
    }

    try {
      await _supabaseService.updateTodoList(updatedList);
      
      // Refresh the entire list to ensure we have the latest data
      await loadTodoLists();
      
      // Also update the current todo list if it's the one being updated
      if (_currentTodoList?.id == updatedList.id) {
        await loadCurrentTodoList(updatedList.id);
      }
    } catch (e) {
      debugPrint('Error updating todo list: $e');
      rethrow;
    }
  }

  // Delete todo list
  Future<void> deleteTodoList(String id) async {
    if (!isSupabaseConfigured) {
      throw Exception('Supabase is not properly configured.');
    }

    try {
      await _supabaseService.deleteTodoList(id);
      _todoLists.removeWhere((list) => list.id == id);
      if (_currentTodoList?.id == id) {
        _currentTodoList = null;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting todo list: $e');
      rethrow;
    }
  }

  // Add item to current todo list
  Future<void> addTodoItem(TodoItem item) async {
    if (_currentTodoList == null || !isSupabaseConfigured) return;

    try {
      await _supabaseService.addItemToList(_currentTodoList!.id, item);
      // Reload current todo list to get updated items
      await loadCurrentTodoList(_currentTodoList!.id);
      // Refresh main todo lists to update statistics and UI
      await loadTodoLists();
    } catch (e) {
      debugPrint('Error adding todo item: $e');
      rethrow;
    }
  }

  // Update todo item
  Future<void> updateTodoItem(TodoItem updatedItem) async {
    if (_currentTodoList == null || !isSupabaseConfigured) return;

    try {
      await _supabaseService.updateTodoItem(updatedItem);
      // Reload current todo list to get updated items
      await loadCurrentTodoList(_currentTodoList!.id);
      // Refresh main todo lists to update statistics and UI
      await loadTodoLists();
    } catch (e) {
      debugPrint('Error updating todo item: $e');
      rethrow;
    }
  }

  // Delete todo item
  Future<void> deleteTodoItem(String itemId) async {
    if (_currentTodoList == null || !isSupabaseConfigured) return;

    try {
      await _supabaseService.deleteTodoItem(itemId);
      // Reload current todo list to get updated items
      await loadCurrentTodoList(_currentTodoList!.id);
      // Refresh main todo lists to update statistics and UI
      await loadTodoLists();
    } catch (e) {
      debugPrint('Error deleting todo item: $e');
      rethrow;
    }
  }

  // Link two todo lists
  Future<void> linkTodoLists(String sourceListId, String targetListId) async {
    if (!isSupabaseConfigured) return;

    try {
      await _supabaseService.linkTodoLists(sourceListId, targetListId);
      debugPrint('Linked todo lists: $sourceListId -> $targetListId');
    } catch (e) {
      debugPrint('Error linking todo lists: $e');
      rethrow;
    }
  }

  // Get linked todo lists
  Future<List<TodoList>> getLinkedTodoLists(String listId) async {
    if (!isSupabaseConfigured) return [];

    try {
      return await _supabaseService.getLinkedTodoLists(listId);
    } catch (e) {
      debugPrint('Error getting linked todo lists: $e');
      return [];
    }
  }

  // Schedule a todo list
  Future<void> scheduleTodoList(String listId, DateTime scheduledDate) async {
    if (!isSupabaseConfigured) return;

    try {
      // Get the todo list first
      final todoList = await _supabaseService.getTodoListById(listId);
      if (todoList != null) {
        // Update the todo list with the new scheduled date
        final updatedList = TodoList(
          id: todoList.id,
          title: todoList.title,
          description: todoList.description,
          items: todoList.items,
          createdAt: todoList.createdAt,
          scheduledDate: scheduledDate,
          shareableLink: todoList.shareableLink,
        );
        
        await _supabaseService.updateTodoList(updatedList);
        await loadTodoLists(); // Refresh the list
      }
    } catch (e) {
      debugPrint('Error scheduling todo list: $e');
      rethrow;
    }
  }

  // Get scheduled todo lists for a specific date
  Future<List<TodoList>> getScheduledTodoListsForDate(DateTime date) async {
    if (!isSupabaseConfigured) return [];

    try {
      return await _supabaseService.getScheduledTodoListsForDate(date);
    } catch (e) {
      debugPrint('Error getting scheduled todo lists: $e');
      return [];
    }
  }

  // Get todo list by shareable link
  Future<TodoList?> getTodoListByShareableLink(String linkOrToken) async {
    if (!isSupabaseConfigured) return null;

    try {
      // Extract token if it's a full URL
      String token = linkOrToken;
      if (linkOrToken.contains('/shared/')) {
        token = linkOrToken.split('/shared/').last;
      }
      
      return await _supabaseService.getTodoListByShareToken(token);
    } catch (e) {
      debugPrint('Error getting todo list by shareable link: $e');
      return null;
    }
  }

  // Get todo list by ID
  Future<TodoList?> getTodoListById(String id) async {
    if (!isSupabaseConfigured) return null;

    try {
      return await _supabaseService.getTodoListById(id);
    } catch (e) {
      debugPrint('Error getting todo list by ID: $e');
      return null;
    }
  }

  // Generate shareable link for todo list
  Future<String?> generateShareableLink(String listId) async {
    if (!isSupabaseConfigured) return null;

    try {
      final token = await _supabaseService.generateShareToken(listId);
      return '${SupabaseConfig.appDomain}/#/shared/$token';
    } catch (e) {
      debugPrint('Error generating shareable link: $e');
      return null;
    }
  }

  // Load a specific todo list and set as current
  Future<void> loadCurrentTodoList(String listId) async {
    if (!isSupabaseConfigured) return;

    try {
      _currentTodoList = await _supabaseService.getTodoListById(listId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading current todo list: $e');
    }
  }

  // Set selected date for calendar
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  // Set current todo list
  void setCurrentTodoList(TodoList? todoList) {
    _currentTodoList = todoList;
    notifyListeners();
  }

  // Clear current todo list
  void clearCurrentTodoList() {
    _currentTodoList = null;
    notifyListeners();
  }

  // Refresh data
  Future<void> refresh() async {
    await loadTodoLists();
  }
}
