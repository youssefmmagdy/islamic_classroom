# Delete Assignment Feature Implementation

## Overview
Implemented the ability for teachers to delete assignments, including all associated submissions.

## Features Implemented

### 1. Database Method ✅
**File**: `lib/services/database_service.dart`

**New Method**: `deleteAssignment(String assignmentId)`

**Functionality**:
- Deletes all submissions associated with the assignment
- Deletes the assignment itself
- Returns success/failure response

```dart
Future<Map<String, dynamic>> deleteAssignment(String assignmentId) async {
  try {
    // Delete all submissions for this assignment
    await client
        .from('Assignment_Submission')
        .delete()
        .eq('assignment_id', assignmentId);

    // Delete the assignment
    await client
        .from('Assignment')
        .delete()
        .eq('id', assignmentId);

    return {
      'success': true,
      'message': 'تم حذف الواجب بنجاح',
    };
  } catch (e) {
    return {
      'success': false,
      'message': 'فشل في حذف الواجب: ${e.toString()}',
    };
  }
}
```

**Database Operations**:
1. First deletes from `Assignment_Submission` table (where `assignment_id` matches)
2. Then deletes from `Assignment` table (where `id` matches)
3. This ensures no orphaned submission records remain

### 2. UI Implementation ✅
**File**: `lib/screens/tabs/assignments_tab_screen.dart`

**Added Components**:

#### A. Delete Button in Assignment Card
- Red trash icon button in assignment header
- Positioned next to assignment title
- Only visible to teachers
- Tooltip: "حذف الواجب"

#### B. Confirmation Dialog
**Method**: `_showDeleteConfirmationDialog()`

**Features**:
- Shows assignment name being deleted
- Warning message about deleting all submissions
- Two action buttons:
  - **Cancel** (إلغاء) - closes dialog
  - **Delete** (حذف) - red button, confirms deletion

**Dialog Text**:
```
هل أنت متأكد من حذف الواجب "[assignment name]"؟

سيتم حذف جميع التسليمات المرتبطة بهذا الواجب.
```

#### C. Delete Process
**Method**: `_deleteAssignment()`

**Flow**:
1. Shows loading SnackBar ("جاري حذف الواجب...")
2. Calls database service to delete assignment
3. Hides loading SnackBar
4. Shows success/error SnackBar
5. Reloads assignment data if successful

**SnackBar Messages**:
- **Loading**: "جاري حذف الواجب..." (with spinner)
- **Success**: "تم حذف الواجب بنجاح" (green)
- **Error**: Error message (red)

## User Flow

### Teacher Deletes Assignment:
1. Navigate to Assignments tab in course
2. Find the assignment to delete
3. Click the red trash icon (🗑️) on the assignment card
4. Confirmation dialog appears with warning
5. Click "حذف" to confirm or "إلغاء" to cancel
6. If confirmed:
   - Loading indicator appears
   - Assignment and all submissions are deleted
   - Success message shows
   - Assignment list refreshes automatically
7. Assignment is removed from the list

## Safety Features

### 1. Confirmation Dialog
- Prevents accidental deletions
- Shows clear warning about consequences
- Requires explicit confirmation

### 2. Loading Feedback
- Shows progress during deletion
- Prevents multiple delete attempts
- User knows operation is in progress

### 3. Error Handling
- Try-catch blocks around delete operations
- User-friendly error messages
- Failed deletions don't break the UI

### 4. Data Integrity
- Deletes submissions first
- Then deletes assignment
- Prevents orphaned data

## Technical Implementation

### State Management
- Uses local state with `setState()`
- Reloads data after successful deletion
- Maintains UI consistency

### Context Safety
- Checks `mounted` before showing SnackBars
- Prevents errors after widget disposal
- Uses `context.mounted` for navigation

### Cascade Behavior
```dart
// Manual cascade delete
await client.from('Assignment_Submission').delete().eq('assignment_id', assignmentId);
await client.from('Assignment').delete().eq('id', assignmentId);
```

**Note**: If your database has CASCADE DELETE foreign key constraints set up, the submissions will be automatically deleted when the assignment is deleted. The manual deletion is kept for safety.

## UI/UX Details

### Delete Button Styling
- **Icon**: `Icons.delete_outline`
- **Color**: `Colors.red.shade400`
- **Position**: Top-right of assignment card header
- **Tooltip**: Shows on hover/long-press

### Confirmation Dialog
- **Title**: "تأكيد الحذف"
- **Content**: Warning with assignment name
- **Line height**: 1.5 for readability
- **Cancel button**: Text button (default style)
- **Delete button**: Filled button (red background)

### SnackBar Feedback
- **Loading**: Circular progress indicator + text
- **Duration**: 2 seconds for loading
- **Auto-hide**: On success/error
- **Colors**: Green for success, red for error

## Testing Checklist

- [ ] Delete button appears only for teachers
- [ ] Click delete shows confirmation dialog
- [ ] Cancel closes dialog without deleting
- [ ] Confirm deletes the assignment
- [ ] All submissions are deleted
- [ ] Success message appears
- [ ] Assignment list refreshes
- [ ] Deleted assignment disappears from list
- [ ] Error handling works for failed deletions
- [ ] Loading indicator shows during deletion
- [ ] Can delete assignments with PDF files
- [ ] Can delete assignments with submissions
- [ ] Can delete assignments without submissions

## Database Impact

### Tables Affected:
1. **Assignment** - Row deleted
2. **Assignment_Submission** - All related rows deleted

### Foreign Key Considerations:
If you have CASCADE DELETE set up in your Supabase database:
```sql
ALTER TABLE "Assignment_Submission"
ADD CONSTRAINT fk_assignment
FOREIGN KEY (assignment_id)
REFERENCES "Assignment"(id)
ON DELETE CASCADE;
```

Then submissions will auto-delete when assignment is deleted. The manual deletion in code provides extra safety.

## Future Enhancements

1. **Soft Delete**: Archive instead of permanent deletion
2. **Undo Option**: Allow restoration within time window
3. **Bulk Delete**: Delete multiple assignments at once
4. **Admin Audit**: Log who deleted what and when
5. **Cloudinary Cleanup**: Also delete associated PDF files from Cloudinary
6. **Permissions**: Add role-based delete permissions
7. **Statistics**: Show impact (X submissions will be deleted)

## Security Considerations

### Current Implementation:
- Only teachers have access to delete button (UI level)
- Database service doesn't verify user role

### Recommended Database Security:
Add Row Level Security (RLS) policy in Supabase:
```sql
-- Only teachers can delete assignments they own
CREATE POLICY "Teachers can delete their assignments"
ON "Assignment"
FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM "Teacher"
    WHERE "Teacher".id = auth.uid()
    AND "Assignment".teacher_id = auth.uid()
  )
);
```

This prevents students from deleting assignments even if they somehow access the delete function.
