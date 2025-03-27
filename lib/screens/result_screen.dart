import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import 'package:gallery_saver/gallery_saver.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:typed_data' show Uint8List;
import '../constants/app_constants.dart';
import '../services/app_state.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({Key? key}) : super(key: key);

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
                'Step 3: See your result',
                style: AppConstants.headingStyle,
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              
              Expanded(
                child: appState.isLoading
                    ? _buildLoadingState()
                    : _buildResultState(context, appState),
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
          const Text(
            'Generating your hanbok image...',
            style: AppConstants.bodyStyle,
            textAlign: TextAlign.center,
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
} 