# Course Background Images Implementation

## Overview
I've implemented a feature to display random background images for courses. Each course will automatically get assigned one of 7 random background images when created.

## Changes Made

### 1. **Course Model** (`lib/models/course.dart`)
- Added `back` field to store the background image name (e.g., 'back1', 'back2', etc.)
- Updated `toJson()`, `fromJson()`, and `copyWith()` methods to include the `back` field

### 2. **Database Service** (`lib/services/database_service.dart`)
- Imported `dart:math` for random number generation
- Added `_random` instance variable for generating random numbers
- Modified `createCourse()` to automatically assign a random background image (`back1` through `back7`) when creating a new course

### 3. **Home Screen** (`lib/screens/home_screen.dart`)
- Updated course card display to show background images
- Added `back` field when converting database course data to Course model
- Wrapped Card content in a Container with background image decoration
- Applied dark overlay (40% opacity) for better text readability
- Changed text colors to white when background image is present
- Made avatar background white with opacity for better visibility

### 4. **Assets Configuration** (`pubspec.yaml`)
- Assets folder is already configured to include all files from `assets/`
- This will include the `assets/courses_back/` folder

## What You Need To Do

### 1. Create the Assets Folder Structure
Create the following folder structure in your project:
```
my_app/
  assets/
    courses_back/
      back1.jpg
      back2.jpg
      back3.jpg
      back4.jpg
      back5.jpg
      back6.jpg
      back7.jpg
```

### 2. Add 7 Background Images
- Add 7 different background images to the `assets/courses_back/` folder
- Name them exactly as: `back1.jpg`, `back2.jpg`, `back3.jpg`, `back4.jpg`, `back5.jpg`, `back6.jpg`, `back7.jpg`
- Recommended image dimensions: 1920x1080 or similar aspect ratio
- These could be educational-themed images, abstract patterns, or any images you prefer

### 3. Update Database Schema (Supabase)
You need to add the `back` column to your Course table in Supabase:

```sql
ALTER TABLE "Course" 
ADD COLUMN "back" TEXT;
```

Or through the Supabase dashboard:
1. Go to your Supabase project
2. Navigate to Table Editor
3. Select the `Course` table
4. Add a new column:
   - Name: `back`
   - Type: `text`
   - Default value: (leave empty or set to 'back1')
   - Allow nullable: Yes

### 4. Run the App
After completing the above steps:
1. Run `flutter pub get` to ensure assets are registered
2. Hot restart the app (not just hot reload)
3. Create a new course to see it automatically get a random background image
4. Existing courses without a `back` value will display without background (default style)

## Features
- ✅ Random background assignment (1 of 7 images) when creating courses
- ✅ Background image displayed on course cards
- ✅ Dark overlay for text readability
- ✅ White text when background is present
- ✅ Fallback to default style if no background is set
- ✅ Improved visual appeal with avatar contrast

## Notes
- The background images are stored in the database as just the name (e.g., 'back1')
- The full path is constructed in the UI: `assets/courses_back/back1.jpg`
- Existing courses will need to be updated in the database if you want them to have backgrounds
- You can manually update existing courses in Supabase to assign specific backgrounds
