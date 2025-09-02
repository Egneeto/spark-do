import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/todo_provider_supabase_only.dart';
import '../models/todo_list.dart';
import 'todo_list_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final ValueNotifier<List<TodoList>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  List<TodoList> _getEventsForDay(DateTime day) {
    final todoProvider = context.read<TodoProvider>();
    return todoProvider.todoLists.where((todoList) {
      if (todoList.scheduledDate == null) return false;
      return isSameDay(todoList.scheduledDate!, day);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar Schedule'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
                _selectedEvents.value = _getEventsForDay(_selectedDay!);
              });
            },
          ),
        ],
      ),
      body: Consumer<TodoProvider>(
        builder: (context, todoProvider, child) {
          return Column(
            children: [
              TableCalendar<TodoList>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                eventLoader: _getEventsForDay,
                startingDayOfWeek: StartingDayOfWeek.monday,
                calendarStyle: const CalendarStyle(
                  outsideDaysVisible: false,
                  markersMaxCount: 3,
                  markerDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  if (!isSameDay(_selectedDay, selectedDay)) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                      _selectedEvents.value = _getEventsForDay(selectedDay);
                    });
                  }
                },
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
              ),
              const SizedBox(height: 8.0),
              Expanded(
                child: ValueListenableBuilder<List<TodoList>>(
                  valueListenable: _selectedEvents,
                  builder: (context, value, _) {
                    if (value.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_available,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No todo lists scheduled for ${_selectedDay?.day}/${_selectedDay?.month}/${_selectedDay?.year}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Schedule a todo list from the main screen',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: value.length,
                      itemBuilder: (context, index) {
                        final todoList = value[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 4.0,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(todoList),
                              child: Icon(
                                _getStatusIcon(todoList),
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              todoList.title,
                              style: const TextStyle(fontWeight: FontWeight.bold),
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
                                    const Spacer(),
                                    if (todoList.isOverdue)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          'OVERDUE',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                if (todoList.totalItemsCount > 0)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    child: LinearProgressIndicator(
                                      value: todoList.completionPercentage,
                                      backgroundColor: Colors.grey.shade300,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _getStatusColor(todoList),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) => _handleMenuAction(
                                context,
                                value,
                                todoList,
                              ),
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'open',
                                  child: Row(
                                    children: [
                                      Icon(Icons.open_in_new),
                                      SizedBox(width: 8),
                                      Text('Open'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'reschedule',
                                  child: Row(
                                    children: [
                                      Icon(Icons.schedule),
                                      SizedBox(width: 8),
                                      Text('Reschedule'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'unschedule',
                                  child: Row(
                                    children: [
                                      Icon(Icons.event_busy),
                                      SizedBox(width: 8),
                                      Text('Remove from Schedule'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              todoProvider.setCurrentTodoList(todoList);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TodoListScreen(),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getStatusColor(TodoList todoList) {
    if (todoList.isOverdue) {
      return Colors.red;
    } else if (todoList.completionPercentage == 1.0) {
      return Colors.green;
    } else if (todoList.completionPercentage > 0.5) {
      return Colors.orange;
    } else {
      return Colors.blue;
    }
  }

  IconData _getStatusIcon(TodoList todoList) {
    if (todoList.completionPercentage == 1.0) {
      return Icons.check;
    } else if (todoList.isOverdue) {
      return Icons.warning;
    } else {
      return Icons.list;
    }
  }

  void _handleMenuAction(BuildContext context, String action, TodoList todoList) {
    switch (action) {
      case 'open':
        context.read<TodoProvider>().setCurrentTodoList(todoList);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TodoListScreen(),
          ),
        );
        break;
      case 'reschedule':
        _rescheduleTodoList(context, todoList);
        break;
      case 'unschedule':
        _unscheduleTodoList(context, todoList);
        break;
    }
  }

  void _rescheduleTodoList(BuildContext context, TodoList todoList) {
    showDatePicker(
      context: context,
      initialDate: todoList.scheduledDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    ).then((selectedDate) {
      if (selectedDate != null) {
        context.read<TodoProvider>().scheduleTodoList(todoList.id, selectedDate);
        setState(() {
          _selectedEvents.value = _getEventsForDay(_selectedDay!);
        });
      }
    });
  }

  void _unscheduleTodoList(BuildContext context, TodoList todoList) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Schedule'),
        content: Text(
          'Are you sure you want to remove "${todoList.title}" from the schedule?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final updatedList = todoList.copyWith(scheduledDate: null);
              context.read<TodoProvider>().updateTodoList(updatedList);
              Navigator.pop(context);
              setState(() {
                _selectedEvents.value = _getEventsForDay(_selectedDay!);
              });
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
