import 'dart:html' as html;
import 'package:flutter/material.dart';
import '../screens/shared_todo_list_screen.dart';
import '../screens/home_screen.dart';
import '../utils/app_router.dart';

class WebDeepLinkHandler {
  static Widget handleInitialRoute() {
    // Get the current URL from the browser
    final currentUrl = html.window.location.href;
    
    // Check if this is a shared todo list link
    final todoListId = AppRouter.extractTodoListIdFromLink(currentUrl);
    
    if (todoListId != null) {
      // Return the shared todo list screen
      return SharedTodoListScreen(todoListId: todoListId);
    }
    
    // Default to home screen
    return const HomeScreen();
  }
  
  static void updateUrl(String route) {
    // Update the browser URL without triggering a page reload
    html.window.history.pushState(null, '', '#$route');
  }
  
  static void setupPopstateListener(Function(String) onRouteChange) {
    html.window.onPopState.listen((event) {
      final fragment = html.window.location.hash;
      
      if (fragment.isNotEmpty) {
        onRouteChange(fragment.substring(1)); // Remove the # character
      } else {
        onRouteChange('/');
      }
    });
  }
}
