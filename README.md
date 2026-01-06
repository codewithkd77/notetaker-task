# NoteTaker - Flutter Notes Application

A secure Flutter mobile application for managing personal notes with Supabase backend integration. This app demonstrates authentication, CRUD operations, and Row Level Security implementation.

## Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Setup Instructions](#setup-instructions)
- [Database Schema](#database-schema)
- [Security Implementation](#security-implementation)
- [Architecture](#architecture)
- [Running the App](#running-the-app)
- [Building APK](#building-apk)
- [Trade-offs and Assumptions](#trade-offs-and-assumptions)

## Features

### Authentication
- Email and password sign up
- User login
- Secure logout
- Persistent user sessions
- Auto-redirect based on authentication state

### Notes Management
- Create new notes
- Edit existing notes
- Delete notes with confirmation
- View all personal notes
- Real-time updates
- Pull-to-refresh

### Search
- Client-side search by note title
- Instant filter results
- Clear search functionality

### Security
- Row Level Security (RLS) on database
- Users can only access their own notes
- Secure authentication with Supabase Auth

## Tech Stack

- **Frontend**: Flutter SDK 3.9.2+
- **Backend**: Supabase (BaaS)
  - Authentication: Supabase Auth
  - Database: PostgreSQL with RLS
- **State Management**: Provider
- **Dependencies**:
  - `supabase_flutter: ^2.5.10` - Supabase client
  - `provider: ^6.1.2` - State management
  - `intl: ^0.19.0` - Date formatting

## Prerequisites

Before you begin, ensure you have the following installed:

1. Flutter SDK (3.9.2 or higher)
   ```bash
   flutter --version
   ```

2. Android Studio or VS Code with Flutter extensions

3. Android SDK (for building APK)

4. Supabase Account (free tier available at https://supabase.com)

## Setup Instructions

### 1. Clone or Setup Project

```bash
# Navigate to project directory
cd notetaker

# Install dependencies
flutter pub get
```

### 2. Supabase Setup

#### A. Create a Supabase Project

1. Go to [https://app.supabase.com](https://app.supabase.com)
2. Click "New Project"
3. Fill in project details and create

#### B. Get Your Credentials

1. In your Supabase project dashboard, go to Settings > API
2. Copy the following:
   - Project URL (format: `https://xxxxx.supabase.co`)
   - Anon/Public Key (starts with `eyJ...`)

#### C. Configure the App

1. Open `lib/utils/constants.dart`
2. Replace the placeholder values:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://your-project-id.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key-here';
}
```

### 3. Database Setup

#### A. Create the Notes Table

In your Supabase project, go to SQL Editor and run:

```sql
-- Create notes table
CREATE TABLE notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  content TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Create index for faster queries
CREATE INDEX notes_user_id_idx ON notes(user_id);
CREATE INDEX notes_created_at_idx ON notes(created_at DESC);
```

#### B. Enable Row Level Security (RLS)

```sql
-- Enable RLS on notes table
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view only their own notes
CREATE POLICY "Users can view own notes" 
  ON notes FOR SELECT 
  USING (auth.uid() = user_id);

-- Policy: Users can insert their own notes
CREATE POLICY "Users can insert own notes" 
  ON notes FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update only their own notes
CREATE POLICY "Users can update own notes" 
  ON notes FOR UPDATE 
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete only their own notes
CREATE POLICY "Users can delete own notes" 
  ON notes FOR DELETE 
  USING (auth.uid() = user_id);
```

#### C. Verify RLS Policies

In Supabase dashboard:
1. Go to Authentication > Policies
2. Select the `notes` table
3. You should see 4 policies (SELECT, INSERT, UPDATE, DELETE)

## Database Schema

### Table: `notes`

| Column      | Type                        | Constraints           | Description                    |
|-------------|-----------------------------|-----------------------|--------------------------------|
| id          | UUID                        | PRIMARY KEY, DEFAULT  | Auto-generated unique ID       |
| user_id     | UUID                        | NOT NULL, FOREIGN KEY | References auth.users(id)      |
| title       | TEXT                        | NOT NULL              | Note title                     |
| content     | TEXT                        | NULL                  | Note content/body              |
| created_at  | TIMESTAMP WITH TIME ZONE    | NOT NULL, DEFAULT NOW | Creation timestamp             |
| updated_at  | TIMESTAMP WITH TIME ZONE    | NOT NULL, DEFAULT NOW | Last update timestamp          |

### Relationships

- `user_id` → `auth.users(id)` (CASCADE DELETE)
  - When a user is deleted, all their notes are automatically deleted

## Security Implementation

### Row Level Security (RLS)

RLS is enabled on the `notes` table with the following policies:

1. **SELECT Policy**: Users can only read their own notes
   - `WHERE auth.uid() = user_id`

2. **INSERT Policy**: Users can only create notes for themselves
   - `WITH CHECK auth.uid() = user_id`

3. **UPDATE Policy**: Users can only modify their own notes
   - `USING auth.uid() = user_id`

4. **DELETE Policy**: Users can only delete their own notes
   - `USING auth.uid() = user_id`

### Authentication

- Passwords are hashed by Supabase (never stored in plaintext)
- Session tokens are stored securely by Supabase Flutter SDK
- Automatic session refresh handled by Supabase
- No credentials hardcoded in the app

## Architecture

### Folder Structure

```
lib/
├── main.dart                    # App entry point & initialization
├── models/
│   └── note.dart                # Note data model
├── providers/
│   ├── auth_provider.dart       # Authentication state management
│   └── notes_provider.dart      # Notes CRUD operations & search
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart    # Login UI
│   │   └── signup_screen.dart   # Sign up UI
│   └── notes/
│       ├── notes_list_screen.dart  # Main notes list with search
│       └── note_form_screen.dart   # Add/Edit note form
├── services/
│   └── supabase_service.dart    # Supabase client initialization
└── utils/
    └── constants.dart           # Configuration constants
```

### State Management (Provider)

**AuthProvider**
- Manages user authentication state
- Handles sign up, sign in, sign out
- Listens to auth state changes
- Persists session automatically

**NotesProvider**
- Manages notes list
- Handles CRUD operations
- Implements client-side search
- Error handling

### Authentication Flow

```
App Start
    ↓
Initialize Supabase
    ↓
Check Session
    ↓
├─→ Authenticated → Notes List Screen
└─→ Not Authenticated → Login Screen
```

### Data Flow

```
User Action (UI)
    ↓
Provider Method
    ↓
Supabase Service
    ↓
Supabase Backend (with RLS)
    ↓
Response
    ↓
Update Provider State
    ↓
UI Updates (via notifyListeners)
```

## Running the App

### Development Mode

```bash
# Check for connected devices
flutter devices

# Run on connected device/emulator
flutter run

# Run with hot reload enabled (default)
flutter run --debug

# Run in release mode (better performance)
flutter run --release
```

### Common Issues & Solutions

**Issue**: Supabase connection error
- **Solution**: Check your credentials in `lib/utils/constants.dart`

**Issue**: Build errors after adding dependencies
```bash
flutter clean
flutter pub get
flutter run
```

**Issue**: RLS policy errors
- **Solution**: Verify RLS policies are created correctly in Supabase dashboard

## Building APK

### Build Debug APK (for testing)

```bash
flutter build apk --debug
```

Output: `build/app/outputs/flutter-apk/app-debug.apk`

### Build Release APK (for distribution)

```bash
# Build release APK
flutter build apk --release

# Or build split APKs per ABI (smaller file size)
flutter build apk --split-per-abi --release
```

Output:
- `build/app/outputs/flutter-apk/app-release.apk` (universal)
- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk` (ARM 32-bit)
- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (ARM 64-bit)
- `build/app/outputs/flutter-apk/app-x86_64-release.apk` (x86 64-bit)

### Install APK on Device

```bash
# Using ADB
adb install build/app/outputs/flutter-apk/app-release.apk

# Or transfer APK to device and install manually
```

### Build App Bundle (for Play Store)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

## Trade-offs and Assumptions

### Design Decisions

1. **Provider over Bloc/Riverpod**
   - **Why**: Simpler setup, less boilerplate, sufficient for app complexity
   - **Trade-off**: Less scalable for very large apps, but perfect for this use case

2. **Client-side Search**
   - **Why**: Faster response, works offline, simple implementation
   - **Trade-off**: Limited to loaded notes, no advanced full-text search
   - **Alternative**: Could implement server-side search with Supabase `.textSearch()`

3. **No Offline Support**
   - **Assumption**: Users have internet connection when using the app
   - **Trade-off**: Simpler architecture, no sync conflicts
   - **Future**: Could add local caching with `sqflite` and sync logic

4. **Email/Password Only**
   - **Why**: Simplest authentication method, no OAuth setup required
   - **Trade-off**: No social login (Google, Apple, etc.)
   - **Future**: Can easily add OAuth providers via Supabase

5. **No Rich Text Editor**
   - **Assumption**: Plain text is sufficient for notes
   - **Trade-off**: Simpler UI, faster performance
   - **Future**: Could integrate `flutter_quill` or similar

6. **No Image/File Attachments**
   - **Scope**: Keep app focused on text notes
   - **Trade-off**: Limited functionality
   - **Future**: Could add using Supabase Storage

### Assumptions

- Users have stable internet connection
- Email confirmation is disabled in Supabase (for easier testing)
- Users understand basic note-taking concepts
- App targets Android platform primarily (iOS untested)
- Single device usage (no multi-device sync indicators)

### Security Assumptions

- Supabase RLS is properly configured
- HTTPS is used for all API calls (default in Supabase)
- Anon key is safe to use client-side (true for Supabase)
- Users have unique email addresses

## License

This project is created for educational purposes.

## Support

For issues or questions:
- Supabase documentation: https://supabase.com/docs
- Flutter documentation: https://flutter.dev/docs
- Review RLS policies in Supabase dashboard
