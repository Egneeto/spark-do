import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider_supabase_only.dart';

class CreateTodoListDialog extends StatefulWidget {
  const CreateTodoListDialog({super.key});

  @override
  State<CreateTodoListDialog> createState() => _CreateTodoListDialogState();
}

class _CreateTodoListDialogState extends State<CreateTodoListDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _scheduledDate;
  bool _generateShareableLink = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Todo List'),
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    _scheduledDate == null
                        ? 'No scheduled date'
                        : 'Scheduled: ${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year}',
                  ),
                ),
                TextButton(
                  onPressed: _selectDate,
                  child: const Text('Select Date'),
                ),
                if (_scheduledDate != null)
                  IconButton(
                    onPressed: () => setState(() => _scheduledDate = null),
                    icon: const Icon(Icons.clear),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Generate shareable link'),
              subtitle: const Text('Others can access this list via a link'),
              value: _generateShareableLink,
              onChanged: (value) => setState(() => _generateShareableLink = value ?? false),
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
          onPressed: _createTodoList,
          child: const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null) {
      setState(() => _scheduledDate = selectedDate);
    }
  }

  Future<void> _createTodoList() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    try {
      await context.read<TodoProvider>().createTodoList(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        scheduledDate: _scheduledDate,
        generateShareableLink: _generateShareableLink,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Todo list created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating todo list: $e')),
        );
      }
    }
  }
}

class CreateTodoListScreen extends StatefulWidget {
  const CreateTodoListScreen({super.key});

  @override
  State<CreateTodoListScreen> createState() => _CreateTodoListScreenState();
}

class _CreateTodoListScreenState extends State<CreateTodoListScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _scheduledDate;
  bool _generateShareableLink = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Todo List'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  _scheduledDate == null
                      ? 'No scheduled date'
                      : 'Scheduled for ${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: _selectDate,
                      child: const Text('Select'),
                    ),
                    if (_scheduledDate != null)
                      IconButton(
                        onPressed: () => setState(() => _scheduledDate = null),
                        icon: const Icon(Icons.clear),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: CheckboxListTile(
                secondary: const Icon(Icons.share),
                title: const Text('Generate shareable link'),
                subtitle: const Text('Others can access this list via a link'),
                value: _generateShareableLink,
                onChanged: (value) => setState(() => _generateShareableLink = value ?? false),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _createTodoList,
                child: const Text('Create Todo List'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null) {
      setState(() => _scheduledDate = selectedDate);
    }
  }

  Future<void> _createTodoList() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    try {
      await context.read<TodoProvider>().createTodoList(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        scheduledDate: _scheduledDate,
        generateShareableLink: _generateShareableLink,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Todo list created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating todo list: $e')),
        );
      }
    }
  }
}
