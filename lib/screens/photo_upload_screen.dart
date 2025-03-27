import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../state/app_state.dart';
import '../constants/app_constants.dart';

class PhotoUploadScreen extends StatefulWidget {
  const PhotoUploadScreen({Key? key}) : super(key: key);

  @override
  State<PhotoUploadScreen> createState() => _PhotoUploadScreenState();
}

class _PhotoUploadScreenState extends State<PhotoUploadScreen> {
  bool _isUploading = false;
  
  Future<void> _pickImage(ImageSource source) async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    try {
      setState(() {
        _isUploading = true;
      });
      
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        // For web, we need to use Uint8List instead of File
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          appState.setUserImage(bytes);
        } else {
          // For mobile, use File
          appState.setUserImage(File(pickedFile.path));
        }
        
        // Simulate processing delay
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Navigate to result screen
        if (!mounted) return;
        Navigator.pushNamed(context, '/result');
      }
    } catch (e) {
      print('Error picking image: $e');
      // Show error dialog
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to upload image: ${e.toString()}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Your Photo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Instructions text
              const Text(
                'Upload a photo of yourself to try on the selected hanbok',
                style: AppConstants.bodyStyle,
              ),
              const SizedBox(height: AppConstants.defaultPadding * 2),
              
              // Selected hanbok preview
              if (appState.selectedHanbok != null)
                Center(
                  child: Column(
                    children: [
                      const Text(
                        'Your selected hanbok:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: AppConstants.defaultPadding),
                      Container(
                        width: 200,
                        height: 280,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppConstants.borderColor,
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppConstants.borderRadius - 1),
                          child: Image.asset(
                            appState.selectedHanbok!.imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const Spacer(),
              
              // Upload options
              _isUploading
                  ? const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: AppConstants.defaultPadding),
                          Text('Processing image...'),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Camera button
                        if (!kIsWeb) // Camera not available in web
                          ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Take a Photo'),
                          ),
                          
                        const SizedBox(height: AppConstants.defaultPadding),
                        
                        // Gallery button
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Choose from Gallery'),
                        ),
                        
                        const SizedBox(height: AppConstants.defaultPadding * 2),
                        
                        // Use demo image for testing
                        TextButton.icon(
                          onPressed: () async {
                            setState(() {
                              _isUploading = true;
                            });
                            
                            // Simulate processing delay
                            await Future.delayed(const Duration(seconds: 1));
                            
                            // Use a mock result image path for demo
                            final appState = Provider.of<AppState>(context, listen: false);
                            appState.setResultImage('assets/images/mock_result.png');
                            
                            setState(() {
                              _isUploading = false;
                            });
                            
                            // Navigate to result screen
                            if (!mounted) return;
                            Navigator.pushNamed(context, '/result');
                          },
                          icon: const Icon(Icons.face),
                          label: const Text('Use Demo Image (for testing)'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}