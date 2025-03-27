import 'package:flutter/foundation.dart';
import '../models/hanbok_image.dart';
import 'api_service.dart';
import 'storage_service.dart';

class HanbokService {
  // Singleton pattern
  static final HanbokService _instance = HanbokService._internal();
  factory HanbokService() => _instance;
  HanbokService._internal();
  
  // Services
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  
  // In-memory caches for hanbok images
  final List<HanbokImage> _traditionalHanbokImages = [];
  final List<HanbokImage> _modernHanbokImages = [];
  final List<HanbokImage> _savedResultImages = [];
  
  // Getters
  List<HanbokImage> get traditionalHanbokImages => _traditionalHanbokImages;
  List<HanbokImage> get modernHanbokImages => _modernHanbokImages;
  List<HanbokImage> get savedResultImages => _savedResultImages;
  
  Future<void> loadHanbokImages() async {
    try {
      // Initialize storage
      await _storageService.initialize();
      
      // For MVP purposes, generate some mock hanbok data directly
      // In a real app, this would load from a remote API
      
      // Generate traditional hanbok images
      if (_traditionalHanbokImages.isEmpty) {
        for (int i = 1; i <= 20; i++) {
          _traditionalHanbokImages.add(
            HanbokImage(
              id: 'traditional-$i',
              imagePath: 'assets/images/traditional/hanbok_${i % 10 + 1}.png',
              title: 'Traditional Hanbok ${i % 10 + 1}',
              category: 'traditional',
              description: 'A beautiful traditional hanbok design',
            ),
          );
        }
      }
      
      // Generate modern hanbok images
      if (_modernHanbokImages.isEmpty) {
        for (int i = 1; i <= 10; i++) {
          _modernHanbokImages.add(
            HanbokImage(
              id: 'modern-$i',
              imagePath: 'assets/images/modern/hanbok_${i % 5 + 1}.png',
              title: 'Modern Hanbok ${i % 5 + 1}',
              category: 'modern',
              description: 'A stylish modern hanbok design',
            ),
          );
        }
      }
      
      // Load saved result images from local storage
      await loadSavedResultImages();
      
      print('Loaded ${_traditionalHanbokImages.length} traditional and ${_modernHanbokImages.length} modern hanbok images');
      print('Loaded ${_savedResultImages.length} saved result images');
    } catch (e) {
      print('Error loading hanbok images: $e');
      // Return empty lists on error
      _traditionalHanbokImages.clear();
      _modernHanbokImages.clear();
    }
  }
  
  // Load saved result images from local storage
  Future<void> loadSavedResultImages() async {
    try {
      final savedImagePaths = await _storageService.getSavedImages();
      _savedResultImages.clear();
      
      for (int i = 0; i < savedImagePaths.length; i++) {
        final path = savedImagePaths[i];
        _savedResultImages.add(
          HanbokImage(
            id: 'saved-result-$i',
            imagePath: path,
            title: 'Saved Result ${i + 1}',
            category: 'result',
            description: 'Your saved hanbok result',
          ),
        );
      }
    } catch (e) {
      print('Error loading saved results: $e');
    }
  }
  
  List<HanbokImage> getHanboksByCategory(String category) {
    if (category == 'traditional') {
      return _traditionalHanbokImages;
    } else if (category == 'modern') {
      return _modernHanbokImages;
    } else if (category == 'result') {
      return _savedResultImages;
    } else {
      // Default to returning all template images
      return [..._traditionalHanbokImages, ..._modernHanbokImages];
    }
  }
  
  // Generate a hanbok image using the GKE API
  Future<HanbokImage?> generateHanbokImage(HanbokImage selectedHanbok, dynamic userImage) async {
    try {
      // Call the API service to generate the image
      final resultImage = await _apiService.generateHanbokImage(userImage, selectedHanbok);
      
      if (resultImage != null) {
        // Add the result to the saved images list
        _savedResultImages.add(resultImage);
        return resultImage;
      } else {
        // If API fails, fallback to a mock result for demo purposes
        print('API call failed, using mock result image');
        return HanbokImage(
          id: 'result-${selectedHanbok.id}-${DateTime.now().millisecondsSinceEpoch}',
          imagePath: 'assets/images/mock_result.png',
          title: 'Your Hanbok (Mock)',
          category: selectedHanbok.category,
          description: 'A mock hanbok result (API call failed)',
        );
      }
    } catch (e) {
      print('Error in generateHanbokImage: $e');
      // Return a mock result on error
      return HanbokImage(
        id: 'result-${selectedHanbok.id}-${DateTime.now().millisecondsSinceEpoch}',
        imagePath: 'assets/images/mock_result.png',
        title: 'Your Hanbok (Mock)',
        category: selectedHanbok.category,
        description: 'A mock hanbok result (An error occurred)',
      );
    }
  }
  
  // Delete a saved result image
  Future<bool> deleteResultImage(String imageId) async {
    try {
      // Find the image in the saved results
      final imageIndex = _savedResultImages.indexWhere((img) => img.id == imageId);
      if (imageIndex >= 0) {
        final image = _savedResultImages[imageIndex];
        
        // Delete from storage
        final deleted = await _storageService.deleteImage(image.imagePath);
        if (deleted) {
          // Remove from the list
          _savedResultImages.removeAt(imageIndex);
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error deleting result image: $e');
      return false;
    }
  }
  
  // Clean up temporary files
  Future<void> cleanupTempFiles() async {
    await _storageService.cleanupTempFiles();
  }
}