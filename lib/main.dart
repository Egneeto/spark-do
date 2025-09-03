import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/todo_provider_supabase_only.dart';
import 'screens/home_screen.dart';
import 'utils/app_router.dart';
import 'services/supabase_service.dart';
import 'config/supabase_config.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Supabase with web-specific configuration
    await SupabaseService.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    
    // Debug logging for web
    debugPrint('SparkDo: Supabase initialized successfully');
    debugPrint('SparkDo: URL - ${SupabaseConfig.supabaseUrl}');
    debugPrint('SparkDo: Running on web platform');
    
    runApp(const MyApp());
  } catch (e, stackTrace) {
    debugPrint('SparkDo: Error initializing app: $e');
    debugPrint('SparkDo: Stack trace: $stackTrace');
    runApp(ErrorApp(error: e.toString()));
  }
}

class ErrorApp extends StatelessWidget {
  final String error;
  
  const ErrorApp({super.key, required this.error});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SparkDo - Error',
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'SparkDo Failed to Initialize',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please check your internet connection and try refreshing the page.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error: $error',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Reload the page on web
                    html.window.location.reload();
                  },
                  child: const Text('Reload Page'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
