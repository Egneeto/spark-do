class SupabaseConfig {
  // TODO: Replace these with your actual Supabase project credentials
  // You can find these in your Supabase dashboard under Settings > API
  
  static const String supabaseUrl = 'https://ftmxbyonwjhzrzwatwin.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ0bXhieW9ud2poenJ6d2F0d2luIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY4NDY0MDcsImV4cCI6MjA3MjQyMjQwN30.SoEmLjtxFBX8mOoUK2GdU8dAbLW3jEGSbvp89SnPqfU';
  
  // Your app's domain for generating shareable links
  static const String appDomain = 'https://egneeto.github.io/spark-do/';
  
  // Configuration for share links
  static const bool enableShareExpiration = false; // Set to true if you want links to expire
  static const int shareExpirationDays = 30; // Days before share links expire
  
  // Anonymous editing configuration
  static const bool defaultAllowAnonymousEdit = false; // Default setting for new shared lists
}

// Instructions for setup:
// 
// 1. Go to https://supabase.com and create a new project
// 2. Once created, go to Settings > API
// 3. Copy your Project URL and replace 'YOUR_SUPABASE_URL'
// 4. Copy your anon/public key and replace 'YOUR_SUPABASE_ANON_KEY'
// 5. Run the SQL schema from supabase_schema.sql in your Supabase SQL editor
// 6. Update appDomain with your actual GitHub Pages URL
// 7. Configure RLS policies if needed for additional security
