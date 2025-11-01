# New Database Schema Documentation

## Overview
This document describes the improved inheritance-based database schema for the Islamic education classroom management app. The new design provides better data organization and follows database normalization principles.

## Schema Design

### Base Table: `users`
The `users` table serves as the base table that all user types inherit from.

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    phone VARCHAR(20) NOT NULL,
    gender VARCHAR(10) CHECK (gender IN ('male', 'female')) NOT NULL,
    birth_date DATE NOT NULL,
    password VARCHAR(255), -- Managed by Supabase Auth
    country_code VARCHAR(10) NOT NULL
);
```

### Inheritance Tables

#### 1. Students Table
Students inherit the user's ID and extend with student-specific information.

```sql
CREATE TABLE students (
    id UUID REFERENCES users(id) ON DELETE CASCADE PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    parent_id UUID REFERENCES users(id) ON DELETE SET NULL
);
```

#### 2. Parents Table
Parents inherit the user's ID and can be linked to students.

```sql
CREATE TABLE parents (
    id UUID REFERENCES users(id) ON DELETE CASCADE PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    student_id UUID REFERENCES users(id) ON DELETE SET NULL
);
```

#### 3. Teachers Table
Teachers inherit the user's ID and can be assigned to courses.

```sql
CREATE TABLE teachers (
    id UUID REFERENCES users(id) ON DELETE CASCADE PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    course_id UUID REFERENCES courses(id) ON DELETE SET NULL
);
```

### Academic Tables

#### 1. Courses Table
```sql
CREATE TABLE courses (
    id UUID PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    title VARCHAR(255) NOT NULL,
    teacher_id UUID REFERENCES users(id) ON DELETE CASCADE
);
```

#### 2. Sessions Table
```sql
CREATE TABLE sessions (
    id UUID PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    teacher_id UUID REFERENCES users(id) ON DELETE CASCADE,
    course_id UUID REFERENCES courses(id) ON DELETE CASCADE,
    desc TEXT
);
```

#### 3. Attendance Table
```sql
CREATE TABLE attendance (
    id UUID PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    session_id UUID REFERENCES sessions(id) ON DELETE CASCADE,
    course_id UUID REFERENCES courses(id) ON DELETE CASCADE,
    date DATE NOT NULL DEFAULT CURRENT_DATE
);
```

#### 4. Assignments Table
```sql
CREATE TABLE assignments (
    id UUID PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    course_id UUID REFERENCES courses(id) ON DELETE CASCADE,
    session_id UUID REFERENCES sessions(id) ON DELETE CASCADE,
    desc TEXT
);
```

## Registration Process

### Role-Based Registration Logic

When a user registers, the system:

1. **Creates Auth User**: Uses Supabase Auth for authentication
2. **Inserts Base Data**: Adds record to `users` table
3. **Inserts Role Data**: Based on selected role:
   - **Student**: Inserts into `students` table
   - **Parent**: Inserts into `parents` table  
   - **Teacher**: Inserts into `teachers` table

### Example Registration Flow

```dart
// For Student Registration
await supabaseService.registerUser(
  email: 'student@example.com',
  password: 'password123',
  name: 'أحمد محمد',
  phone: '501234567',
  countryCode: '+966',
  birthDate: DateTime(2005, 1, 1),
  gender: 'male',
  role: UserRole.student,
  parentId: 'parent-uuid-here', // Optional
);
```

This will:
1. Create auth user
2. Insert into `users` table
3. Insert into `students` table with parent reference

## Data Relationships

### Primary Relationships
- **Users → Students**: One-to-one inheritance
- **Users → Parents**: One-to-one inheritance  
- **Users → Teachers**: One-to-one inheritance
- **Parents ↔ Students**: Bidirectional reference
- **Teachers → Courses**: One-to-many
- **Courses → Sessions**: One-to-many
- **Sessions → Attendance**: One-to-many
- **Sessions → Assignments**: One-to-many

### Query Examples

#### Get Student with Parent Info
```sql
SELECT s.*, u.*, p.*, pu.*
FROM students s
JOIN users u ON s.id = u.id
LEFT JOIN parents p ON s.parent_id = p.id
LEFT JOIN users pu ON p.id = pu.id
WHERE s.id = 'student-uuid';
```

#### Get Teacher's Courses and Sessions
```sql
SELECT c.*, s.*
FROM teachers t
JOIN courses c ON t.id = c.teacher_id
LEFT JOIN sessions s ON c.id = s.course_id
WHERE t.id = 'teacher-uuid';
```

## Security Policies

### Row Level Security (RLS)
All tables have RLS enabled with appropriate policies:

- **Users**: Can view/edit own data
- **Students**: Can view own data, parents can view children, teachers can view students
- **Parents**: Can view own data and linked student data
- **Teachers**: Can view own data and manage courses/sessions
- **Courses/Sessions/Assignments**: Teachers can manage, students can view
- **Attendance**: Teachers can manage, students can view own records

## API Services

### SupabaseService
Handles authentication and user registration with inheritance logic.

### DatabaseService  
Provides CRUD operations for:
- Course management
- Session management
- Assignment management
- Attendance tracking
- User relationship management

## Benefits of New Schema

1. **Normalized Design**: Eliminates data redundancy
2. **Inheritance Model**: Clear role separation
3. **Scalability**: Easy to extend with new user types
4. **Performance**: Proper indexing and relationships
5. **Security**: Comprehensive RLS policies
6. **Maintainability**: Clean, logical structure

## Migration Notes

To migrate from the old schema:
1. Export existing data
2. Run the new schema SQL
3. Transform and import data according to new structure
4. Update application code to use new service methods
5. Test all functionality thoroughly

## File Locations

- **Schema**: `new_supabase_schema.sql`
- **Auth Service**: `lib/services/supabase_service.dart`
- **Database Service**: `lib/services/database_service.dart`
- **Registration**: `lib/screens/register_screen.dart`