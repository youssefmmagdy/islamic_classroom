# Supabase Setup Instructions

## 1. Create Supabase Project
1. Go to [supabase.com](https://supabase.com) and sign up/login
2. Create a new project
3. Note down your project URL and anon key

## 2. Database Setup
1. Go to your Supabase dashboard
2. Navigate to SQL Editor
3. Copy and paste the contents of `supabase_schema.sql` file
4. Execute the SQL to create all necessary tables and policies

## 3. Update Configuration
1. In your Supabase dashboard, go to Settings > API
2. Copy your project URL and anon key
3. Update the `main.dart` file with your actual keys:

```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL_HERE',
  anonKey: 'YOUR_ANON_KEY_HERE',
);
```

## 4. Email Authentication Setup (Optional)
1. Go to Authentication > Settings in your Supabase dashboard
2. Configure email templates if needed
3. Set up email confirmation if required

## 5. Row Level Security (RLS)
The schema already includes RLS policies that:
- Allow users to view/edit their own data
- Allow teachers to view student data for their courses
- Allow parents to view their children's data
- Protect sensitive operations

## 6. Testing
After setup, you can:
1. Register new users through the app
2. Check the `auth.users` and `public.users` tables in Supabase
3. Test login functionality
4. Verify data is being saved correctly

## Database Structure

### Core Tables:
- `users` - Extended user information (linked to auth.users)
- `students` - Student-specific data
- `courses` - Course information
- `course_enrollments` - Student-course relationships
- `sessions` - Class sessions
- `homework` - Homework assignments
- `homework_submissions` - Student homework submissions
- `attendance` - Attendance records

### Key Features:
- Complete user registration with validation
- Role-based access (teacher, student, parent)
- Automatic timestamps (created_at, updated_at)
- Foreign key relationships
- Data integrity constraints
- Security policies

## Environment Variables
The app reads from a `.env` file for the database URL, but the Supabase configuration is done directly in the code for simplicity.

## Next Steps
1. Set up your Supabase project
2. Run the schema SQL
3. Update the configuration in main.dart
4. Test registration and login
5. Extend with additional features as needed