import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider_supabase_only.dart';
import '../models/todo_list.dart';
import '../models/todo_item.dart';

class SharedTodoListScreen extends StatefulWidget {
  final String shareToken;

  const SharedTodoListScreen({super.key, required this.shareToken});

  @override
  State<SharedTodoListScreen> createState() => _SharedTodoListScreenState();
}

class _SharedTodoListScreenState extends State<SharedTodoListScreen> {
  TodoList? _todoList;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTodoList();
  }

  Future<void> _loadTodoList() async {
    try {
      final todoProvider = context.read<TodoProvider>();
      // Use share token to get todo list, not direct ID lookup
      final todoList = await todoProvider.getTodoListByShareableLink(widget.shareToken);
      
      if (mounted) {
        setState(() {
          _todoList = todoList;
          _isLoading = false;
          if (todoList == null) {
            _errorMessage = 'Todo list not found or no longer shared';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading todo list: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Shared Todo List'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null || _todoList == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Shared Todo List'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Todo list not found',
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_todoList!.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () => _showTodoListInfo(context, _todoList!),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTodoList,
          ),
        ],
      ),
      body: Column(
        children: [
          // Shared indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Icon(Icons.share, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This is a shared todo list. You can mark tasks as complete/incomplete.',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_todoList!.completedItemsCount}/${_todoList!.totalItemsCount} completed',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${(_todoList!.completionPercentage * 100).toInt()}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _todoList!.completionPercentage,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _todoList!.isOverdue ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ),
          
          // Todo items list
          Expanded(
            child: _todoList!.items.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.task_alt, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No tasks in this list',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _todoList!.items.length,
                    itemBuilder: (context, index) {
                      final item = _todoList!.items[index];
                      return SharedTodoItemCard(
                        item: item,
                        onToggleComplete: (TodoItem item) => _toggleItemCompletion(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleItemCompletion(TodoItem item) async {
    try {
      final updatedItem = item.copyWith(isCompleted: !item.isCompleted);
      
      // Update UI immediately for better UX
      setState(() {
        final updatedItems = _todoList!.items.map((todoItem) {
          return todoItem.id == item.id ? updatedItem : todoItem;
        }).toList();
        
        _todoList = _todoList!.copyWith(items: updatedItems);
      });
      
      final todoProvider = context.read<TodoProvider>();
      
      // Update the item in Supabase
      await todoProvider.updateTodoItem(updatedItem);
      
      // Show feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updatedItem.isCompleted 
                ? '✓ Task marked as complete' 
                : '○ Task marked as incomplete'
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      // Reload the todo list to sync with server (after a brief delay)
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _loadTodoList();
        }
      });
      
    } catch (e) {
      // If there's an error, reload to get the correct state
      await _loadTodoList();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showTodoListInfo(BuildContext context, TodoList todoList) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(todoList.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (todoList.description.isNotEmpty) ...[
              const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(todoList.description),
              const SizedBox(height: 16),
            ],
            const Text('Created:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('${todoList.createdAt.day}/${todoList.createdAt.month}/${todoList.createdAt.year}'),
            if (todoList.scheduledDate != null) ...[
              const SizedBox(height: 8),
              const Text('Scheduled:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${todoList.scheduledDate!.day}/${todoList.scheduledDate!.month}/${todoList.scheduledDate!.year}'),
            ],
            const SizedBox(height: 8),
            const Text('Progress:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('${todoList.completedItemsCount}/${todoList.totalItemsCount} tasks completed'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This is a shared todo list. You can mark tasks as complete/incomplete.',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class SharedTodoItemCard extends StatelessWidget {
  final TodoItem item;
  final Function(TodoItem) onToggleComplete;

  const SharedTodoItemCard({
    super.key, 
    required this.item,
    required this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Checkbox(
          value: item.isCompleted,
          onChanged: (value) => onToggleComplete(item),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
            color: item.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.description.isNotEmpty)
              Text(
                item.description,
                style: TextStyle(
                  color: item.isCompleted ? Colors.grey : null,
                ),
              ),
            Row(
              children: [
                _getPriorityChip(item.priority),
                if (item.dueDate != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: _getDueDateColor(item.dueDate!),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${item.dueDate!.day}/${item.dueDate!.month}',
                    style: TextStyle(
                      fontSize: 12,
                      color: _getDueDateColor(item.dueDate!),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _getPriorityChip(Priority priority) {
    Color color;
    switch (priority) {
      case Priority.low:
        color = Colors.green;
        break;
      case Priority.medium:
        color = Colors.orange;
        break;
      case Priority.high:
        color = Colors.red;
        break;
      case Priority.urgent:
        color = Colors.purple;
        break;
    }

    return Chip(
      label: Text(
        priority.displayName,
        style: const TextStyle(fontSize: 10, color: Colors.white),
      ),
      backgroundColor: color,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Color _getDueDateColor(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (due.isBefore(today)) {
      return Colors.red; // Overdue
    } else if (due.isAtSameMomentAs(today)) {
      return Colors.orange; // Due today
    } else {
      return Colors.blue; // Future
    }
  }
}
