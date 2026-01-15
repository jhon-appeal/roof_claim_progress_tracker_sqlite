# Roof Claim Progress Tracker

A Flutter mobile application for tracking roof claim progress through the entire lifecycle from hail event to project closure. This app uses SQLite for local data storage and provides a simple, intuitive interface for managing claims.

## Features

- **Claim Management**: Create, view, edit, and delete roof claims
- **Progress Tracking**: Visual timeline showing the progress through 10 stages:
  1. Hail Event
  2. Customer Outreach
  3. Inspection & Evidence
  4. Claim Enablement
  5. Claim Management
  6. Claim Approval
  7. Roof Construction
  8. Progress Validation
  9. Payment Flow
  10. Project Closure
- **Local Storage**: All data is stored locally using SQLite
- **Status Updates**: Easy status progression with one-tap updates
- **Detailed View**: Comprehensive claim information display

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── config/
│   └── supabase_config.dart     # Supabase configuration
├── models/
│   ├── claim.dart              # Claim data model (SQLite)
│   └── supabase_models.dart    # Supabase models (Project, Profile, etc.)
├── database/
│   └── database_helper.dart    # SQLite database operations
├── repository/
│   ├── claim_repository.dart   # SQLite repository
│   ├── supabase_project_repository.dart
│   ├── supabase_profile_repository.dart
│   ├── supabase_milestone_repository.dart
│   ├── supabase_photo_repository.dart
│   └── supabase_status_history_repository.dart
├── viewmodels/
│   ├── claims_list_viewmodel.dart
│   ├── add_edit_claim_viewmodel.dart
│   └── claim_detail_viewmodel.dart
└── screens/
    ├── claims_list_screen.dart
    ├── add_edit_claim_screen.dart
    └── claim_detail_screen.dart
```

## Getting Started

### Prerequisites

- Flutter SDK (3.10.4 or higher)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- Supabase account (optional - for cloud sync)

### Installation

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. **Supabase Setup (Optional)**:
   - Create a `.env` file in the project root
   - Add your Supabase credentials:
     ```
     SUPABASE_URL=your_supabase_project_url
     SUPABASE_ANON_KEY=your_supabase_anon_key
     ```
   - The app will work with SQLite only if Supabase is not configured
   - See Supabase section below for schema setup

3. Run the app:
   ```bash
   flutter run
   ```

## Dependencies

- `sqflite`: ^2.3.0 - SQLite database for Flutter
- `path`: ^1.8.3 - Path manipulation utilities
- `intl`: ^0.19.0 - Internationalization and date formatting
- `provider`: ^6.1.1 - State management
- `supabase_flutter`: ^2.5.6 - Supabase client (optional)
- `uuid`: ^4.3.3 - UUID generation
- `flutter_dotenv`: ^5.1.0 - Environment variable management

## Usage

1. **Add a New Claim**: Tap the + button on the main screen
2. **View Claim Details**: Tap on any claim in the list
3. **Update Progress**: In the detail screen, use "Move to Next" button to advance status
4. **Edit Claim**: Tap the edit icon in the detail screen or use the menu in the list
5. **Delete Claim**: Use the menu (three dots) in the list view

## Database Schema

The app uses a single `claims` table with the following fields:
- `id` (INTEGER PRIMARY KEY)
- `homeownerName` (TEXT)
- `address` (TEXT)
- `phoneNumber` (TEXT)
- `insuranceCompany` (TEXT)
- `claimNumber` (TEXT)
- `status` (TEXT)
- `notes` (TEXT)
- `createdAt` (TEXT - ISO8601 format)
- `updatedAt` (TEXT - ISO8601 format)

## Business Flow Alignment

This app closely follows the business flow:
- Tracks claims from initial hail event through project closure
- Maintains all relevant customer and insurance information
- Provides clear visual progress indicators
- Supports notes for additional documentation

## Supabase Integration

The app includes Supabase integration for cloud storage and multi-user support. The Supabase schema includes:

### Tables

1. **profiles** - User profiles with roles (homeowner, roofingCompany, assessDirect, admin)
2. **projects** - Main project/claim records
3. **milestones** - Project milestones with status tracking
4. **progress_photos** - Photo attachments for milestones
5. **status_history** - Audit trail of status changes

### Setup

1. Create a Supabase project at https://supabase.com
2. Run the SQL schema in your Supabase SQL editor
3. Create a `.env` file with your credentials:
   ```
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   ```
4. The app will automatically initialize Supabase on startup

### Architecture

The app uses **MVVM (Model-View-ViewModel)** architecture:
- **Models**: Data structures
- **ViewModels**: Business logic and state management
- **Views**: UI screens
- **Repository**: Data access layer (abstracts SQLite/Supabase)

### Dual Storage Support

- **SQLite**: Local storage for offline-first functionality
- **Supabase**: Cloud storage for multi-device sync and collaboration
- Both can work together or independently

## Future Enhancements (Optional)

- Photo/document attachments (Supabase storage integration)
- Real-time sync between devices
- Multi-user collaboration
- Export functionality
- Search and filter capabilities
- Statistics dashboard
- Push notifications for status changes
