import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';
import '../models/hanbok_image.dart';
import '../state/app_state.dart';
import '../services/storage_service.dart';
import 'index_screen.dart';

class ResultScreen extends StatelessWidget {
  static const String routeName = '/result';

  const ResultScreen({Key? key}) : super(key: key);

  Future<void> _downloadImage(BuildContext context, String imagePath) async {
    try {
      if (kIsWeb) {
        // For web, we'll use a different approach since direct file downloads work differently
        // We can launch a URL that points to the image
        final uri = Uri.parse(imagePath.startsWith('http') 
            ? imagePath 
            : 'assets/images/mock_result.png');
        
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to open image for download')),
          );
        }
      } else {
        // For mobile platforms
        final storageService = StorageService();
        final savedPath = await storageService.saveImage(imagePath);
        
        if (savedPath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image saved to: $savedPath')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save image')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _shareImage(BuildContext context, String imagePath) async {
    try {
      if (imagePath.startsWith('assets/')) {
        // For asset images, we need a different approach
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot share demo images. Try with a real result.')),
        );
        return;
      }
      
      if (kIsWeb) {
        // Web sharing is limited compared to mobile
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sharing not fully supported on web. Please download and share manually.')),
        );
      } else {
        // For mobile platforms
        await Share.shareXFiles([XFile(imagePath)], text: 'Check out my Hanbok transformation!');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing: ${e.toString()}')),
      );
    }
  }

  Future<void> _tryAgain(BuildContext context) async {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.reset();
    Navigator.pushNamedAndRemoveUntil(
      context, 
      IndexScreen.routeName, 
      (route) => false,
    );
  }
  
  // For saving the result
  Future<void> _saveResult(BuildContext context, HanbokImage result) async {
    try {
      final storageService = StorageService();
      await storageService.initialize();
      
      // Save the image permanently
      final savedPath = await storageService.saveImage(result.imagePath);
      
      if (savedPath != null) {
        // Refresh the list of saved results
        final appState = Provider.of<AppState>(context, listen: false);
        await Provider.of<AppState>(context, listen: false)
            ._hanbokService
            .loadSavedResultImages();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Result saved successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save result')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final Size screenSize = MediaQuery.of(context).size;
    final bool isLandscape = screenSize.width > screenSize.height;
    final bool isSmallScreen = screenSize.width < 600;

    if (appState.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Processing'),
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 24),
              Text(
                'Processing your image...\nThis may take a moment',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (appState.errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 24),
                Text(
                  appState.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _tryAgain(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (appState.resultHanbok == null) {
      // Redirect to index if no result
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, IndexScreen.routeName);
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final resultImage = appState.resultHanbok!;
    final imagePath = resultImage.imagePath;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Hanbok Transformation'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Clean up any temp files before navigating away
            appState.cleanupTempFiles();
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: isLandscape && !isSmallScreen
            ? _buildLandscapeLayout(context, resultImage, imagePath)
            : _buildPortraitLayout(context, resultImage, imagePath),
      ),
    );
  }

  Widget _buildPortraitLayout(BuildContext context, HanbokImage resultImage, String imagePath) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Text(
              'Here\'s how you look in your Hanbok!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppConstants.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildResultImage(context, imagePath),
            const SizedBox(height: 32),
            _buildActionButtons(context, resultImage),
          ],
        ),
      ),
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, HanbokImage resultImage, String imagePath) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildResultImage(context, imagePath),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Here\'s how you look in your Hanbok!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                _buildActionButtons(context, resultImage),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultImage(BuildContext context, String imagePath) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: imagePath.startsWith('assets/')
            ? Image.asset(
                imagePath,
                fit: BoxFit.contain,
              )
            : imagePath.startsWith('http')
                ? Image.network(
                    imagePath,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                  )
                : kIsWeb
                    ? Image.network(
                        imagePath,
                        fit: BoxFit.contain,
                      )
                    : Image.file(
                        File(imagePath),
                        fit: BoxFit.contain,
                      ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, HanbokImage resultImage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () => _saveResult(context, resultImage),
          icon: const Icon(Icons.save),
          label: const Text('Save Result'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _downloadImage(context, resultImage.imagePath),
          icon: const Icon(Icons.download),
          label: const Text('Download Image'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.secondaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _shareImage(context, resultImage.imagePath),
          icon: const Icon(Icons.share),
          label: const Text('Share'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.accentColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => _tryAgain(context),
          icon: const Icon(Icons.refresh),
          label: const Text('Try Again'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppConstants.primaryColor,
            side: BorderSide(color: AppConstants.primaryColor),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }
}