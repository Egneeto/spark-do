import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/todo_list.dart';
import '../models/todo_item.dart';

class TodoService {
  static const String _todoListsKey = 'todo_lists';
  static const String _shareableLinksKey = 'shareable_links';
  final Uuid _uuid = const Uuid();

  // Get all todo lists
  Future<List<TodoList>> getAllTodoLists() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_todoListsKey);
    
    if (jsonString == null) return [];
    
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => TodoList.fromJson(json)).toList();
  }

  // Save todo lists
  Future<void> saveTodoLists(List<TodoList> todoLists) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(todoLists.map((list) => list.toJson()).toList());
    await prefs.setString(_todoListsKey, jsonString);
  }

  // Create a new todo list
  Future<TodoList> createTodoList({
    required String title,
    String description = '',
    DateTime? scheduledDate,
    bool generateShareableLink = false,
  }) async {
    final id = _uuid.v4();
    final shareableLink = generateShareableLink ? _generateShareableLink(id) : null;
    
    final todoList = TodoList(
      id: id,
      title: title,
      description: description,
      createdAt: DateTime.now(),
      scheduledDate: scheduledDate,
      shareableLink: shareableLink,
      isShared: generateShareableLink,
    );

    final todoLists = await getAllTodoLists();
    todoLists.add(todoList);
    await saveTodoLists(todoLists);

    if (generateShareableLink) {
      await _saveShareableLink(shareableLink!, id);
    }

    return todoList;
  }

  // Update todo list
  Future<void> updateTodoList(TodoList updatedList) async {
    final todoLists = await getAllTodoLists();
    final index = todoLists.indexWhere((list) => list.id == updatedList.id);
    
    if (index != -1) {
      todoLists[index] = updatedList;
      await saveTodoLists(todoLists);
    }
  }

  // Delete todo list
  Future<void> deleteTodoList(String id) async {
    final todoLists = await getAllTodoLists();
    todoLists.removeWhere((list) => list.id == id);
    await saveTodoLists(todoLists);
  }

  // Add item to todo list
  Future<void> addItemToList(String listId, TodoItem item) async {
    final todoLists = await getAllTodoLists();
    final listIndex = todoLists.indexWhere((list) => list.id == listId);
    
    if (listIndex != -1) {
      final updatedItems = List<TodoItem>.from(todoLists[listIndex].items);
      updatedItems.add(item);
      
      todoLists[listIndex] = todoLists[listIndex].copyWith(items: updatedItems);
      await saveTodoLists(todoLists);
    }
  }

  // Update item in todo list
  Future<void> updateItemInList(String listId, TodoItem updatedItem) async {
    final todoLists = await getAllTodoLists();
    final listIndex = todoLists.indexWhere((list) => list.id == listId);
    
    if (listIndex != -1) {
      final updatedItems = List<TodoItem>.from(todoLists[listIndex].items);
      final itemIndex = updatedItems.indexWhere((item) => item.id == updatedItem.id);
      
      if (itemIndex != -1) {
        updatedItems[itemIndex] = updatedItem;
        todoLists[listIndex] = todoLists[listIndex].copyWith(items: updatedItems);
        await saveTodoLists(todoLists);
      }
    }
  }

  // Remove item from todo list
  Future<void> removeItemFromList(String listId, String itemId) async {
    final todoLists = await getAllTodoLists();
    final listIndex = todoLists.indexWhere((list) => list.id == listId);
    
    if (listIndex != -1) {
      final updatedItems = List<TodoItem>.from(todoLists[listIndex].items);
      updatedItems.removeWhere((item) => item.id == itemId);
      
      todoLists[listIndex] = todoLists[listIndex].copyWith(items: updatedItems);
      await saveTodoLists(todoLists);
    }
  }

  // Link todo lists
  Future<void> linkTodoLists(String sourceListId, String targetListId) async {
    final todoLists = await getAllTodoLists();
    final sourceIndex = todoLists.indexWhere((list) => list.id == sourceListId);
    
    if (sourceIndex != -1) {
      final linkedIds = List<String>.from(todoLists[sourceIndex].linkedTodoListIds);
      if (!linkedIds.contains(targetListId)) {
        linkedIds.add(targetListId);
        todoLists[sourceIndex] = todoLists[sourceIndex].copyWith(
          linkedTodoListIds: linkedIds,
        );
        await saveTodoLists(todoLists);
      }
    }
  }

  // Get linked todo lists
  Future<List<TodoList>> getLinkedTodoLists(String listId) async {
    final todoLists = await getAllTodoLists();
    final sourceList = todoLists.firstWhere((list) => list.id == listId);
    
    return todoLists.where((list) => 
      sourceList.linkedTodoListIds.contains(list.id)
    ).toList();
  }

  // Generate shareable link
  String _generateShareableLink(String listId) {
    // In a real app, this would be your domain
    return 'https://your-app-domain.github.io/#/shared/$listId';
  }

  // Save shareable link mapping
  Future<void> _saveShareableLink(String link, String listId) async {
    final prefs = await SharedPreferences.getInstance();
    final linksJson = prefs.getString(_shareableLinksKey) ?? '{}';
    final links = Map<String, String>.from(json.decode(linksJson));
    links[link] = listId;
    await prefs.setString(_shareableLinksKey, json.encode(links));
  }

  // Get todo list by shareable link
  Future<TodoList?> getTodoListByShareableLink(String link) async {
    final prefs = await SharedPreferences.getInstance();
    final linksJson = prefs.getString(_shareableLinksKey) ?? '{}';
    final links = Map<String, String>.from(json.decode(linksJson));
    
    final listId = links[link];
    if (listId == null) return null;
    
    final todoLists = await getAllTodoLists();
    try {
      return todoLists.firstWhere((list) => list.id == listId);
    } catch (e) {
      return null;
    }
  }

  // Get todo list by ID
  Future<TodoList?> getTodoListById(String id) async {
    final todoLists = await getAllTodoLists();
    try {
      return todoLists.firstWhere((list) => list.id == id);
    } catch (e) {
      return null;
    }
  }

  // Schedule todo list
  Future<void> scheduleTodoList(String listId, DateTime scheduledDate) async {
    final todoLists = await getAllTodoLists();
    final index = todoLists.indexWhere((list) => list.id == listId);
    
    if (index != -1) {
      todoLists[index] = todoLists[index].copyWith(scheduledDate: scheduledDate);
      await saveTodoLists(todoLists);
    }
  }

  // Get scheduled todo lists for a specific date
  Future<List<TodoList>> getScheduledTodoListsForDate(DateTime date) async {
    final todoLists = await getAllTodoLists();
    return todoLists.where((list) {
      if (list.scheduledDate == null) return false;
      return list.scheduledDate!.year == date.year &&
             list.scheduledDate!.month == date.month &&
             list.scheduledDate!.day == date.day;
    }).toList();
  }

  // Create todo item
  TodoItem createTodoItem({
    required String title,
    String description = '',
    DateTime? dueDate,
    Priority priority = Priority.medium,
  }) {
    return TodoItem(
      id: _uuid.v4(),
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority,
    );
  }
}
