# Integrating Supabase Services Package

This document provides step-by-step instructions for integrating the Supabase Services package into a new Flutter project.

## Prerequisites

- Flutter SDK installed
- An existing Supabase project (the same one used in the original application)
- Basic knowledge of Flutter development

## Step 1: Add the Package to Your Project

Add the package to your `pubspec.yaml` file:

```yaml
dependencies:
  supabase_services:
    path: ../path_to_supabase_services  # Adjust path as needed
```

Then run:

```bash
flutter pub get
```

## Step 2: Create Environment Configuration

1. Create a `.env` file in your project root (don't commit this file to source control):

```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

2. Update your `pubspec.yaml` to include the `.env` file:

```yaml
flutter:
  assets:
    - .env
```

## Step 3: Initialize the Supabase Services

In your `main.dart` file:

```dart
import 'package:flutter/material.dart';
import 'package:supabase_services/supabase_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase services
  await SupabaseServices.initialize();
  
  runApp(const MyApp());
}
```

## Step 4: Use the Supabase Services in Your App

You can now use the various services provided by the package:

### Authentication

```dart
final supabaseService = SupabaseServices.supabaseService;

// Sign in anonymously
final token = await supabaseService.signInAnonymously();

// Sign out
await supabaseService.signOut();
```

### File Upload

```dart
// Upload an image (requires authentication)
final result = await supabaseService.uploadUserImage(
  imageBytes,  // Uint8List
  'image/jpeg', // content type
  authToken     // from authentication
);

// Get the uploaded image URL
final imageUrl = result['image']['image_url'];
```

### Preset Images

```dart
// Get all preset images
final presets = await supabaseService.getPresetImages();

// Get preset images by category
final traditionalPresets = await supabaseService.getPresetImages(category: 'traditional');
```

### Image Generation

```dart
final inferenceService = SupabaseServices.inferenceService;

// Generate an image
final result = await inferenceService.generateHanbokFitting(
  sourcePath: sourceImageUrl, // URL of the user image
  targetPath: presetImageUrl, // URL of the preset image
);

// If result is null, the task is processing and needs polling
if (result == null) {
  // Get the latest task ID
  final taskId = inferenceService.taskIds.last;
  
  // Poll for results
  final status = await inferenceService.checkTaskStatus(taskId);
  
  if (status['status'] == 'completed') {
    final resultUrl = status['image_url'];
    // Use the result URL
  }
}
```

## Step 5: Advanced Usage - Building Your Own State Management

Create a state management class for your specific application needs. For example:

```dart
class MyAppState extends ChangeNotifier {
  final _supabaseService = SupabaseServices.supabaseService;
  final _inferenceService = SupabaseServices.inferenceService;
  
  // Add your application-specific state and logic here
  
  // Initialize and authenticate
  Future<void> initialize() async {
    // Your initialization logic
  }
  
  // Your application-specific methods
}
```

## Edge Functions

The Supabase Services package relies on specific Edge Functions deployed to your Supabase project:

1. `upload-user-image` - For uploading user images
2. `get-presets` - For fetching preset images
3. `generate-hanbok-image` - For generating fitting results
4. `check-status` - For checking task status

Make sure these Edge Functions are properly deployed in your Supabase project.

## Troubleshooting

- **Authentication Issues**: Ensure your Supabase URL and anon key are correct
- **Edge Function Errors**: Check if the Edge Functions are properly deployed
- **Image Upload Failures**: Verify storage bucket permissions in Supabase

## Additional Resources

- See `example_usage.dart` for a complete usage example
- Check the API documentation in each service file for details on all available methods 