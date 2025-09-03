import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/todo_provider_supabase_only.dart';
import 'screens/home_screen.dart';
import 'utils/app_router.dart';
import 'services/supabase_service.dart';
import 'services/supabase_connection_test.dart';
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
    
    // Test Supabase connection
    debugPrint('SparkDo: Testing Supabase connection...');
    final testResults = await SupabaseConnectionTest.testConnection();
    debugPrint('SparkDo: Connection test completed');
    debugPrint(SupabaseConnectionTest.formatTestResults(testResults));
    
    // Check if connection is working
    if (!testResults['database_accessible']) {
      throw Exception('Supabase database not accessible: ${testResults['network_error'] ?? 'Unknown error'}');
    }
    
    runApp(const MyApp());
  } catch (e, stackTrace) {
    debugPrint('SparkDo: Error initializing app: $e');
    debugPrint('SparkDo: Stack trace: $stackTrace');
    
    // Run connection test even on error to help diagnose
    try {
      final testResults = await SupabaseConnectionTest.testConnection();
      runApp(ErrorApp(
        error: e.toString(), 
        connectionTest: SupabaseConnectionTest.formatTestResults(testResults),
      ));
    } catch (testError) {
      runApp(ErrorApp(
        error: e.toString(), 
        connectionTest: 'Connection test failed: $testError',
      ));
    }
  }
}

class ErrorApp extends StatelessWidget {
  final String error;
  final String? connectionTest;
  
  const ErrorApp({super.key, required this.error, this.connectionTest});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SparkDo - Error',
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'SparkDo Failed to Initialize',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Supabase connection test results below:',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              if (connectionTest != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Connection Test Results:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        connectionTest!,
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Error Details:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error,
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Reload the page on web
                    html.window.location.reload();
                  },
                  child: const Text('Reload Page'),
                ),
              ),
            ],
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
