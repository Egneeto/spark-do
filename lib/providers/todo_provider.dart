import 'package:flutter/foundation.dart';
import '../models/todo_list.dart';
import '../models/todo_item.dart';
import '../services/todo_service.dart';

class TodoProvider extends ChangeNotifier {
  final TodoService _todoService = TodoService();
  
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

  // Initialize and load all todo lists
  Future<void> loadTodoLists() async {
    _isLoading = true;
    notifyListeners();

    try {
      _todoLists = await _todoService.getAllTodoLists();
    } catch (e) {
      debugPrint('Error loading todo lists: $e');
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
    _isLoading = true;
    notifyListeners();

    try {
      final newTodoList = await _todoService.createTodoList(
        title: title,
        description: description,
        scheduledDate: scheduledDate,
        generateShareableLink: generateShareableLink,
      );

      _todoLists.add(newTodoList);
      notifyListeners();
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
    try {
      await _todoService.updateTodoList(updatedList);
      
      final index = _todoLists.indexWhere((list) => list.id == updatedList.id);
      if (index != -1) {
        _todoLists[index] = updatedList;
        if (_currentTodoList?.id == updatedList.id) {
          _currentTodoList = updatedList;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating todo list: $e');
    }
  }

  // Delete todo list
  Future<void> deleteTodoList(String id) async {
    try {
      await _todoService.deleteTodoList(id);
      _todoLists.removeWhere((list) => list.id == id);
      
      if (_currentTodoList?.id == id) {
        _currentTodoList = null;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting todo list: $e');
    }
  }

  // Set current todo list
  void setCurrentTodoList(TodoList? todoList) {
    _currentTodoList = todoList;
    notifyListeners();
  }

  // Add item to current todo list
  Future<void> addItemToCurrentList(TodoItem item) async {
    if (_currentTodoList == null) return;

    try {
      await _todoService.addItemToList(_currentTodoList!.id, item);
      
      final updatedItems = List<TodoItem>.from(_currentTodoList!.items);
      updatedItems.add(item);
      
      final updatedList = _currentTodoList!.copyWith(items: updatedItems);
      await updateTodoList(updatedList);
    } catch (e) {
      debugPrint('Error adding item to list: $e');
    }
  }

  // Update item in current todo list
  Future<void> updateItemInCurrentList(TodoItem updatedItem) async {
    if (_currentTodoList == null) return;

    try {
      await _todoService.updateItemInList(_currentTodoList!.id, updatedItem);
      
      final updatedItems = List<TodoItem>.from(_currentTodoList!.items);
      final itemIndex = updatedItems.indexWhere((item) => item.id == updatedItem.id);
      
      if (itemIndex != -1) {
        updatedItems[itemIndex] = updatedItem;
        final updatedList = _currentTodoList!.copyWith(items: updatedItems);
        await updateTodoList(updatedList);
      }
    } catch (e) {
      debugPrint('Error updating item in list: $e');
    }
  }

  // Remove item from current todo list
  Future<void> removeItemFromCurrentList(String itemId) async {
    if (_currentTodoList == null) return;

    try {
      await _todoService.removeItemFromList(_currentTodoList!.id, itemId);
      
      final updatedItems = List<TodoItem>.from(_currentTodoList!.items);
      updatedItems.removeWhere((item) => item.id == itemId);
      
      final updatedList = _currentTodoList!.copyWith(items: updatedItems);
      await updateTodoList(updatedList);
    } catch (e) {
      debugPrint('Error removing item from list: $e');
    }
  }

  // Link todo lists
  Future<void> linkTodoLists(String sourceListId, String targetListId) async {
    try {
      await _todoService.linkTodoLists(sourceListId, targetListId);
      await loadTodoLists(); // Refresh to get updated linked lists
    } catch (e) {
      debugPrint('Error linking todo lists: $e');
    }
  }

  // Get linked todo lists
  Future<List<TodoList>> getLinkedTodoLists(String listId) async {
    try {
      return await _todoService.getLinkedTodoLists(listId);
    } catch (e) {
      debugPrint('Error getting linked todo lists: $e');
      return [];
    }
  }

  // Schedule todo list
  Future<void> scheduleTodoList(String listId, DateTime scheduledDate) async {
    try {
      await _todoService.scheduleTodoList(listId, scheduledDate);
      await loadTodoLists(); // Refresh to get updated schedule
    } catch (e) {
      debugPrint('Error scheduling todo list: $e');
    }
  }

  // Get scheduled todo lists for date
  Future<List<TodoList>> getScheduledTodoListsForDate(DateTime date) async {
    try {
      return await _todoService.getScheduledTodoListsForDate(date);
    } catch (e) {
      debugPrint('Error getting scheduled todo lists: $e');
      return [];
    }
  }

  // Set selected date for calendar
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  // Get todo list by shareable link
  Future<TodoList?> getTodoListByShareableLink(String link) async {
    try {
      return await _todoService.getTodoListByShareableLink(link);
    } catch (e) {
      debugPrint('Error getting todo list by shareable link: $e');
      return null;
    }
  }

  // Get todo list by ID
  Future<TodoList?> getTodoListById(String id) async {
    try {
      return await _todoService.getTodoListById(id);
    } catch (e) {
      debugPrint('Error getting todo list by ID: $e');
      return null;
    }
  }

  // Create todo item
  TodoItem createTodoItem({
    required String title,
    String description = '',
    DateTime? dueDate,
    Priority priority = Priority.medium,
  }) {
    return _todoService.createTodoItem(
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority,
    );
  }
}
