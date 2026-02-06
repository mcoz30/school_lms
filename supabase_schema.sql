-- ============================================
-- LEARNNOVA LMS - SUPABASE DATABASE SCHEMA
-- ============================================
-- Run this in your Supabase SQL Editor to set up the database

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- USERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    auth_id UUID UNIQUE, -- Link to Supabase Auth
    name VARCHAR(255) NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255), -- For demo purposes - use Supabase Auth in production
    email VARCHAR(255) UNIQUE,
    role VARCHAR(20) NOT NULL CHECK (role IN ('admin', 'teacher', 'student')),
    avatar VARCHAR(10) DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);

-- Insert default users
INSERT INTO users (name, username, password, role, avatar) VALUES
    ('School Admin', 'admin', '123', 'admin', 'AD'),
    ('Mrs. Anderson', 'teacher', '123', 'teacher', 'MA'),
    ('Juan Dela Cruz', 'student', '123', 'student', 'JD'),
    ('Maria Santos', 'student2', '123', 'student', 'MS')
ON CONFLICT (username) DO NOTHING;

-- ============================================
-- SUBJECTS (COURSES) TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS subjects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50) NOT NULL,
    teacher_id UUID REFERENCES users(id) ON DELETE SET NULL,
    students UUID[] DEFAULT ARRAY[]::UUID[],
    color VARCHAR(7) DEFAULT '#0374B5',
    img TEXT,
    intro_title VARCHAR(255),
    intro_body TEXT,
    grading_weights JSONB DEFAULT '{"ww": 40, "pt": 40, "qa": 20}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default course
INSERT INTO subjects (name, code, teacher_id, students, color, img, intro_title, intro_body) VALUES
    ('Introduction to Physics', 'PHYS-101', 
     (SELECT id FROM users WHERE username = 'teacher' LIMIT 1),
     ARRAY[(SELECT id FROM users WHERE username = 'student' LIMIT 1),
           (SELECT id FROM users WHERE username = 'student2' LIMIT 1)],
     '#0374B5',
     'https://images.unsplash.com/photo-1636466497217-26a8cbeaf0aa?auto=format&fit=crop&w=600&q=80',
     'Welcome to Physics', 'Check the feed.')
ON CONFLICT DO NOTHING;

-- ============================================
-- POSTS TABLE (Announcements/Discussions)
-- ============================================
CREATE TABLE IF NOT EXISTS posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_id UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    author_id UUID REFERENCES users(id) ON DELETE SET NULL,
    author_name VARCHAR(255),
    content TEXT NOT NULL,
    media_type VARCHAR(20) DEFAULT 'text' CHECK (media_type IN ('text', 'image', 'video', 'file')),
    media_url TEXT,
    is_pinned BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default post
INSERT INTO posts (course_id, author_id, author_name, content, is_pinned) VALUES
    ((SELECT id FROM subjects WHERE code = 'PHYS-101' LIMIT 1),
     (SELECT id FROM users WHERE username = 'teacher' LIMIT 1),
     'Mrs. Anderson',
     'Welcome to class!',
     false)
ON CONFLICT DO NOTHING;

-- ============================================
-- MODULES TABLE (Course Content)
-- ============================================
CREATE TABLE IF NOT EXISTS modules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_id UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    blocks JSONB DEFAULT '[]'::jsonb,
    publish_date TIMESTAMP WITH TIME ZONE,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- ACTIVITIES TABLE (Assignments)
-- ============================================
CREATE TABLE IF NOT EXISTS activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_id UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    activity_type VARCHAR(50) CHECK (activity_type IN ('written_output', 'performance_task', 'quarterly_assessment')),
    points INTEGER DEFAULT 100,
    due_date TIMESTAMP WITH TIME ZONE,
    unlock_date TIMESTAMP WITH TIME ZONE,
    lock_date TIMESTAMP WITH TIME ZONE,
    blocks JSONB DEFAULT '[]'::jsonb,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- ACTIVITY SUBMISSIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS activity_submissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_id UUID NOT NULL,
    activity_id UUID NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT,
    grade NUMERIC(5,2),
    graded_at TIMESTAMP WITH TIME ZONE,
    graded_by UUID REFERENCES users(id),
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(activity_id, student_id)
);

