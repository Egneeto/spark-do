import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseConnectionTest {
  static Future<Map<String, dynamic>> testConnection() async {
    final Map<String, dynamic> results = {
      'timestamp': DateTime.now().toIso8601String(),
      'config_loaded': false,
      'client_initialized': false,
      'network_reachable': false,
      'auth_working': false,
      'database_accessible': false,
      'error': null,
    };

    try {
      // Test 1: Config loaded
      results['config_url'] = SupabaseConfig.supabaseUrl;
      results['config_key_length'] = SupabaseConfig.supabaseAnonKey.length;
      results['config_loaded'] = true;

      // Test 2: Client initialized
      final client = Supabase.instance.client;
      results['client_initialized'] = true;

      // Test 3: Network connectivity test
      try {
        final response = await client
            .from('todo_lists')
            .select('count')
            .count(CountOption.exact);
        
        results['network_reachable'] = true;
        results['database_accessible'] = true;
        results['todo_lists_count'] = response.count;
        
      } catch (e) {
        results['network_error'] = e.toString();
        
        // Try a simpler test - just auth
        try {
          final user = client.auth.currentUser;
          results['auth_working'] = true;
          results['current_user'] = user?.id ?? 'anonymous';
        } catch (authError) {
          results['auth_error'] = authError.toString();
        }
      }

    } catch (e) {
      results['error'] = e.toString();
    }

    return results;
  }

  static String formatTestResults(Map<String, dynamic> results) {
    final buffer = StringBuffer();
    buffer.writeln('🔍 SUPABASE CONNECTION TEST RESULTS');
    buffer.writeln('─' * 40);
    buffer.writeln('⏰ Timestamp: ${results['timestamp']}');
    buffer.writeln('');
    
    buffer.writeln('📋 CONFIGURATION:');
    buffer.writeln('✅ Config Loaded: ${results['config_loaded']}');
    buffer.writeln('🌐 URL: ${results['config_url']}');
    buffer.writeln('🔑 Key Length: ${results['config_key_length']} chars');
    buffer.writeln('');
    
    buffer.writeln('🔧 CLIENT STATUS:');
    buffer.writeln('✅ Client Init: ${results['client_initialized']}');
    buffer.writeln('');
    
    buffer.writeln('🌐 NETWORK & DATABASE:');
    buffer.writeln('✅ Network: ${results['network_reachable']}');
    buffer.writeln('✅ Database: ${results['database_accessible']}');
    buffer.writeln('✅ Auth: ${results['auth_working']}');
    
    if (results['todo_lists_count'] != null) {
      buffer.writeln('📊 Todo Lists: ${results['todo_lists_count']}');
    }
    
    if (results['current_user'] != null) {
      buffer.writeln('👤 User: ${results['current_user']}');
    }
    
    buffer.writeln('');
    
    if (results['error'] != null) {
      buffer.writeln('❌ MAIN ERROR:');
      buffer.writeln(results['error']);
      buffer.writeln('');
    }
    
    if (results['network_error'] != null) {
      buffer.writeln('🌐 NETWORK ERROR:');
      buffer.writeln(results['network_error']);
      buffer.writeln('');
    }
    
    if (results['auth_error'] != null) {
      buffer.writeln('🔐 AUTH ERROR:');
      buffer.writeln(results['auth_error']);
      buffer.writeln('');
    }

    return buffer.toString();
  }
}
