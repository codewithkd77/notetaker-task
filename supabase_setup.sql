
-- 1. CREATE NOTES TABLE


CREATE TABLE IF NOT EXISTS notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  content TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

COMMENT ON TABLE notes IS 'User notes with secure access control';
COMMENT ON COLUMN notes.id IS 'Unique identifier for each note';
COMMENT ON COLUMN notes.user_id IS 'Reference to the user who owns this note';
COMMENT ON COLUMN notes.title IS 'Note title (required)';
COMMENT ON COLUMN notes.content IS 'Note content/body (optional)';
COMMENT ON COLUMN notes.created_at IS 'Timestamp when note was created';
COMMENT ON COLUMN notes.updated_at IS 'Timestamp when note was last updated';


-- 2. CREATE INDEXES FOR PERFORMANCE


-- Index for user queries (most common operation)
CREATE INDEX IF NOT EXISTS notes_user_id_idx ON notes(user_id);

-- Index for sorting by creation date (descending)
CREATE INDEX IF NOT EXISTS notes_created_at_idx ON notes(created_at DESC);

-- Composite index for user-specific date sorting
CREATE INDEX IF NOT EXISTS notes_user_created_idx ON notes(user_id, created_at DESC);

-- 3. ENABLE ROW LEVEL SECURITY


ALTER TABLE notes ENABLE ROW LEVEL SECURITY;

-- 4. CREATE SECURITY POLICIES


-- Policy: Users can SELECT (view) only their own notes
CREATE POLICY "Users can view own notes" 
  ON notes 
  FOR SELECT 
  USING (auth.uid() = user_id);

-- Policy: Users can INSERT (create) only their own notes
CREATE POLICY "Users can insert own notes" 
  ON notes 
  FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can UPDATE (edit) only their own notes
CREATE POLICY "Users can update own notes" 
  ON notes 
  FOR UPDATE 
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can DELETE only their own notes
CREATE POLICY "Users can delete own notes" 
  ON notes 
  FOR DELETE 
  USING (auth.uid() = user_id);

