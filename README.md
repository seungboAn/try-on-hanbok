# Try On Hanbok App

A Flutter application that allows users to virtually try on traditional and modern hanbok designs using AI-powered image processing.

## Features

- Browse traditional and modern hanbok designs
- Upload photos from camera or gallery
- AI-powered hanbok transformation using Google Kubernetes Engine API
- Save, share, and download generated results
- Cross-platform support (Web, iOS, Android)

## Architecture

The application follows a clean architecture pattern with the following components:

### Core Components

- **Models**: Data structures like `HanbokImage`
- **Services**: Business logic and API interactions
- **State Management**: Using Provider pattern
- **UI Components**: Screens and reusable widgets

### Key Services

#### API Service
Handles communication with the GKE API for hanbok image generation:
- Converts images to the correct format for API consumption
- Manages authentication and error handling
- Handles timeout and retry logic

#### Storage Service
Manages local storage of images and application data:
- Saves generated images to device storage
- Handles temporary files cleanup
- Provides access to saved images

#### Hanbok Service
Core business logic for managing hanbok images:
- Loads and caches hanbok templates
- Interacts with the API service for image generation
- Manages saved results

## GKE API Integration

The app integrates with a Google Kubernetes Engine API for generating hanbok transformations. The API process works as follows:

1. User selects a hanbok design
2. User uploads a photo
3. The app sends both images to the GKE API
4. The API processes the images and returns a transformed result
5. The app displays and stores the result

### API Configuration

The API configuration is stored in `lib/config/api_config.dart` with the following settings:
- Base URL for the API endpoints
- Timeout values
- Maximum image sizes
- API keys and authentication

### Fallback Mechanism

If the API is unavailable or returns an error, the app falls back to using mock data to ensure a smooth user experience:
- Displays a mock result image
- Shows appropriate error messages
- Allows retry functionality

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio or VS Code with Flutter plugins

### Installation

1. Clone the repository
```bash
git clone https://github.com/seungboAn/try-on-hanbok.git
```

2. Install dependencies
```bash
flutter pub get
```

3. Run the app
```bash
flutter run
```

## Project Structure

```
lib/
├── config/              # Configuration files
│   └── api_config.dart  # API endpoint and settings
├── constants/           # App constants
│   └── app_constants.dart
├── models/              # Data models
│   └── hanbok_image.dart
├── screens/             # UI screens
│   ├── index_screen.dart
│   ├── hanbok_selection_screen.dart
│   ├── photo_upload_screen.dart
│   └── result_screen.dart
├── services/            # Business logic
│   ├── api_service.dart
│   ├── hanbok_service.dart
│   └── storage_service.dart
├── state/               # State management
│   └── app_state.dart
├── widgets/             # Reusable UI components
│   ├── category_filter.dart
│   └── hanbok_grid.dart
└── main.dart            # Application entry point
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter team for the amazing framework
- Korean traditional culture for inspiration