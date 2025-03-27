import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import 'package:gallery_saver/gallery_saver.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:typed_data' show Uint8List;
import 'dart:async';
import '../constants/app_constants.dart';
import '../services/app_state.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({Key? key}) : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  Timer? _pollingTimer;
  bool _isPolling = false;
  String? _pollingStatus;
  
  @override
  void initState() {
    super.initState();
    // Start polling when screen initializes
    _startPolling();
  }
  
  @override
  void dispose() {
    // Cancel timer when screen is disposed
    _pollingTimer?.cancel();
    super.dispose();
  }
  
  void _startPolling() {
    // Only start if not already polling
    if (_isPolling) return;
    
    setState(() {
      _isPolling = true;
      _pollingStatus = 'Starting...';
    });
    
    // Poll every 3 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _pollForResults();
    });
    
    // Immediately poll once
    _pollForResults();
  }
  
  Future<void> _pollForResults() async {
    final appState = provider.Provider.of<AppState>(context, listen: false);
    
    // If we already have a result, stop polling
    if (appState.resultImagePath != null) {
      debugPrint('Already have a result, stopping polling');
      _stopPolling();
      return;
    }
    
    setState(() {
      _pollingStatus = 'Checking for results...';
    });
    
    try {
      // Call the polling method in AppState
      debugPrint('Polling for task results...');
      await appState.pollTaskResults();
      
      // If we now have a result, stop polling
      if (appState.resultImagePath != null) {
        debugPrint('Received result, stopping polling');
        _stopPolling();
        
        // Verify the URL
        _verifyImageUrl(appState.resultImagePath!);
      } else if (appState.errorMessage != null) {
        debugPrint('Received error: ${appState.errorMessage}');
        _stopPolling();
      }
    } catch (e) {
      debugPrint('Error during polling: $e');
      setState(() {
        _pollingStatus = 'Error: $e';
      });
    }
  }
  
  void _verifyImageUrl(String url) {
    debugPrint('Verifying image URL: $url');
    http.get(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        debugPrint('Image URL verification successful: ${response.statusCode}');
      } else {
        debugPrint('Image URL verification failed: ${response.statusCode}');
      }
    }).catchError((error) {
      debugPrint('Error verifying image URL: $error');
    });
  }
  
  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    
    setState(() {
      _isPolling = false;
      _pollingStatus = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = provider.Provider.of<AppState>(context);
    
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
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Result',
                style: AppConstants.headingStyle,
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              
              Expanded(
                child: appState.isLoading || (appState.resultImagePath == null && _isPolling)
                    ? _buildLoadingState()
                    : appState.resultImagePath != null
                        ? _buildResultState(context, appState)
                        : _buildErrorState(appState),
              ),
              
              const SizedBox(height: AppConstants.defaultPadding),
              
              // Try again button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => appState.reset(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppConstants.primaryColor,
                    elevation: 0,
                    side: BorderSide(color: AppConstants.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    ),
                  ),
                  child: const Text(
                    'Try Again',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Text(
            _pollingStatus ?? 'Generating your hanbok image...',
            style: AppConstants.bodyStyle,
            textAlign: TextAlign.center,
          ),
          if (_isPolling)
            Padding(
              padding: const EdgeInsets.only(top: AppConstants.smallPadding),
              child: Text(
                'This may take a few moments...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildErrorState(AppState appState) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red[300],
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            appState.errorMessage ?? 'An error occurred',
            style: AppConstants.bodyStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          TextButton(
            onPressed: () {
              // Restart polling
              _startPolling();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResultState(BuildContext context, AppState appState) {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              child: CachedNetworkImage(
                imageUrl: appState.resultImagePath!,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 500),
                memCacheHeight: 800,
                maxHeightDiskCache: 1024,
                maxWidthDiskCache: 768,
                errorWidget: (context, url, error) {
                  debugPrint('Error loading image from URL: $url - Error: $error');
                  // Try an alternative approach with direct Image.network with different caching
                  return FutureBuilder(
                    future: _retryLoadImage(url),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done && 
                          snapshot.data == true) {
                        return Image.network(
                          // Add cache-busting parameter if not already present
                          url.contains('?') ? '$url&t=${DateTime.now().millisecondsSinceEpoch}' 
                            : '$url?t=${DateTime.now().millisecondsSinceEpoch}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error, color: Colors.red, size: 48),
                                  const SizedBox(height: 16),
                                  const Text('Failed to load image'),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      // Force refresh the image
                                      setState(() {});
                                      // Try to poll results again
                                      _pollForResults();
                                    },
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      } else {
                        return Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error, color: Colors.red, size: 48),
                                const SizedBox(height: 16),
                                Text(snapshot.hasError ? 'Error: ${snapshot.error}' : 'Retrying...'),
                                const SizedBox(height: 8),
                                if (!snapshot.hasData && snapshot.connectionState != ConnectionState.waiting)
                                  ElevatedButton(
                                    onPressed: () {
                                      // Force refresh the image
                                      setState(() {});
                                      // Try to poll results again
                                      _pollForResults();
                                    },
                                    child: const Text('Retry'),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
                placeholder: (context, url) {
                  debugPrint('Loading image from URL: $url');
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(),
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
          children: [
            // Save button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: appState.resultImagePath != null
                    ? () async {
                        try {
                          if (kIsWeb) {
                            // Web platform: Download image
                            final response = await http.get(Uri.parse(appState.resultImagePath!));
                            final bytes = response.bodyBytes;
                            // TODO: Implement web download
                          } else {
                            // Mobile platform: Save to gallery
                            await GallerySaver.saveImage(appState.resultImagePath!);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Image saved to gallery')),
                            );
                          }
                        } catch (e) {
                          debugPrint('Error saving image: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to save image')),
                          );
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                ),
                icon: const Icon(Icons.save_alt),
                label: const Text('Save'),
              ),
            ),
            
            const SizedBox(width: AppConstants.defaultPadding),
            
            // Share button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: appState.resultImagePath != null
                    ? () async {
                        try {
                          await Share.share(
                            'Check out my virtual hanbok fitting!',
                            subject: 'Virtual Hanbok Fitting Result',
                          );
                        } catch (e) {
                          debugPrint('Error sharing image: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to share image')),
                          );
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppConstants.primaryColor,
                  elevation: 0,
                  side: BorderSide(color: AppConstants.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                ),
                icon: const Icon(Icons.share),
                label: const Text('Share'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<bool> _retryLoadImage(String url) async {
    try {
      // First check if the URL is accessible
      final response = await http.head(Uri.parse(url));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('URL is accessible in retry: $url');
        return true;
      }
      
      // If original URL isn't accessible, try with added timestamp
      final timestampUrl = url.contains('?') 
          ? '$url&t=${DateTime.now().millisecondsSinceEpoch}' 
          : '$url?t=${DateTime.now().millisecondsSinceEpoch}';
      
      final retryResponse = await http.head(Uri.parse(timestampUrl));
      debugPrint('Retry URL accessibility status: ${retryResponse.statusCode}');
      
      return retryResponse.statusCode >= 200 && retryResponse.statusCode < 300;
    } catch (e) {
      debugPrint('Error retrying image load: $e');
      return false;
    }
  }
} 