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
├── models/
│   └── claim.dart              # Claim data model and status definitions
├── database/
│   └── database_helper.dart    # SQLite database operations
└── screens/
    ├── claims_list_screen.dart      # Main screen with claims list
    ├── add_edit_claim_screen.dart   # Add/Edit claim form
    └── claim_detail_screen.dart     # Claim details with progress timeline
```

## Getting Started

### Prerequisites

- Flutter SDK (3.10.4 or higher)
- Dart SDK
- Android Studio / Xcode (for mobile development)

### Installation

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Run the app:
   ```bash
   flutter run
   ```

## Dependencies

- `sqflite`: ^2.3.0 - SQLite database for Flutter
- `path`: ^1.8.3 - Path manipulation utilities
- `intl`: ^0.19.0 - Internationalization and date formatting

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

## Future Enhancements (Optional)

- Photo/document attachments
- Export functionality
- Search and filter capabilities
- Statistics dashboard
- Cloud sync
- Notifications for status changes
