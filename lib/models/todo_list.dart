import 'todo_item.dart';

class TodoList {
  final String id;
  final String title;
  final String description;
  final List<TodoItem> items;
  final DateTime createdAt;
  final DateTime? scheduledDate;
  final String? shareableLink;
  final bool isShared;
  final List<String> linkedTodoListIds;

  TodoList({
    required this.id,
    required this.title,
    this.description = '',
    this.items = const [],
    required this.createdAt,
    this.scheduledDate,
    this.shareableLink,
    this.isShared = false,
    this.linkedTodoListIds = const [],
  });

  TodoList copyWith({
    String? id,
    String? title,
    String? description,
    List<TodoItem>? items,
    DateTime? createdAt,
    DateTime? scheduledDate,
    String? shareableLink,
    bool? isShared,
    List<String>? linkedTodoListIds,
  }) {
    return TodoList(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      shareableLink: shareableLink ?? this.shareableLink,
      isShared: isShared ?? this.isShared,
      linkedTodoListIds: linkedTodoListIds ?? this.linkedTodoListIds,
    );
  }

  int get completedItemsCount => items.where((item) => item.isCompleted).length;
  int get totalItemsCount => items.length;
  double get completionPercentage => 
      totalItemsCount == 0 ? 0 : completedItemsCount / totalItemsCount;

  bool get isScheduled => scheduledDate != null;
  bool get isOverdue => scheduledDate != null && 
      scheduledDate!.isBefore(DateTime.now()) && 
      completionPercentage < 1.0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'items': items.map((item) => item.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'scheduledDate': scheduledDate?.toIso8601String(),
      'shareableLink': shareableLink,
      'isShared': isShared,
      'linkedTodoListIds': linkedTodoListIds,
    };
  }

  factory TodoList.fromJson(Map<String, dynamic> json) {
    return TodoList(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => TodoItem.fromJson(item))
          .toList() ?? [],
      createdAt: DateTime.parse(json['createdAt']),
      scheduledDate: json['scheduledDate'] != null 
          ? DateTime.parse(json['scheduledDate']) 
          : null,
      shareableLink: json['shareableLink'],
      isShared: json['isShared'] ?? false,
      linkedTodoListIds: List<String>.from(json['linkedTodoListIds'] ?? []),
    );
  }
}
