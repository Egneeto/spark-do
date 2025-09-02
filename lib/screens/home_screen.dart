import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider_supabase_only.dart';
import '../models/todo_list.dart';
import 'todo_list_screen.dart';
import 'calendar_screen.dart';
import 'create_todo_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TodoProvider>().loadTodoLists();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app comes back to foreground
      context.read<TodoProvider>().loadTodoLists();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          TodoListsTab(),
          CalendarScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          // Refresh data when switching to Todo Lists tab
          if (index == 0) {
            context.read<TodoProvider>().loadTodoLists();
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Todo Lists',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTodoListDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateTodoListDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateTodoListDialog(),
    );
  }
}

class TodoListsTab extends StatelessWidget {
  const TodoListsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SparkDo - Todo Lists'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<TodoProvider>(
        builder: (context, todoProvider, child) {
          if (todoProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (todoProvider.todoLists.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.list_alt, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No todo lists yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap the + button to create your first list',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              // Overdue section
              if (todoProvider.overdueTodoLists.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Overdue',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final todoList = todoProvider.overdueTodoLists[index];
                      return TodoListCard(
                        todoList: todoList,
                        isOverdue: true,
                      );
                    },
                    childCount: todoProvider.overdueTodoLists.length,
                  ),
                ),
              ],
              
              // Scheduled section
              if (todoProvider.scheduledTodoLists.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Scheduled',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final todoList = todoProvider.scheduledTodoLists[index];
                      return TodoListCard(todoList: todoList);
                    },
                    childCount: todoProvider.scheduledTodoLists.length,
                  ),
                ),
              ],
              
              // Unscheduled section
              if (todoProvider.unscheduledTodoLists.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Unscheduled',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final todoList = todoProvider.unscheduledTodoLists[index];
                      return TodoListCard(todoList: todoList);
                    },
                    childCount: todoProvider.unscheduledTodoLists.length,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class TodoListCard extends StatelessWidget {
  final TodoList todoList;
  final bool isOverdue;

  const TodoListCard({
    super.key,
    required this.todoList,
    this.isOverdue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isOverdue ? Colors.red.shade50 : null,
      child: ListTile(
        title: Text(
          todoList.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isOverdue ? Colors.red.shade700 : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (todoList.description.isNotEmpty)
              Text(todoList.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Colors.green.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  '${todoList.completedItemsCount}/${todoList.totalItemsCount} completed',
                  style: const TextStyle(fontSize: 12),
                ),
                if (todoList.isScheduled) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: isOverdue ? Colors.red : Colors.blue,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${todoList.scheduledDate!.day}/${todoList.scheduledDate!.month}/${todoList.scheduledDate!.year}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOverdue ? Colors.red : null,
                    ),
                  ),
                ],
              ],
            ),
            if (todoList.totalItemsCount > 0)
              LinearProgressIndicator(
                value: todoList.completionPercentage,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOverdue ? Colors.red : Colors.green,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (todoList.isShared)
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => _showShareDialog(context, todoList),
              ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(context, value, todoList),
              itemBuilder: (context) => [
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
                      Text('Link to Another List'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share),
                      SizedBox(width: 8),
                      Text('Generate Share Link'),
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
          ],
        ),
        onTap: () async {
          context.read<TodoProvider>().setCurrentTodoList(todoList);
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TodoListScreen(),
            ),
          );
          // Refresh data when returning from TodoListScreen
          if (context.mounted) {
            context.read<TodoProvider>().loadTodoLists();
          }
        },
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action, TodoList todoList) {
    switch (action) {
      case 'schedule':
        _showScheduleDialog(context, todoList);
        break;
      case 'link':
        _showLinkDialog(context, todoList);
        break;
      case 'share':
        _generateShareLink(context, todoList);
        break;
      case 'delete':
        _showDeleteDialog(context, todoList);
        break;
    }
  }

  void _showScheduleDialog(BuildContext context, TodoList todoList) {
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

  void _showLinkDialog(BuildContext context, TodoList todoList) {
    showDialog(
      context: context,
      builder: (context) => LinkTodoListDialog(sourceList: todoList),
    );
  }

  void _generateShareLink(BuildContext context, TodoList todoList) async {
    final provider = context.read<TodoProvider>();
    
    if (!todoList.isShared) {
      // Generate a shareable link
      final updatedList = todoList.copyWith(
        isShared: true,
        shareableLink: 'https://your-app-domain.github.io/#/shared/${todoList.id}',
      );
      await provider.updateTodoList(updatedList);
    }
    
    _showShareDialog(context, todoList);
  }

  void _showShareDialog(BuildContext context, TodoList todoList) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Todo List'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Share this link with others:'),
            const SizedBox(height: 8),
            SelectableText(
              todoList.shareableLink ?? 'No link available',
              style: const TextStyle(
                fontFamily: 'monospace',
                backgroundColor: Colors.grey,
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

  void _showDeleteDialog(BuildContext context, TodoList todoList) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Todo List'),
        content: Text('Are you sure you want to delete "${todoList.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<TodoProvider>().deleteTodoList(todoList.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class LinkTodoListDialog extends StatelessWidget {
  final TodoList sourceList;

  const LinkTodoListDialog({super.key, required this.sourceList});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Link Todo List'),
      content: SizedBox(
        width: double.maxFinite,
        child: Consumer<TodoProvider>(
          builder: (context, todoProvider, child) {
            final availableLists = todoProvider.todoLists
                .where((list) => list.id != sourceList.id)
                .toList();

            if (availableLists.isEmpty) {
              return const Text('No other todo lists available to link.');
            }

            return ListView.builder(
              shrinkWrap: true,
              itemCount: availableLists.length,
              itemBuilder: (context, index) {
                final list = availableLists[index];
                return ListTile(
                  title: Text(list.title),
                  subtitle: Text(list.description),
                  onTap: () {
                    todoProvider.linkTodoLists(sourceList.id, list.id);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Linked "${sourceList.title}" to "${list.title}"'),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
