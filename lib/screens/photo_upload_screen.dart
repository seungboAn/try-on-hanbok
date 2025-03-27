import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../state/app_state.dart';
import 'result_screen.dart';

class PhotoUploadScreen extends StatefulWidget {
  static const String routeName = '/photo-upload';

  const PhotoUploadScreen({Key? key}) : super(key: key);

  @override
  State<PhotoUploadScreen> createState() => _PhotoUploadScreenState();
}

class _PhotoUploadScreenState extends State<PhotoUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Reset error state when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      if (appState.errorMessage != null) {
        appState.setError('');
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      // Update state after image picking
      setState(() {
        _isLoading = false;
      });

      if (pickedFile != null) {
        final appState = Provider.of<AppState>(context, listen: false);
        
        if (kIsWeb) {
          // Web implementation - Read as bytes
          final bytes = await pickedFile.readAsBytes();
          appState.setUserImage(bytes);
        } else {
          // Mobile implementation - Use File
          appState.setUserImage(File(pickedFile.path));
        }
        
        // Navigate to result screen if processed automatically
        _processImage();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to pick image: ${e.toString()}';
      });
    }
  }

  Future<void> _processImage() async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    if (!appState.hasSelectedHanbok || !appState.hasUserImage) {
      setState(() {
        _errorMessage = 'Please select a hanbok and upload your photo.';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Generate the hanbok image via API
      final success = await appState.generateHanbokImage();
      
      if (success && mounted) {
        // Navigate to result screen
        Navigator.pushReplacementNamed(context, ResultScreen.routeName);
      } else if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = appState.errorMessage ?? 'Failed to process image.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An error occurred: ${e.toString()}';
        });
      }
    }
  }

  Widget _buildImagePreview() {
    final appState = Provider.of<AppState>(context);
    
    if (appState.hasUserImage) {
      // Show the selected image
      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: AppConstants.lightGrey,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: appState.isUserImageFile
              ? Image.file(appState.userImage as File, fit: BoxFit.contain)
              : Image.memory(appState.userImage as Uint8List, fit: BoxFit.contain),
        ),
      );
    } else {
      // Show placeholder
      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: AppConstants.lightGrey,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person,
                size: 64,
                color: AppConstants.primaryColor.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'Your photo will appear here',
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildHanbokPreview() {
    final appState = Provider.of<AppState>(context);
    
    if (appState.hasSelectedHanbok) {
      // Show the selected hanbok
      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: AppConstants.lightGrey,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            appState.selectedHanbok!.imagePath,
            fit: BoxFit.contain,
          ),
        ),
      );
    } else {
      // Show placeholder
      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: AppConstants.lightGrey,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.checkroom,
                size: 64,
                color: AppConstants.primaryColor.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'Please select a hanbok first',
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Your Photo'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                    'Processing your image with AI...\nThis may take a moment',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Selected Hanbok Style',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildHanbokPreview(),
                  const SizedBox(height: 24),
                  Text(
                    'Your Photo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildImagePreview(),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Take Photo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Choose Photo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.secondaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: appState.hasUserImage ? _processImage : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      disabledBackgroundColor: AppConstants.lightGrey,
                    ),
                    child: const Text(
                      'Try On Hanbok',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}