-- ============================================
-- EXAMS TABLE (Quizzes/Tests)
-- ============================================
CREATE TABLE IF NOT EXISTS exams (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_id UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    questions JSONB NOT NULL,
    points INTEGER DEFAULT 100,
    time_limit INTEGER, -- Time in minutes
    due_date TIMESTAMP WITH TIME ZONE,
    unlock_date TIMESTAMP WITH TIME ZONE,
    lock_date TIMESTAMP WITH TIME ZONE,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- EXAM SUBMISSIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS exam_submissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_id UUID NOT NULL,
    exam_id UUID NOT NULL REFERENCES exams(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    answers JSONB,
    score NUMERIC(5,2),
    correct INTEGER,
    total INTEGER,
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(exam_id, student_id)
);

-- ============================================
-- GRADES TABLE (Student Grades)
-- ============================================
CREATE TABLE IF NOT EXISTS grades (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_id UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    item_id UUID NOT NULL, -- ID of activity or exam
    item_type VARCHAR(20) CHECK (item_type IN ('activity', 'exam')),
    grade_value NUMERIC(5,2),
    max_points INTEGER,
    letter_grade VARCHAR(2),
    comments TEXT,
    graded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(course_id, student_id, item_id)
);

-- ============================================
-- GLOBAL EVENTS TABLE (Calendar)
-- ============================================
CREATE TABLE IF NOT EXISTS global_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    event_date DATE NOT NULL,
    event_type VARCHAR(20) DEFAULT 'other',
    color VARCHAR(7) DEFAULT '#0374B5',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- AUTO-UPDATE TIMESTAMPS FUNCTION
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables with updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subjects_updated_at BEFORE UPDATE ON subjects
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_posts_updated_at BEFORE UPDATE ON posts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_modules_updated_at BEFORE UPDATE ON modules
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_activities_updated_at BEFORE UPDATE ON activities
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_activity_submissions_updated_at BEFORE UPDATE ON activity_submissions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_exams_updated_at BEFORE UPDATE ON exams
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_exam_submissions_updated_at BEFORE UPDATE ON exam_submissions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_grades_updated_at BEFORE UPDATE ON grades
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_global_events_updated_at BEFORE UPDATE ON global_events
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE exams ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE grades ENABLE ROW LEVEL SECURITY;
ALTER TABLE global_events ENABLE ROW LEVEL SECURITY;

-- ============================================
-- USERS TABLE POLICIES
-- ============================================

-- Everyone can view users (for display names, etc.)
CREATE POLICY "Public can view users" ON users
    FOR SELECT USING (true);

-- Only authenticated users can update their own profile
CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid()::text = id::text);

-- ============================================
-- SUBJECTS TABLE POLICIES
-- ============================================

-- Public can view published subjects
CREATE POLICY "Public can view subjects" ON subjects
    FOR SELECT USING (true);

-- Teachers can create subjects
CREATE POLICY "Teachers can create subjects" ON subjects
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM users WHERE id = teacher_id AND role = 'teacher'
        )
    );

-- Teachers can update their own subjects
CREATE POLICY "Teachers can update own subjects" ON subjects
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM users WHERE id = teacher_id AND role = 'teacher'
        )
    );

-- ============================================
-- POSTS TABLE POLICIES
-- ============================================

-- Enrolled students can view posts
CREATE POLICY "Enrolled can view posts" ON posts
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM subjects 
            WHERE subjects.id = posts.course_id
            AND posts.author_id = subjects.teacher_id
        )
    );

-- Teachers can create posts in their courses
CREATE POLICY "Teachers can create posts" ON posts
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM subjects 
            WHERE subjects.id = posts.course_id
            AND subjects.teacher_id = auth.uid()::text::uuid
        )
    );

-- ============================================
-- MODULES TABLE POLICIES
-- ============================================

-- Enrolled students can view published modules
CREATE POLICY "Enrolled can view modules" ON modules
    FOR SELECT USING (
        publish_date IS NULL OR publish_date <= NOW()
    );

-- Teachers can manage modules in their courses
CREATE POLICY "Teachers can manage modules" ON modules
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM subjects 
            WHERE subjects.id = modules.course_id
            AND subjects.teacher_id = auth.uid()::text::uuid
        )
    );

-- ============================================
-- ACTIVITIES TABLE POLICIES
-- ============================================

-- Enrolled students can view published activities
CREATE POLICY "Enrolled can view activities" ON activities
    FOR SELECT USING (
        unlock_date IS NULL OR unlock_date <= NOW()
    );

