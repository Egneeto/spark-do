import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider_supabase_only.dart';
import '../models/todo_item.dart';
import '../utils/share_dialog_helper.dart';

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, child) {
        final todoList = todoProvider.currentTodoList;
        
        if (todoList == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Todo List'),
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            ),
            body: const Center(
              child: Text('No todo list selected'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(todoList.title),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            actions: [
              IconButton(
                icon: const Icon(Icons.info),
                onPressed: () => _showTodoListInfo(context, todoList),
              ),
              if (todoList.isShared)
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => _showShareDialog(context, todoList),
                ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(context, value, todoList),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Edit List'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'schedule',
                    child: Row(
                      children: [
                        Icon(Icons.schedule),
                        SizedBox(width: 8),
                        Text('Schedule'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'link',
                    child: Row(
                      children: [
                        Icon(Icons.link),
                        SizedBox(width: 8),
                        Text('Link Lists'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'linked',
                    child: Row(
                      children: [
                        Icon(Icons.list_alt),
                        SizedBox(width: 8),
                        Text('View Linked Lists'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              // Progress indicator
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${todoList.completedItemsCount}/${todoList.totalItemsCount} completed',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${(todoList.completionPercentage * 100).toInt()}%',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: todoList.completionPercentage,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        todoList.isOverdue ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Todo items list
              Expanded(
                child: todoList.items.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.task_alt, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No tasks yet',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tap the + button to add your first task',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: todoList.items.length,
                        itemBuilder: (context, index) {
                          final item = todoList.items[index];
                          return TodoItemCard(
                            item: item,
                            onToggle: () => _toggleItem(item),
                            onEdit: () => _editItem(context, item),
                            onDelete: () => _deleteItem(item),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _addItem(context),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _handleMenuAction(BuildContext context, String action, todoList) {
    switch (action) {
      case 'edit':
        _editTodoList(context, todoList);
        break;
      case 'schedule':
        _scheduleTodoList(context, todoList);
        break;
      case 'link':
        _linkTodoLists(context, todoList);
        break;
      case 'linked':
        _showLinkedLists(context, todoList);
        break;
    }
  }

  void _showTodoListInfo(BuildContext context, todoList) {
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
            if (todoList.linkedTodoListIds.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Linked Lists:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${todoList.linkedTodoListIds.length} linked lists'),
            ],
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

  void _showShareDialog(BuildContext context, todoList) {
    ShareDialogHelper.showShareDialog(context, todoList);
  }

  void _editTodoList(BuildContext context, todoList) {
    // Implementation for editing todo list details
    showDialog(
      context: context,
      builder: (context) => EditTodoListDialog(todoList: todoList),
    );
  }

  void _scheduleTodoList(BuildContext context, todoList) {
    showDatePicker(
      context: context,
      initialDate: todoList.scheduledDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    ).then((selectedDate) {
      if (selectedDate != null) {
        context.read<TodoProvider>().scheduleTodoList(todoList.id, selectedDate);
      }
    });
  }

  void _linkTodoLists(BuildContext context, todoList) {
    // Implementation for linking todo lists
    // This would show a dialog to select other lists to link to
  }

  void _showLinkedLists(BuildContext context, todoList) async {
    final linkedLists = await context.read<TodoProvider>().getLinkedTodoLists(todoList.id);
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Linked Todo Lists'),
        content: linkedLists.isEmpty
            ? const Text('No linked lists')
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: linkedLists.length,
                  itemBuilder: (context, index) {
                    final linkedList = linkedLists[index];
                    return ListTile(
                      title: Text(linkedList.title),
                      subtitle: Text('${linkedList.completedItemsCount}/${linkedList.totalItemsCount} completed'),
                      onTap: () {
                        Navigator.pop(context);
                        context.read<TodoProvider>().setCurrentTodoList(linkedList);
                      },
                    );
                  },
                ),
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

  void _toggleItem(TodoItem item) {
    final updatedItem = item.copyWith(isCompleted: !item.isCompleted);
    context.read<TodoProvider>().updateTodoItem(updatedItem);
  }

  void _editItem(BuildContext context, TodoItem item) {
    showDialog(
      context: context,
      builder: (context) => EditTodoItemDialog(item: item),
    );
  }

  void _deleteItem(TodoItem item) {
    context.read<TodoProvider>().deleteTodoItem(item.id);
  }

  void _addItem(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddTodoItemDialog(),
    );
  }
}

class TodoItemCard extends StatelessWidget {
  final TodoItem item;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TodoItemCard({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Checkbox(
          value: item.isCompleted,
          onChanged: (_) => onToggle(),
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
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
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

class AddTodoItemDialog extends StatefulWidget {
  const AddTodoItemDialog({super.key});

  @override
  State<AddTodoItemDialog> createState() => _AddTodoItemDialogState();
}

class _AddTodoItemDialogState extends State<AddTodoItemDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _dueDate;
  Priority _priority = Priority.medium;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Todo Item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Priority>(
              value: _priority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
              ),
              items: Priority.values.map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Text(priority.displayName),
                );
              }).toList(),
              onChanged: (value) => setState(() => _priority = value!),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _dueDate == null
                        ? 'No due date'
                        : 'Due: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                  ),
                ),
                TextButton(
                  onPressed: _selectDueDate,
                  child: const Text('Select Date'),
                ),
                if (_dueDate != null)
                  IconButton(
                    onPressed: () => setState(() => _dueDate = null),
                    icon: const Icon(Icons.clear),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _addItem,
          child: const Text('Add'),
        ),
      ],
    );
  }

  Future<void> _selectDueDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null) {
      setState(() => _dueDate = selectedDate);
    }
  }

  void _addItem() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    final item = TodoItem(
      id: '', // Will be generated by Supabase
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      isCompleted: false,
      dueDate: _dueDate,
      priority: _priority,
    );

    context.read<TodoProvider>().addTodoItem(item);
    Navigator.pop(context);
  }
}

class EditTodoItemDialog extends StatefulWidget {
  final TodoItem item;

  const EditTodoItemDialog({super.key, required this.item});

  @override
  State<EditTodoItemDialog> createState() => _EditTodoItemDialogState();
}

class _EditTodoItemDialogState extends State<EditTodoItemDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late DateTime? _dueDate;
  late Priority _priority;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _descriptionController = TextEditingController(text: widget.item.description);
    _dueDate = widget.item.dueDate;
    _priority = widget.item.priority;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Todo Item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Priority>(
              value: _priority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
              ),
              items: Priority.values.map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Text(priority.displayName),
                );
              }).toList(),
              onChanged: (value) => setState(() => _priority = value!),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _dueDate == null
                        ? 'No due date'
                        : 'Due: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                  ),
                ),
                TextButton(
                  onPressed: _selectDueDate,
                  child: const Text('Select Date'),
                ),
                if (_dueDate != null)
                  IconButton(
                    onPressed: () => setState(() => _dueDate = null),
                    icon: const Icon(Icons.clear),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _updateItem,
          child: const Text('Update'),
        ),
      ],
    );
  }

  Future<void> _selectDueDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null) {
      setState(() => _dueDate = selectedDate);
    }
  }

  void _updateItem() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    final updatedItem = widget.item.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      dueDate: _dueDate,
      priority: _priority,
    );

    context.read<TodoProvider>().updateTodoItem(updatedItem);
    Navigator.pop(context);
  }
}

class EditTodoListDialog extends StatefulWidget {
  final todoList;

  const EditTodoListDialog({super.key, required this.todoList});

  @override
  State<EditTodoListDialog> createState() => _EditTodoListDialogState();
}

class _EditTodoListDialogState extends State<EditTodoListDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todoList.title);
    _descriptionController = TextEditingController(text: widget.todoList.description);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Todo List'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _updateTodoList,
          child: const Text('Update'),
        ),
      ],
    );
  }

  void _updateTodoList() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    final updatedList = widget.todoList.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    context.read<TodoProvider>().updateTodoList(updatedList);
    Navigator.pop(context);
  }
}
