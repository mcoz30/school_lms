# GitHub Pages Deployment Guide

## How to Host LearnNovaLMS on GitHub Pages

### Step 1: Create a GitHub Repository
1. Go to [github.com](https://github.com) and create a new repository
2. Name it something like `learnnova-lms` or `school-lms`
3. Make it **Public** (recommended for GitHub Pages)
4. Don't initialize with README (we'll add our files)

### Step 2: Upload Your Files
**Option A: Using GitHub Web Interface**
1. In your new repository, click "Upload files"
2. Drag and drop these files:
   - `textassse.html` (rename to `index.html` for GitHub Pages)
   - `supabase_setup.sql` (for documentation)
   - `README_SUPABASE.md` (for documentation)
3. Click "Commit changes"

**Option B: Using Git Command Line**
```bash
# Initialize git
git init

# Add files
git add textassse.html supabase_setup.sql README_SUPABASE.md

# Commit
git commit -m "Initial commit - LearnNovaLMS with Supabase"

# Rename main file for GitHub Pages
git mv textassse.html index.html
git commit -m "Rename to index.html for GitHub Pages"

# Add remote (replace with your repo URL)
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git

# Push to GitHub
git branch -M main
git push -u origin main
```

### Step 3: Enable GitHub Pages
1. Go to your repository on GitHub
2. Click **Settings** tab
3. Scroll down to **GitHub Pages** section
4. Under **Source**, select:
   - Branch: `main`
   - Folder: `/(root)`
5. Click **Save**

### Step 4: Access Your LMS
1. Wait 1-2 minutes for deployment
2. Your LMS will be available at:
   ```
   https://YOUR_USERNAME.github.io/YOUR_REPO/
   ```
3. Share this URL with students and teachers!

---

## ✅ What Students & Teachers Will See

### 👨‍🎓 When a STUDENT Logs In:
- ✅ **Dashboard**: See announcements from admin
- ✅ **My Courses**: Only courses they're enrolled in
- ✅ **Course Materials**: View modules, activities, resources
- ✅ **Submit Work**: Submit assignments and activities
- ✅ **Take Quizzes**: Access and submit exams/quizzes
- ✅ **View Grades**: See their own grades and progress
- ✅ **Calendar**: See due dates and events
- ✅ **Settings**: Update their profile and password

### 👩‍🏫 When a TEACHER Logs In:
- ✅ **Dashboard**: Post announcements, manage calendar
- ✅ **My Courses**: All courses they teach
- ✅ **Manage Students**: View enrolled students
- ✅ **Create Content**: Add modules, activities, resources
- ✅ **Create Quizzes**: Build exams and quizzes
- ✅ **Grade Work**: Review and grade submissions
- ✅ **View Analytics**: See student progress and performance
- ✅ **Register Students**: Enroll new students (from course page)
- ✅ **Settings**: Update profile and course details

### 👑 When an ADMIN Logs In:
- ✅ **Everything**: All teacher features PLUS:
- ✅ **Register Teachers**: Add new teacher accounts
- ✅ **Manage All Users**: View and delete users
- ✅ **Create Courses**: Create any course and assign teachers
- ✅ **Design System**: Customize colors, logos, themes
- ✅ **Global Announcements**: Post school-wide updates
- ✅ **Global Events**: Add school calendar events
- ✅ **View All Data**: Access all courses, grades, and activities

---

## 🔐 Data Security & Privacy

### What Each Role Can See:
| Feature | Student | Teacher | Admin |
|---------|---------|---------|-------|
| Own Profile | ✅ | ✅ | ✅ |
| Own Grades | ✅ | ❌ | ✅ |
| Enrolled Courses | ✅ | ✅ (own) | ✅ (all) |
| Course Content | ✅ | ✅ (own) | ✅ (all) |
| Student Submissions | ❌ | ✅ (in own courses) | ✅ (all) |
| All Users Data | ❌ | ❌ | ✅ |
| System Settings | ❌ | ❌ | ✅ |

### Important Notes:
- Students **CANNOT** see other students' grades or work
- Teachers **CANNOT** see other teachers' courses
- Each user sees only what's relevant to their role
- All data is stored securely in Supabase
- Login credentials are validated against the database

---

## 🎯 Real-World Example

### Scenario: Teacher "Mrs. Anderson" logs in

**She will see:**
1. Her dashboard with announcements
2. Her course "Introduction to Physics" (PHYS-101)
3. Students enrolled in her course (Juan, Maria, etc.)
4. Assignments and activities she created
5. Quizzes she built
6. Submissions from her students
7. Grading tools for her students

**She will NOT see:**
- Other teachers' courses
- Students in other teachers' classes
- Admin settings
- Other teachers' grades

### Scenario: Student "Juan" logs in

**He will see:**
1. His dashboard with announcements
2. His courses (only ones he's enrolled in)
3. Course materials and resources
4. His assignments and due dates
5. Quizzes he needs to take
6. His own grades and feedback
7. His profile settings

**He will NOT see:**
- Other students' grades or work
- Teacher grading tools
- Other courses he's not enrolled in
- Admin controls

---

## 📱 Sharing Your LMS

### With Students:
1. Share the GitHub Pages URL: `https://yourname.github.io/your-repo/`
2. Give them their username and password
3. They log in and see their courses!

### With Teachers:
1. Share the same URL
2. Give them teacher credentials
3. They log in and see their courses and students

### Example Email to Send:
```
Welcome to LearnNovaLMS!

🎓 Student Portal: https://yourname.github.io/learnnova-lms/

Your Login Details:
Username: student123
Password: class2025

Please log in to access your courses, assignments, and grades.

Need help? Contact the school office.
```

---

## 🔄 Real-Time Data Sync

### How It Works:
1. Teacher adds an assignment → Saves to Supabase
2. Student logs in → Loads data from Supabase
3. Student sees the assignment immediately
4. Student submits work → Saves to Supabase
5. Teacher logs in → Sees the submission
6. Teacher grades it → Saves to Supabase
7. Student logs in → Sees their grade

**All happens in real-time across all users!**

---

## 🚨 Important Setup Reminder

Before sharing your LMS:
1. ✅ Run `supabase_setup.sql` in your Supabase project
2. ✅ Test with `test_supabase.html` to verify connection
3. ✅ Register all users (students, teachers, admin)
4. ✅ Create courses and enroll students
5. ✅ Deploy to GitHub Pages
6. ✅ Test login for each role

---

## 📊 Sample User Data Structure

When you register users, they're stored like this:

```json
{
  "users": [
    {
      "id": "u1234567890",
      "name": "Mrs. Anderson",
      "username": "manderson",
      "password": "teacher123",
      "role": "teacher",
      "avatar": "MA"
    },
    {
      "id": "u9876543210",
      "name": "Juan Dela Cruz",
      "username": "juan",
      "password": "student123",
      "role": "student",
      "avatar": "JD"
    }
  ]
}
```

Each user sees data based on their role!

---

## 💡 Pro Tips

1. **Change Default Passwords**: After first login, tell users to change passwords
2. **Use Usernames Wisely**: Use school IDs or email for usernames
3. **Register Early**: Register all users before the term starts
4. **Test Each Role**: Log in as student, teacher, and admin to verify
5. **Keep SQL Script Safe**: You might need it if you reset the database

---

**Your LMS is now ready for GitHub Pages deployment!** 🎉