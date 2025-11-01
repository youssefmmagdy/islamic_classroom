-- Add FCM token column to User table
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- Create Notification table
CREATE TABLE IF NOT EXISTS "Notification" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES "User"(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type TEXT NOT NULL, -- 'post', 'assignment', 'session', 'announcement'
    reference_id UUID, -- ID of the post/assignment/session
    course_id UUID REFERENCES "Course"(id) ON DELETE CASCADE,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    read_at TIMESTAMP WITH TIME ZONE
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_notification_user_id ON "Notification"(user_id);
CREATE INDEX IF NOT EXISTS idx_notification_created_at ON "Notification"(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notification_is_read ON "Notification"(is_read);

-- Create function to update read_at timestamp
CREATE OR REPLACE FUNCTION update_notification_read_at()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_read = TRUE AND OLD.is_read = FALSE THEN
        NEW.read_at = NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for read_at
DROP TRIGGER IF EXISTS notification_read_at_trigger ON "Notification";
CREATE TRIGGER notification_read_at_trigger
    BEFORE UPDATE ON "Notification"
    FOR EACH ROW
    EXECUTE FUNCTION update_notification_read_at();

-- Grant permissions
GRANT ALL ON "Notification" TO authenticated;
GRANT ALL ON "Notification" TO anon;
