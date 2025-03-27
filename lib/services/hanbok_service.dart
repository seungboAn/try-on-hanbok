import 'package:flutter/foundation.dart';
import '../models/hanbok_image.dart';

class HanbokService {
  // Singleton pattern
  static final HanbokService _instance = HanbokService._internal();
  factory HanbokService() => _instance;
  HanbokService._internal();
  
  // In-memory caches for hanbok images
  final List<HanbokImage> _traditionalHanbokImages = [];
  final List<HanbokImage> _modernHanbokImages = [];
  
  // Getters
  List<HanbokImage> get traditionalHanbokImages => _traditionalHanbokImages;
  List<HanbokImage> get modernHanbokImages => _modernHanbokImages;
  
  Future<void> loadHanbokImages() async {
    try {
      // For MVP purposes, generate some mock hanbok data directly
      // In a real app, this would load from a remote API
      
      // Generate 20 traditional hanbok images
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
      
      // Generate 10 modern hanbok images
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
      
      print('Loaded ${_traditionalHanbokImages.length} traditional and ${_modernHanbokImages.length} modern hanbok images');
    } catch (e) {
      print('Error loading hanbok images: $e');
      // Return empty lists on error
      _traditionalHanbokImages.clear();
      _modernHanbokImages.clear();
    }
  }
  
  List<HanbokImage> getHanboksByCategory(String category) {
    if (category == 'traditional') {
      return _traditionalHanbokImages;
    } else if (category == 'modern') {
      return _modernHanbokImages;
    } else {
      // Default to returning all images
      return [..._traditionalHanbokImages, ..._modernHanbokImages];
    }
  }
  
  Future<HanbokImage?> generateMockImage(HanbokImage selectedHanbok, dynamic userImage) async {
    // This would normally call an API with the user image and selected hanbok
    // For the MVP, just simulate an API call delay and return the same hanbok
    await Future.delayed(const Duration(seconds: 2));
    
    // In a real app, we would return a newly generated image
    // For now, just return a mock result
    return HanbokImage(
      id: 'result-${selectedHanbok.id}',
      imagePath: 'assets/images/mock_result.png',
      title: 'Your Hanbok',
      category: selectedHanbok.category,
      description: 'Your personalized hanbok',
    );
  }
}