-- Teachers can manage activities in their courses
CREATE POLICY "Teachers can manage activities" ON activities
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM subjects 
            WHERE subjects.id = activities.course_id
            AND subjects.teacher_id = auth.uid()::text::uuid
        )
    );

-- ============================================
-- ACTIVITY SUBMISSIONS POLICIES
-- ============================================

-- Students can view their own submissions
CREATE POLICY "Students can view own submissions" ON activity_submissions
    FOR SELECT USING (student_id = auth.uid()::text::uuid);

-- Students can create their own submissions
CREATE POLICY "Students can create submissions" ON activity_submissions
    FOR INSERT WITH CHECK (student_id = auth.uid()::text::uuid);

-- Teachers can view all submissions for their courses
CREATE POLICY "Teachers can view all submissions" ON activity_submissions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM activities a
            JOIN subjects s ON s.id = a.course_id
            WHERE a.id = activity_id
            AND s.teacher_id = auth.uid()::text::uuid
        )
    );

-- Teachers can grade submissions
CREATE POLICY "Teachers can grade submissions" ON activity_submissions
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM activities a
            JOIN subjects s ON s.id = a.course_id
            WHERE a.id = activity_id
            AND s.teacher_id = auth.uid()::text::uuid
        )
    );

-- ============================================
-- EXAMS TABLE POLICIES
-- ============================================

-- Enrolled students can view published exams
CREATE POLICY "Enrolled can view exams" ON exams
    FOR SELECT USING (
        unlock_date IS NULL OR unlock_date <= NOW()
    );

-- Teachers can manage exams in their courses
CREATE POLICY "Teachers can manage exams" ON exams
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM subjects 
            WHERE subjects.id = exams.course_id
            AND subjects.teacher_id = auth.uid()::text::uuid
        )
    );

-- ============================================
-- EXAM SUBMISSIONS POLICIES
-- ============================================

-- Students can view their own exam submissions
CREATE POLICY "Students can view own exam submissions" ON exam_submissions
    FOR SELECT USING (student_id = auth.uid()::text::uuid);

-- Students can create their own exam submissions
CREATE POLICY "Students can create exam submissions" ON exam_submissions
    FOR INSERT WITH CHECK (student_id = auth.uid()::text::uuid);

-- Teachers can view all exam submissions for their courses
CREATE POLICY "Teachers can view all exam submissions" ON exam_submissions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM exams e
            JOIN subjects s ON s.id = e.course_id
            WHERE e.id = exam_id
            AND s.teacher_id = auth.uid()::text::uuid
        )
    );

-- ============================================
-- GRADES TABLE POLICIES
-- ============================================

-- Students can view their own grades
CREATE POLICY "Students can view own grades" ON grades
    FOR SELECT USING (student_id = auth.uid()::text::uuid);

-- Teachers can view all grades for their courses
CREATE POLICY "Teachers can view all grades" ON grades
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM subjects 
            WHERE subjects.id = grades.course_id
            AND subjects.teacher_id = auth.uid()::text::uuid
        )
    );

-- Teachers can create/update grades
CREATE POLICY "Teachers can manage grades" ON grades
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM subjects 
            WHERE subjects.id = grades.course_id
            AND subjects.teacher_id = auth.uid()::text::uuid
        )
    );

-- ============================================
-- GLOBAL EVENTS POLICIES
-- ============================================

-- Everyone can view events
CREATE POLICY "Public can view events" ON global_events
    FOR SELECT USING (true);

-- Admins can manage events
CREATE POLICY "Admins can manage events" ON global_events
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users WHERE id = auth.uid()::text::uuid AND role = 'admin'
        )
    );

-- ============================================
-- REAL-TIME REPLICATION
-- ============================================

-- Enable real-time for all tables
ALTER PUBLICATION supabase_realtime ADD TABLE users;
ALTER PUBLICATION supabase_realtime ADD TABLE posts;
ALTER PUBLICATION supabase_realtime ADD TABLE activities;
ALTER PUBLICATION supabase_realtime ADD TABLE modules;
ALTER PUBLICATION supabase_realtime ADD TABLE exams;
ALTER PUBLICATION supabase_realtime ADD TABLE activity_submissions;
ALTER PUBLICATION supabase_realtime ADD TABLE exam_submissions;
ALTER PUBLICATION supabase_realtime ADD TABLE grades;

-- ============================================
-- SCHEMA COMPLETE
-- ============================================