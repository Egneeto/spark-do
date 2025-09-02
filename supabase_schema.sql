-- =====================================================
-- SparkDo - Supabase PostgreSQL Schema
-- =====================================================
-- This schema supports:
-- - Todo Lists with scheduling and sharing
-- - Todo Items with priorities and due dates  
-- - List linking functionality
-- - Recurring schedules
-- - Web access without accounts
-- =====================================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- ENUMS
-- =====================================================

-- Priority levels for todo items
CREATE TYPE priority_level AS ENUM ('low', 'medium', 'high', 'urgent');

-- Schedule types for recurring todos
CREATE TYPE schedule_type AS ENUM ('none', 'daily', 'weekly', 'monthly', 'yearly', 'custom');

-- Access levels for shared lists
CREATE TYPE access_level AS ENUM ('view_only', 'edit', 'admin');

-- =====================================================
-- MAIN TABLES
-- =====================================================

-- Todo Lists table
CREATE TABLE todo_lists (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    description TEXT DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Scheduling fields
    scheduled_date TIMESTAMP WITH TIME ZONE,
    schedule_type schedule_type DEFAULT 'none',
    schedule_interval INTEGER DEFAULT 1, -- For custom recurring (e.g., every 2 weeks)
    schedule_end_date TIMESTAMP WITH TIME ZONE, -- When recurring should stop
    next_occurrence TIMESTAMP WITH TIME ZONE, -- Next scheduled occurrence
    
    -- Sharing fields
    is_shared BOOLEAN DEFAULT FALSE,
    share_token VARCHAR(64) UNIQUE, -- Unique token for web access
    share_expires_at TIMESTAMP WITH TIME ZONE, -- Optional expiration
    allow_anonymous_edit BOOLEAN DEFAULT FALSE, -- Allow editing without account
    
    -- Metadata
    is_archived BOOLEAN DEFAULT FALSE,
    completion_percentage NUMERIC(5,2) DEFAULT 0.00,
    total_items INTEGER DEFAULT 0,
    completed_items INTEGER DEFAULT 0
);

-- Todo Items table
CREATE TABLE todo_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    todo_list_id UUID NOT NULL REFERENCES todo_lists(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT DEFAULT '',
    
    -- Status and priority
    is_completed BOOLEAN DEFAULT FALSE,
    priority priority_level DEFAULT 'medium',
    
    -- Dates
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    due_date TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Ordering
    sort_order INTEGER DEFAULT 0
);

