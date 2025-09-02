import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/todo_provider.dart';
import 'screens/home_screen.dart';
import 'utils/app_router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TodoProvider(),
      child: MaterialApp(
        title: 'SparkDo - Todo & Schedule',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const AppLauncher(),
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}

class AppLauncher extends StatefulWidget {
  const AppLauncher({super.key});

  @override
  State<AppLauncher> createState() => _AppLauncherState();
}

class _AppLauncherState extends State<AppLauncher> {
  @override
  void initState() {
    super.initState();
    _handleInitialRoute();
  }

  void _handleInitialRoute() {
    // In a real web app, you would check the current URL here
    // For now, we'll always start with the home screen
    // But this is where you'd parse the URL to check for shared links
    
    // Example of how to handle a shared link:
    // final currentUrl = window.location.href; // For web
    // final todoListId = AppRouter.extractTodoListIdFromLink(currentUrl);
    // if (todoListId != null) {
    //   Navigator.pushReplacement(
    //     context,
    //     MaterialPageRoute(
    //       builder: (_) => SharedTodoListScreen(todoListId: todoListId),
    //     ),
    //   );
    //   return;
    // }
  }

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}
