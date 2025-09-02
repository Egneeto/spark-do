# Supabase Setup Guide for SparkDo

This guide will walk you through setting up Supabase as the backend for your SparkDo todo application.

## Prerequisites

- A Supabase account (free tier available at [supabase.com](https://supabase.com))
- Basic understanding of SQL
- Your Flutter project set up locally

## Step 1: Create a Supabase Project

1. Go to [supabase.com](https://supabase.com) and sign up/sign in
2. Click "New Project"
3. Choose your organization
4. Fill in project details:
   - **Name**: `sparkdo-backend` (or your preferred name)
   - **Database Password**: Create a strong password (save this!)
   - **Region**: Choose closest to your users
5. Click "Create new project"
6. Wait for the project to be set up (usually takes 1-2 minutes)

## Step 2: Set Up the Database Schema

1. In your Supabase dashboard, navigate to the **SQL Editor**
2. Click "New Query"
3. Copy the entire contents of `supabase_schema.sql` from your project
4. Paste it into the SQL editor
5. Click "Run" to execute the schema
6. Verify that all tables were created by checking the **Table Editor**

You should see these tables:
- `todo_lists`
- `todo_items`
- `todo_list_links`
- `schedule_instances`
- `share_access_log`

## Step 3: Configure Your Flutter App

1. In your Supabase dashboard, go to **Settings** > **API**
2. Copy the following values:
   - **Project URL**
   - **anon/public key** (NOT the service_role key!)

3. Open `lib/config/supabase_config.dart` in your Flutter project
4. Replace the placeholder values:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://your-project-ref.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key-here';
  static const String appDomain = 'https://your-username.github.io/your-repo-name';
}
```

## Step 4: Update Dependencies

Run the following command to install Supabase dependencies:

```bash
flutter pub get
```

## Step 5: Test the Connection

1. Run your Flutter app:
   ```bash
   flutter run -d chrome
   ```

2. Try creating a new todo list
3. Check your Supabase **Table Editor** to see if the data appears in the `todo_lists` table

## Step 6: Configure Row Level Security (RLS)

The schema automatically sets up RLS policies for public access to shared lists. You can customize these in the **SQL Editor**:

### For Public Read-Only Access:
```sql
-- Already included in schema - allows anyone to view shared lists
CREATE POLICY "Public read access to shared todo lists" ON todo_lists
    FOR SELECT USING (is_shared = TRUE AND share_token IS NOT NULL);
```

### For Public Edit Access:
```sql
-- Already included - allows editing of shared lists when enabled
CREATE POLICY "Public edit access to shared todo lists" ON todo_lists
    FOR UPDATE USING (
        is_shared = TRUE 
        AND share_token IS NOT NULL 
        AND allow_anonymous_edit = TRUE
        AND (share_expires_at IS NULL OR share_expires_at > NOW())
    );
```

## Step 7: Configure Shareable Links

1. Update the `_generateShareableUrl` method in `lib/services/supabase_service.dart`:

```dart
String _generateShareableUrl(String token) {
  return '${SupabaseConfig.appDomain}/#/shared/$token';
}
```

2. Make sure `SupabaseConfig.appDomain` matches your GitHub Pages URL

## Step 8: Enable Real-time Updates (Optional)

For real-time collaboration, enable real-time in your Supabase dashboard:

1. Go to **Settings** > **API**
2. Scroll down to **Real-time**
3. Enable real-time for your tables:
   - `todo_lists`
   - `todo_items`

## Step 9: Deploy to GitHub Pages

1. Build your Flutter web app:
   ```bash
   flutter build web --release
   ```

2. Deploy to GitHub Pages using the provided scripts:
   ```bash
   # Windows
   deploy.bat
   
   # Mac/Linux
   ./deploy.sh
   ```

## Testing Shareable Links

1. Create a todo list with "Generate shareable link" enabled
2. Copy the generated link
3. Open it in an incognito window
4. Verify you can view the todo list without authentication

## Database Features Explained

### Core Tables

**`todo_lists`**:
- Stores todo list metadata
- Handles scheduling and sharing
- Auto-generates share tokens
- Tracks completion statistics

**`todo_items`**:
- Individual tasks within lists
- Priority levels and due dates
- Completion tracking
- Auto-updates parent list statistics

**`todo_list_links`**:
- Manages relationships between lists
- Prevents duplicate and self-links
- Supports bidirectional linking

**`schedule_instances`**:
- Handles recurring schedules
- Tracks individual occurrences
- Supports multiple schedule types

**`share_access_log`**:
- Analytics for shared links
- Tracks access patterns
- Helps with usage statistics

### Advanced Features

**Recurring Schedules**:
- Daily, weekly, monthly, yearly
- Custom intervals (e.g., every 2 weeks)
- End dates for recurring series

**Anonymous Access**:
- View-only by default
- Optional edit permissions
- Configurable link expiration

**Performance Optimizations**:
- Strategic indexes on common queries
- Automatic statistics calculation
- Efficient date-based filtering

## Troubleshooting

### Common Issues

**"Failed to fetch todo lists"**:
- Check your Supabase URL and anon key
- Verify RLS policies allow public access
- Check network connectivity

**Share links don't work**:
- Verify `appDomain` is set correctly
- Check that `is_shared = true` and `share_token` is generated
- Ensure RLS policies allow public access

**Items not updating**:
- Check triggers are enabled
- Verify foreign key relationships
- Look for constraint violations

### Debug Mode

Enable debug mode in `supabase_service.dart`:

```dart
await Supabase.initialize(
  url: url,
  anonKey: anonKey,
  debug: true, // Enable for development
);
```

### Checking Logs

Monitor real-time activity in Supabase:
1. Go to **Logs** in your dashboard
2. Filter by table or operation
3. Look for error messages

## Production Considerations

### Security
- Never expose your `service_role` key in client code
- Use RLS policies to restrict data access
- Consider rate limiting for public endpoints

### Performance
- Monitor database usage in Supabase dashboard
- Consider enabling connection pooling for high traffic
- Optimize queries based on usage patterns

### Backup
- Supabase automatically backs up your data
- Consider additional backups for critical data
- Test restore procedures

## Cost Management

Supabase offers generous free tiers:
- **Database**: 500MB included
- **Auth**: 50,000 monthly active users
- **Storage**: 1GB included
- **Edge Functions**: 500,000 invocations

Monitor usage in your dashboard and upgrade as needed.

## Support

For Supabase-specific issues:
- [Supabase Documentation](https://supabase.com/docs)
- [Supabase Discord](https://discord.supabase.com)
- [GitHub Issues](https://github.com/supabase/supabase/issues)

For SparkDo-specific issues:
- Check the application logs
- Verify your configuration settings
- Test with a minimal example
