# Eat Sheet

A Flutter application for managing and sharing meal planning and grocery lists.

## Project Structure

```
lib/
├── screens/
│   └── splash_screen.dart    # Initial splash screen
assets/
├── fonts/                     # Custom font files
└── images/                    # App images and icons
android/                       # Android-specific configuration
ios/                           # iOS-specific configuration
web/                           # Web platform files
windows/                       # Windows platform files
linux/                         # Linux platform files
macos/                         # macOS platform files
test/                          # Unit and widget tests
```

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart 3.0+
- Android Studio or Xcode (for mobile development)

### Installation

1. Clone the repository:
```bash
git clone Alfredmwange/eat_sheet
cd eat_sheet
```

2. Install dependencies:
```bash
flutter pub get
```

3. **Configure API Keys:**
   - Copy `lib/config/app_config.dart.example` to `lib/config/app_config.dart`:
   ```bash
   cp lib/config/app_config.dart.example lib/config/app_config.dart
   ```
   - Open `lib/config/app_config.dart` and fill in your API keys:
     - **RapidAPI Key**: Get from [Edamam Food & Grocery Database](https://rapidapi.com/edamam/api/edamam-food-and-grocery-database)
     - **Spoonacular API Key**: Get from [Spoonacular API](https://spoonacular.com/food-api)
   - **⚠️ Important**: Do not commit `app_config.dart` to version control. It's added to `.gitignore` to protect your API keys.

4. Run the app:
```bash
flutter run
```

## Features

- Meal planning interface



## Development

### Running Tests

```bash
flutter test
```

### Building for Production

**Android:**
```bash
flutter build apk
```

**iOS:**
```bash
flutter build ios
```

**Web:**
```bash
flutter build web
```

## Database

This project uses [Firestore](https://firebase.google.com/docs/firestore) for data storage and synchronization.

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

[Your License Here]