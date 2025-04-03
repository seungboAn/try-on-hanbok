# Supabase Services Package

A Flutter package containing extracted Supabase logic from the Hanbok Virtual Fitting application for reuse in other projects.

## Getting Started

This package provides services to interact with Supabase, including authentication, storage, and edge functions for image processing.

### Installation

#### Option 1: One-line installer (Easiest)

```bash
# Run this in your terminal (replace with your project path)
curl -s https://raw.githubusercontent.com/seungboAn/hanbok_supabaseServices/master/install.sh | bash -s -- /path/to/my_flutter_app
```

#### Option 2: Using setup script (recommended)

The easiest way to install this package is by using the provided setup script:

```bash
# Clone the repository
git clone https://github.com/seungboAn/hanbok_supabaseServices.git

# Run the setup script (where my_flutter_app is your project directory)
cd hanbok_supabaseServices
./setup_script.sh /path/to/my_flutter_app
```

#### Option 3: Manual installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  supabase_services:
    git:
      url: https://github.com/seungboAn/hanbok_supabaseServices.git
```

Or for local development:

```yaml
dependencies:
  supabase_services:
    path: ../path_to_supabase_services  # Adjust path as needed
```

### Configuration

1. Create a `.env` file in your app root with your Supabase credentials:

```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

2. Initialize the package in your app's `main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:supabase_services/supabase_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase services
  await SupabaseServices.initialize();
  
  runApp(MyApp());
}
```

## Features

- Authentication (anonymous and email)
- File upload to Supabase storage
- Edge function integration
- Image processing with Supabase edge functions

## Services

- `SupabaseService`: Core service for interacting with Supabase
- `EnvService`: Service for loading environment variables
- `InferenceService`: Service for image processing with edge functions

## Documentation

- See [SETUP_GUIDE.md](SETUP_GUIDE.md) for detailed setup instructions
- See [INTEGRATION.md](INTEGRATION.md) for integration guidelines
- See `example_usage.dart` for a complete usage example

## Usage Example

```dart
// Get the Supabase service instance
final supabaseService = SupabaseServices.supabaseService;

// Upload an image
final result = await supabaseService.uploadUserImage(
  imageBytes,
  'image/jpeg',
  authToken
);

// Get presets from Supabase
final presets = await supabaseService.getPresetImages();

// Sign in anonymously
final token = await supabaseService.signInAnonymously();
``` 