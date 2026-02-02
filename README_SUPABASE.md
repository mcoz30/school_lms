# LearnNovaLMS - Supabase Integration

## Overview
This version of LearnNovaLMS has been migrated from Firebase to Supabase for all data storage operations. All features (add student, add teacher, add course, etc.) now save data to Supabase.

## Supabase Setup Instructions

### 1. Create a Supabase Project
1. Go to [https://supabase.com](https://supabase.com)
2. Create a free account and a new project
3. Wait for your project to be provisioned (usually 1-2 minutes)

### 2. Run the SQL Setup Script
1. Go to your Supabase project dashboard
2. Navigate to the **SQL Editor** in the left sidebar
3. Click "New Query"
4. Copy and paste the contents of `supabase_setup.sql`
5. Click "Run" to execute the script

This will create the `app_data` table and set up the necessary permissions.

### 3. Update Configuration (if needed)
The application is already configured with your Supabase credentials:
- **URL**: https://lgovvztkuqnpsshdrwyu.supabase.co
- **Anon Key**: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxnb3Z2enRrdXFucHNzaGRyd3l1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAwMTY0OTgsImV4cCI6MjA4NTU5MjQ5OH0.0gks6pz9g8JCP6LMiKEGQj3J-M27ljGPLwv-umyoPVA

If you need to change these, update the values in `textassse.html`:
```javascript
const supabaseUrl = 'YOUR_SUPABASE_URL';
const supabaseKey = 'YOUR_SUPABASE_ANON_KEY';
```

### 4. Enable Realtime (Optional)
If you want real-time updates across multiple browsers:
1. Go to your Supabase project dashboard
2. Navigate to **Database** > **Replication**
3. Enable replication for the `app_data` table

## Features Using Supabase

All data operations now use Supabase:
- ✅ User registration (students, teachers)
- ✅ User authentication (login)
- ✅ Course management (create, edit, delete)
- ✅ Student enrollment
- ✅ Activity creation and submissions
- ✅ Exam/quiz management
- ✅ Grade management
- ✅ Calendar events
- ✅ Global posts/announcements
- ✅ Theme customization
- ✅ Module/content management

## Authentication

The application uses a simplified authentication system:
- Users are stored in the Supabase `app_data` table
- Login validates username and password against stored users
- All user data persists in Supabase

**Default Users:**
- Admin: username `admin`, password `123`
- Teacher: username `teacher`, password `123`
- Student: username `student`, password `123`

## Database Structure

All data is stored in a single `app_data` table with the following structure:
```json
{
  "id": "master_record",
  "data": {
    "users": [...],
    "subjects": [...],
    "posts": [...],
    "globalPosts": [...],
    "activities": {...},
    "activitySubmissions": {...},
    "exams": {...},
    "examSubmissions": {...},
    "modules": {...},
    "globalEvents": [...],
    "theme": {...}
  },
  "created_at": "2025-01-...",
  "updated_at": "2025-01-..."
}
```

## Security Notes

⚠️ **Important**: The current setup uses the anon key and allows public read/write access for demonstration purposes. For production use:

1. Enable proper Row Level Security (RLS) policies
2. Implement proper authentication with Supabase Auth
3. Use service role keys for admin operations
4. Add proper user session management

## Troubleshooting

### "Database table not found" Error
- Make sure you ran the `supabase_setup.sql` script in your Supabase SQL Editor

### "Failed to save data" Error
- Check that your Supabase URL and anon key are correct
- Verify the `app_data` table exists
- Check browser console for specific error messages

### Data not persisting
- Check your Supabase project's data logs
- Verify network connectivity
- Ensure the table has proper permissions

## Migration from Firebase

If you have existing Firebase data:
1. Export your Firebase data
2. Convert it to match the Supabase data structure
3. Use the Supabase SQL Editor to insert the data manually
4. Or modify the `initSupabase()` function to handle migration

## Support

For issues or questions:
1. Check the browser console for error messages
2. Verify Supabase table structure
3. Review Supabase logs in your project dashboard
4. Ensure all SQL setup steps were completed

---

**Note**: This migration maintains all existing functionality while switching to Supabase as the backend. The user interface and features remain unchanged.