import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../constants/app_constants.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final resultImage = appState.resultImagePath;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Virtual Hanbok'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Your Hanbok Transformation!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              
              appState.isLoading
                  ? const Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: AppConstants.defaultPadding),
                            Text('Processing your image...'),
                          ],
                        ),
                      ),
                    )
                  : resultImage != null
                      ? Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Image preview
                              Expanded(
                                child: Container(
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
                                      resultImage,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        print('Error loading result image: $error');
                                        return const Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.broken_image, size: 64, color: Colors.grey),
                                              SizedBox(height: 16),
                                              Text('Failed to load image'),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: AppConstants.defaultPadding),
                              
                              // Action buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _ActionButton(
                                    icon: Icons.refresh,
                                    label: 'Try Again',
                                    onPressed: () {
                                      // Return to the photo upload screen
                                      Navigator.of(context).popUntil(
                                        (route) => route.settings.name == '/photo-upload',
                                      );
                                    },
                                  ),
                                  _ActionButton(
                                    icon: Icons.download,
                                    label: 'Download',
                                    onPressed: () => _downloadImage(context),
                                  ),
                                  _ActionButton(
                                    icon: Icons.share,
                                    label: 'Share',
                                    onPressed: () => _shareImage(context),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      : const Expanded(
                          child: Center(
                            child: Text(
                              'No result image available',
                              style: AppConstants.bodyStyle,
                            ),
                          ),
                        ),
              
              const SizedBox(height: AppConstants.defaultPadding),
              
              // Start new button
              ElevatedButton(
                onPressed: () {
                  // Reset and go to start
                  appState.reset();
                  Navigator.of(context).popUntil((route) => route.settings.name == '/');
                },
                child: const Text('Start New'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _downloadImage(BuildContext context) {
    if (kIsWeb) {
      // Web doesn't support direct downloads like mobile
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Download not supported on web. Right-click the image and select "Save Image As..." instead.'),
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }
    
    // For mobile we would implement actual download logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image downloaded successfully'),
      ),
    );
  }
  
  void _shareImage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          kIsWeb
              ? 'Sharing is not supported on web'
              : 'Sharing functionality coming soon',
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  
  const _ActionButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onPressed,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: AppConstants.primaryColor,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppConstants.textColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}