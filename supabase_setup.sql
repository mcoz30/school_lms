-- Create the app_data table to store all LMS data
CREATE TABLE IF NOT EXISTS app_data (
    id TEXT PRIMARY KEY,
    data JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security (RLS)
ALTER TABLE app_data ENABLE ROW LEVEL SECURITY;

-- Allow public read access (for demo purposes)
-- In production, you might want to restrict this
CREATE POLICY "Allow public read access" ON app_data
    FOR SELECT
    TO public
    USING (true);

-- Allow public upsert access (for demo purposes)
-- In production, you might want to restrict this
CREATE POLICY "Allow public upsert access" ON app_data
    FOR INSERT
    TO public
    WITH CHECK (true);

CREATE POLICY "Allow public update access" ON app_data
    FOR UPDATE
    TO public
    USING (true);

-- Create an index on the id column for better performance
CREATE INDEX IF NOT EXISTS app_data_id_idx ON app_data(id);

-- Insert initial data (optional - will be created automatically by the app)
INSERT INTO app_data (id, data)
VALUES (
    'master_record',
    '{"users": [], "subjects": [], "posts": [], "globalPosts": [], "activities": {}, "activitySubmissions": {}, "exams": {}, "examSubmissions": {}, "modules": {}, "globalEvents": [], "theme": {"appName": "LearnNovaLMS", "logoUrl": "", "bgType": "color", "bgColor": "#F5F5F5", "bgGradient": "linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%)", "bgImage": "", "glassEffect": false, "glassOpacity": 0.95}}'
) ON CONFLICT (id) DO NOTHING;