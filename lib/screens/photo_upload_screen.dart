import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../constants/app_constants.dart';
import '../services/app_state.dart';
import '../models/hanbok_image.dart';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:cached_network_image/cached_network_image.dart';

class PhotoUploadScreen extends StatefulWidget {
  const PhotoUploadScreen({Key? key}) : super(key: key);

  @override
  State<PhotoUploadScreen> createState() => _PhotoUploadScreenState();
}

class _PhotoUploadScreenState extends State<PhotoUploadScreen> {
  late AppState _appState;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Get the AppState once and listen for changes
    if (!_isInitialized) {
      _appState = provider.Provider.of<AppState>(context);
      _isInitialized = true;
      
      developer.log('PhotoUploadScreen initialized', name: 'PhotoUploadScreen');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = provider.Provider.of<AppState>(context);
    final selectedHanbok = appState.selectedHanbokPreset;
    final hanbokImages = appState.getHanboksByCurrentCategory();
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppConstants.primaryColor.withOpacity(0.2),
              radius: 18,
              child: Icon(
                Icons.accessibility_new,
                color: AppConstants.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Try On\nHanbok',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                height: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: Colors.grey[200],
              radius: 16,
              child: const Text('EN', style: TextStyle(fontSize: 12, color: Colors.black87)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selected hanbok and upload area
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Upload area
                        Expanded(
                          flex: 1,
                          child: Container(
                            height: 300,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: appState.isLoading
                                ? const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(),
                                        SizedBox(height: 16),
                                        Text('Processing image...'),
                                      ],
                                    ),
                                  )
                                : _buildImagePreview(context, appState),
                          ),
                        ),
                        const SizedBox(width: AppConstants.defaultPadding),
                        // Selected hanbok preview
                        if (selectedHanbok != null)
                          Expanded(
                            flex: 1,
                            child: Container(
                              height: 300,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                                child: CachedNetworkImage(
                                  imageUrl: selectedHanbok.imagePath,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: Icon(Icons.error),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: AppConstants.defaultPadding * 2),
                    
                    // Hanbok selection grid
                    const Text(
                      'Select Hanbok Style',
                      style: AppConstants.subheadingStyle,
                    ),
                    const SizedBox(height: AppConstants.smallPadding),
                    
                    // Category tabs
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final category in appState.categories)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(category),
                                selected: appState.currentCategory == category,
                                onSelected: (selected) {
                                  if (selected) {
                                    appState.setCategory(category);
                                  }
                                },
                                backgroundColor: Colors.grey[100],
                                selectedColor: AppConstants.primaryColor.withOpacity(0.2),
                                labelStyle: TextStyle(
                                  color: appState.currentCategory == category
                                      ? AppConstants.primaryColor
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: AppConstants.defaultPadding),
                    
                    // Hanbok grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: hanbokImages.length,
                      itemBuilder: (context, index) {
                        final hanbok = hanbokImages[index];
                        final isSelected = selectedHanbok?.id == hanbok.id;
                        
                        return GestureDetector(
                          onTap: () => appState.selectHanbokPreset(hanbok),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                              border: Border.all(
                                color: isSelected ? AppConstants.primaryColor : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(AppConstants.borderRadius - 1),
                                  child: CachedNetworkImage(
                                    imageUrl: hanbok.imagePath,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[200],
                                      child: const Center(child: CircularProgressIndicator()),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: Colors.grey[200],
                                      child: const Center(child: Icon(Icons.error)),
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: AppConstants.primaryColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom buttons
            Container(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (appState.sourceImage != null || appState.sourceImageUrl != null) && selectedHanbok != null
                          ? () => appState.generateResultImage()
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Generate Hanbok Image',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: AppConstants.smallPadding),
                  
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        appState.setStep(0);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppConstants.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                        ),
                      ),
                      child: const Text(
                        'Back to Hanbok Selection',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  
                  // Debug button - only for development
                  if (kIsWeb == false) // Hide in web production builds
                    Padding(
                      padding: const EdgeInsets.only(top: AppConstants.smallPadding),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => _debugImageUpload(context, appState),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                            ),
                          ),
                          child: const Text(
                            'Debug Image Upload',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildImagePreview(BuildContext context, AppState appState) {
    if (appState.sourceImage != null || appState.sourceImageUrl != null || appState.sourceXFile != null) {
      // 유효한 이미지 URL 가져오기
      final validImageUrl = appState.getValidImageUrl();

      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            child: kIsWeb
                ? (validImageUrl != null
                    ? Image.network(
                        validImageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        appState.sourceXFile!.path,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ))
                : Image.file(
                    appState.sourceImage!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              onPressed: () => _uploadImage(context, appState),
              icon: const Icon(Icons.refresh),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppConstants.primaryColor,
              ),
            ),
          ),
          // Error message display if needed
          if (appState.errorMessage != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                color: Colors.red.withOpacity(0.7),
                child: Text(
                  appState.errorMessage!,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      );
    }
    
    return InkWell(
      onTap: () => _uploadImage(context, appState),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            'Click to upload your photo',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Recommended: Front-facing portrait',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  // Handle image upload with Edge Function call
  Future<void> _uploadImage(BuildContext context, AppState appState) async {
    try {
      // Show loading dialog before starting upload
      if (!context.mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Uploading image...'),
              ],
            ),
          );
        },
      );
      
      developer.log('Starting image upload process', name: 'PhotoUploadScreen');
      
      // Start the image picker process which handles uploading to Supabase
      await appState.pickSourceImage();
      
      // Check for results
      if (!context.mounted) return;
      
      // Close the loading dialog
      Navigator.of(context).pop();
      
      if (appState.sourceImageUrl != null) {
        developer.log('Image upload successful!', name: 'PhotoUploadScreen');
        developer.log('Image URL: ${appState.sourceImageUrl}', name: 'PhotoUploadScreen');
        
        // 만료 시간 포맷팅
        String expiryInfo = '';
        if (appState.storageExpiry != null) {
          final expiry = appState.storageExpiry!;
          final now = DateTime.now();
          final hours = expiry.difference(now).inHours;
          
          expiryInfo = '(만료: ${hours}시간 후)';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Image uploaded successfully!'),
                Text('URL: ${appState.sourceImageUrl!.substring(0, 50)}... $expiryInfo', 
                  style: const TextStyle(fontSize: 10)),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (appState.errorMessage != null) {
        developer.log('Image upload failed: ${appState.errorMessage}', name: 'PhotoUploadScreen');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${appState.errorMessage}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      developer.log('Error during image upload: $e', name: 'PhotoUploadScreen', error: e);
      
      if (!context.mounted) return;
      
      // Close the loading dialog if it's still showing
      Navigator.of(context, rootNavigator: true).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading image: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  
  // Debug helper to inspect the upload process
  void _debugImageUpload(BuildContext context, AppState appState) {
    final sourceImage = appState.sourceImage;
    final sourceUrl = appState.sourceImageUrl;
    final xFile = appState.sourceXFile;

    developer.log('Debug Image Upload', name: 'PhotoUploadScreen');
    developer.log('Source Image: $sourceImage', name: 'PhotoUploadScreen');
    developer.log('Source URL: $sourceUrl', name: 'PhotoUploadScreen');
    developer.log('Source XFile: $xFile', name: 'PhotoUploadScreen');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Debug Info:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Image: ${sourceImage != null}'),
            Text('URL: ${sourceUrl ?? "Not set"}'),
            Text('XFile: ${xFile != null}'),
          ],
        ),
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.black87,
      ),
    );
  }
} 