-- Todo List Links (for linking related lists)
CREATE TABLE todo_list_links (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_list_id UUID NOT NULL REFERENCES todo_lists(id) ON DELETE CASCADE,
    target_list_id UUID NOT NULL REFERENCES todo_lists(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Prevent duplicate links
    UNIQUE(source_list_id, target_list_id),
    -- Prevent self-linking
    CHECK(source_list_id != target_list_id)
);

-- Recurring Schedule Instances (for tracking individual occurrences)
CREATE TABLE schedule_instances (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    todo_list_id UUID NOT NULL REFERENCES todo_lists(id) ON DELETE CASCADE,
    scheduled_date TIMESTAMP WITH TIME ZONE NOT NULL,
    is_completed BOOLEAN DEFAULT FALSE,
    completion_percentage NUMERIC(5,2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Share Access Log (track who accessed shared lists)
CREATE TABLE share_access_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    todo_list_id UUID NOT NULL REFERENCES todo_lists(id) ON DELETE CASCADE,
    share_token VARCHAR(64) NOT NULL,
    access_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ip_address INET,
    user_agent TEXT,
    action VARCHAR(50) -- 'view', 'edit', 'complete_item', etc.
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Todo Lists indexes
CREATE INDEX idx_todo_lists_scheduled_date ON todo_lists(scheduled_date) WHERE scheduled_date IS NOT NULL;
CREATE INDEX idx_todo_lists_share_token ON todo_lists(share_token) WHERE share_token IS NOT NULL;
CREATE INDEX idx_todo_lists_created_at ON todo_lists(created_at);
CREATE INDEX idx_todo_lists_is_shared ON todo_lists(is_shared) WHERE is_shared = TRUE;

-- Todo Items indexes
CREATE INDEX idx_todo_items_list_id ON todo_items(todo_list_id);
CREATE INDEX idx_todo_items_due_date ON todo_items(due_date) WHERE due_date IS NOT NULL;
CREATE INDEX idx_todo_items_is_completed ON todo_items(is_completed);
CREATE INDEX idx_todo_items_priority ON todo_items(priority);
CREATE INDEX idx_todo_items_sort_order ON todo_items(todo_list_id, sort_order);

-- Schedule instances indexes
CREATE INDEX idx_schedule_instances_list_date ON schedule_instances(todo_list_id, scheduled_date);
CREATE INDEX idx_schedule_instances_date ON schedule_instances(scheduled_date);

-- Links indexes
CREATE INDEX idx_todo_list_links_source ON todo_list_links(source_list_id);
CREATE INDEX idx_todo_list_links_target ON todo_list_links(target_list_id);

-- Access log indexes
CREATE INDEX idx_share_access_log_token_time ON share_access_log(share_token, access_time);
CREATE INDEX idx_share_access_log_list_id ON share_access_log(todo_list_id);

-- =====================================================
-- FUNCTIONS AND TRIGGERS
-- =====================================================

-- Function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Function to generate share token
CREATE OR REPLACE FUNCTION generate_share_token()
RETURNS TEXT AS $$
BEGIN
    RETURN encode(gen_random_bytes(32), 'hex');
END;
$$ language 'plpgsql';

-- Function to update todo list completion stats
CREATE OR REPLACE FUNCTION update_todo_list_stats()
RETURNS TRIGGER AS $$
DECLARE
    list_id UUID;
    total_count INTEGER;
    completed_count INTEGER;
    completion_pct NUMERIC(5,2);
BEGIN
    -- Get the list ID from either OLD or NEW record
    list_id := COALESCE(NEW.todo_list_id, OLD.todo_list_id);
    
    -- Calculate totals
    SELECT 
        COUNT(*),
        COUNT(*) FILTER (WHERE is_completed = TRUE)
    INTO total_count, completed_count
    FROM todo_items 
    WHERE todo_list_id = list_id;
    
    -- Calculate percentage
    IF total_count > 0 THEN
        completion_pct := (completed_count::NUMERIC / total_count::NUMERIC) * 100;
    ELSE
        completion_pct := 0;
    END IF;
    
    -- Update the todo list
    UPDATE todo_lists 
    SET 
        total_items = total_count,
        completed_items = completed_count,
        completion_percentage = completion_pct,
        updated_at = NOW()
    WHERE id = list_id;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ language 'plpgsql';

-- Function to generate next occurrence for recurring schedules
CREATE OR REPLACE FUNCTION calculate_next_occurrence(
    base_date TIMESTAMP WITH TIME ZONE,
    schedule_type schedule_type,
    interval_value INTEGER
)
RETURNS TIMESTAMP WITH TIME ZONE AS $$
BEGIN
    CASE schedule_type
        WHEN 'daily' THEN
            RETURN base_date + (interval_value || ' days')::INTERVAL;
        WHEN 'weekly' THEN
            RETURN base_date + (interval_value || ' weeks')::INTERVAL;
        WHEN 'monthly' THEN
            RETURN base_date + (interval_value || ' months')::INTERVAL;
        WHEN 'yearly' THEN
            RETURN base_date + (interval_value || ' years')::INTERVAL;
        ELSE
            RETURN NULL;
    END CASE;
END;
$$ language 'plpgsql';

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Update timestamps triggers
CREATE TRIGGER update_todo_lists_updated_at 
    BEFORE UPDATE ON todo_lists 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_todo_items_updated_at 
    BEFORE UPDATE ON todo_items 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Update todo list statistics when items change
CREATE TRIGGER update_todo_list_stats_on_insert
    AFTER INSERT ON todo_items
    FOR EACH ROW EXECUTE FUNCTION update_todo_list_stats();

CREATE TRIGGER update_todo_list_stats_on_update
    AFTER UPDATE ON todo_items
    FOR EACH ROW EXECUTE FUNCTION update_todo_list_stats();

CREATE TRIGGER update_todo_list_stats_on_delete
    AFTER DELETE ON todo_items
    FOR EACH ROW EXECUTE FUNCTION update_todo_list_stats();

-- Auto-generate share token when is_shared is set to true
CREATE OR REPLACE FUNCTION auto_generate_share_token()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_shared = TRUE AND NEW.share_token IS NULL THEN
        NEW.share_token = generate_share_token();
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER auto_generate_share_token_trigger
    BEFORE INSERT OR UPDATE ON todo_lists
    FOR EACH ROW EXECUTE FUNCTION auto_generate_share_token();

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE todo_lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE todo_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE todo_list_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE schedule_instances ENABLE ROW LEVEL SECURITY;
ALTER TABLE share_access_log ENABLE ROW LEVEL SECURITY;

-- Policy for public access to shared todo lists (no authentication required)
CREATE POLICY "Public read access to shared todo lists" ON todo_lists
    FOR SELECT USING (is_shared = TRUE AND share_token IS NOT NULL);

-- Policy for public access to items in shared todo lists
CREATE POLICY "Public read access to shared todo items" ON todo_items
    FOR SELECT USING (
        todo_list_id IN (
            SELECT id FROM todo_lists 
            WHERE is_shared = TRUE AND share_token IS NOT NULL
        )
    );

-- Policy for public edit access to shared todo lists (if allowed)
CREATE POLICY "Public edit access to shared todo lists" ON todo_lists
    FOR UPDATE USING (
        is_shared = TRUE 
        AND share_token IS NOT NULL 
        AND allow_anonymous_edit = TRUE
        AND (share_expires_at IS NULL OR share_expires_at > NOW())
    );

-- Policy for public edit access to items in editable shared lists
CREATE POLICY "Public edit access to shared todo items" ON todo_items
    FOR ALL USING (
        todo_list_id IN (
            SELECT id FROM todo_lists 
            WHERE is_shared = TRUE 
            AND share_token IS NOT NULL 
            AND allow_anonymous_edit = TRUE
            AND (share_expires_at IS NULL OR share_expires_at > NOW())
        )
    );

-- Policy for public read access to links of shared lists
CREATE POLICY "Public read access to shared todo links" ON todo_list_links
    FOR SELECT USING (
        source_list_id IN (
            SELECT id FROM todo_lists 
            WHERE is_shared = TRUE AND share_token IS NOT NULL
        )
    );

-- Allow anyone to insert access logs (for analytics)
CREATE POLICY "Public insert access to share logs" ON share_access_log
    FOR INSERT WITH CHECK (TRUE);

-- =====================================================
-- VIEWS FOR EASY QUERYING
-- =====================================================

-- View for todo lists with computed stats
CREATE VIEW todo_lists_with_stats AS
SELECT 
    tl.*,
    CASE 
        WHEN tl.scheduled_date IS NOT NULL AND tl.scheduled_date < NOW() 
        AND tl.completion_percentage < 100 
        THEN TRUE 
        ELSE FALSE 
    END AS is_overdue,
    
    CASE 
        WHEN tl.schedule_type != 'none' THEN TRUE 
        ELSE FALSE 
    END AS is_recurring,
    
    (
        SELECT COUNT(*) FROM todo_list_links 
        WHERE source_list_id = tl.id
    ) AS linked_lists_count
    
FROM todo_lists tl
WHERE tl.is_archived = FALSE;

-- View for overdue todo items
CREATE VIEW overdue_todo_items AS
SELECT 
    ti.*,
    tl.title AS list_title
FROM todo_items ti
JOIN todo_lists tl ON ti.todo_list_id = tl.id
WHERE ti.due_date IS NOT NULL 
    AND ti.due_date < NOW() 
    AND ti.is_completed = FALSE
    AND tl.is_archived = FALSE;

-- View for today's scheduled todo lists
CREATE VIEW todays_scheduled_lists AS
SELECT 
    tl.*,
    si.id AS instance_id,
    si.completion_percentage AS instance_completion
FROM todo_lists tl
LEFT JOIN schedule_instances si ON tl.id = si.todo_list_id
WHERE DATE(COALESCE(si.scheduled_date, tl.scheduled_date)) = CURRENT_DATE
    AND tl.is_archived = FALSE;

-- =====================================================
-- SAMPLE DATA (OPTIONAL - REMOVE IN PRODUCTION)
-- =====================================================

-- Sample todo list
INSERT INTO todo_lists (id, title, description, is_shared, allow_anonymous_edit, scheduled_date) 
VALUES (
    '550e8400-e29b-41d4-a716-446655440000',
    'Sample Project Tasks',
    'A sample todo list to demonstrate the system',
    TRUE,
    TRUE,
    NOW() + INTERVAL '1 day'
);

-- Sample todo items
INSERT INTO todo_items (todo_list_id, title, description, priority, due_date) VALUES
('550e8400-e29b-41d4-a716-446655440000', 'Setup database schema', 'Create all necessary tables in Supabase', 'high', NOW() + INTERVAL '2 days'),
('550e8400-e29b-41d4-a716-446655440000', 'Implement API endpoints', 'Create Flutter service to connect with Supabase', 'medium', NOW() + INTERVAL '3 days'),
('550e8400-e29b-41d4-a716-446655440000', 'Test sharing functionality', 'Verify that shared links work correctly', 'high', NOW() + INTERVAL '4 days');

-- =====================================================
-- USEFUL QUERIES FOR DEVELOPMENT
-- =====================================================

/*
-- Get all shared todo lists with their share tokens
SELECT id, title, share_token, 
       CONCAT('https://your-domain.com/#/shared/', share_token) AS share_url
FROM todo_lists 
WHERE is_shared = TRUE;

-- Get todo list with all items and completion stats
SELECT 
    tl.title,
    tl.completion_percentage,
    ti.title AS item_title,
    ti.is_completed,
    ti.priority,
    ti.due_date
FROM todo_lists tl
LEFT JOIN todo_items ti ON tl.id = ti.todo_list_id
WHERE tl.id = 'your-list-id'
ORDER BY ti.sort_order;

-- Get all linked lists for a specific list
SELECT 
    tl.id,
    tl.title,
    'source' AS link_type
FROM todo_lists tl
JOIN todo_list_links tll ON tl.id = tll.target_list_id
WHERE tll.source_list_id = 'your-list-id'

UNION

SELECT 
    tl.id,
    tl.title,
    'target' AS link_type  
FROM todo_lists tl
JOIN todo_list_links tll ON tl.id = tll.source_list_id
WHERE tll.target_list_id = 'your-list-id';

-- Get upcoming scheduled lists for the next 7 days
SELECT * FROM todo_lists_with_stats 
WHERE scheduled_date BETWEEN NOW() AND NOW() + INTERVAL '7 days'
ORDER BY scheduled_date;
*/
