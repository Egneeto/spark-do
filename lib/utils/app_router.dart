import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/shared_todo_list_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case '/shared':
        final String? todoListId = settings.arguments as String?;
        if (todoListId != null) {
          return MaterialPageRoute(
            builder: (_) => SharedTodoListScreen(todoListId: todoListId),
          );
        }
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Page Not Found')),
            body: const Center(
              child: Text('Page not found'),
            ),
          ),
        );
    }
  }

  // Handle deep links for shared todo lists
  static String? extractTodoListIdFromLink(String link) {
    // Extract ID from links like: https://your-app-domain.github.io/#/shared/uuid
    final uri = Uri.tryParse(link);
    if (uri == null) return null;
    
    // Handle both fragment-based and path-based routing
    String path = uri.fragment.isNotEmpty ? uri.fragment : uri.path;
    
    if (path.startsWith('/shared/')) {
      return path.substring('/shared/'.length);
    }
    
    return null;
  }

  // Check if the current route is a shared todo list
  static bool isSharedTodoListRoute(String route) {
    return route.startsWith('/shared/');
  }
}
