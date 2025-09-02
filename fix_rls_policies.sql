-- =====================================================
-- FIX RLS POLICIES FOR TODO LIST CREATION
-- =====================================================
-- Run this SQL in your Supabase SQL editor to fix the RLS policy issue

-- Drop existing restrictive policies
DROP POLICY IF EXISTS "Public read access to shared todo lists" ON todo_lists;
DROP POLICY IF EXISTS "Public edit access to shared todo lists" ON todo_lists;
DROP POLICY IF EXISTS "Public read access to shared todo items" ON todo_items;
DROP POLICY IF EXISTS "Public edit access to shared todo items" ON todo_items;
DROP POLICY IF EXISTS "Public read access to shared todo links" ON todo_list_links;

-- Create new policies that allow anonymous access for all operations
-- (This is suitable for a demo app - for production, you'd want more restrictive policies)

-- Allow anyone to read all todo lists
CREATE POLICY "Allow public read access" ON todo_lists
    FOR SELECT USING (TRUE);

-- Allow anyone to create todo lists
CREATE POLICY "Allow public insert access" ON todo_lists
    FOR INSERT WITH CHECK (TRUE);

-- Allow anyone to update todo lists
CREATE POLICY "Allow public update access" ON todo_lists
    FOR UPDATE USING (TRUE);

-- Allow anyone to delete todo lists
CREATE POLICY "Allow public delete access" ON todo_lists
    FOR DELETE USING (TRUE);

-- Allow anyone to read all todo items
CREATE POLICY "Allow public read access" ON todo_items
    FOR SELECT USING (TRUE);

-- Allow anyone to create todo items
CREATE POLICY "Allow public insert access" ON todo_items
    FOR INSERT WITH CHECK (TRUE);

-- Allow anyone to update todo items
CREATE POLICY "Allow public update access" ON todo_items
    FOR UPDATE USING (TRUE);

-- Allow anyone to delete todo items
CREATE POLICY "Allow public delete access" ON todo_items
    FOR DELETE USING (TRUE);

-- Allow anyone to read todo list links
CREATE POLICY "Allow public read access" ON todo_list_links
    FOR SELECT USING (TRUE);

-- Allow anyone to create todo list links
CREATE POLICY "Allow public insert access" ON todo_list_links
    FOR INSERT WITH CHECK (TRUE);

-- Allow anyone to update todo list links
CREATE POLICY "Allow public update access" ON todo_list_links
    FOR UPDATE USING (TRUE);

-- Allow anyone to delete todo list links
CREATE POLICY "Allow public delete access" ON todo_list_links
    FOR DELETE USING (TRUE);

-- Allow anyone to read schedule instances
CREATE POLICY "Allow public read access" ON schedule_instances
    FOR SELECT USING (TRUE);

-- Allow anyone to create schedule instances
CREATE POLICY "Allow public insert access" ON schedule_instances
    FOR INSERT WITH CHECK (TRUE);

-- Allow anyone to update schedule instances
CREATE POLICY "Allow public update access" ON schedule_instances
    FOR UPDATE USING (TRUE);

-- Allow anyone to delete schedule instances
CREATE POLICY "Allow public delete access" ON schedule_instances
    FOR DELETE USING (TRUE);

-- Keep the existing policy for share access log (insert only)
-- This was already working correctly

-- Verify the policies are active
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('todo_lists', 'todo_items', 'todo_list_links', 'schedule_instances')
ORDER BY tablename, policyname;
