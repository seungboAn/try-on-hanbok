import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/hanbok_image.dart';
import '../services/hanbok_service.dart';

class AppState extends ChangeNotifier {
  // Services
  final HanbokService _hanbokService = HanbokService();
  
  // User selections
  HanbokImage? selectedHanbok;
  dynamic userImage; // Can be File on mobile or Uint8List on web
  String? resultImagePath;
  HanbokImage? resultHanbok;
  bool isLoading = false;
  String? errorMessage;

  // For pagination
  int _pageSize = 8;
  int _currentPage = 1;
  String _selectedCategory = 'traditional';
  
  int get pageSize => _pageSize;
  int get currentPage => _currentPage;
  String get selectedCategory => _selectedCategory;
  
  bool get hasUserImage => userImage != null;
  bool get hasSelectedHanbok => selectedHanbok != null;
  bool get hasResult => resultHanbok != null;
  
  // For web compatibility
  bool get isUserImageFile => userImage is File;
  bool get isUserImageBytes => userImage is Uint8List;
  
  List<HanbokImage> getSavedResults() {
    return _hanbokService.savedResultImages;
  }
  
  void selectHanbok(HanbokImage hanbok) {
    selectedHanbok = hanbok;
    notifyListeners();
  }
  
  void setUserImage(dynamic image) {
    userImage = image;
    notifyListeners();
  }
  
  void setResultImage(String path) {
    resultImagePath = path;
    // Create a result hanbok object
    resultHanbok = HanbokImage(
      id: 'result-${DateTime.now().millisecondsSinceEpoch}',
      imagePath: path,
      title: 'Your Hanbok Result',
      category: 'result',
      description: 'Your personalized hanbok result',
    );
    notifyListeners();
  }
  
  void setLoading(bool loading) {
    isLoading = loading;
    if (loading) {
      errorMessage = null;
    }
    notifyListeners();
  }
  
  void setError(String message) {
    errorMessage = message;
    notifyListeners();
  }
  
  void selectCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      _currentPage = 1; // Reset to first page when changing categories
      notifyListeners();
    }
  }
  
  void nextPage() {
    _currentPage++;
    notifyListeners();
  }
  
  void resetPagination() {
    _currentPage = 1;
    notifyListeners();
  }
  
  Future<bool> generateHanbokImage() async {
    if (!hasSelectedHanbok || !hasUserImage) {
      setError('Please select a hanbok and upload your photo first.');
      return false;
    }
    
    setLoading(true);
    
    try {
      // Call the service to generate the image
      final result = await _hanbokService.generateHanbokImage(selectedHanbok!, userImage);
      
      if (result != null) {
        resultHanbok = result;
        resultImagePath = result.imagePath;
        setLoading(false);
        return true;
      } else {
        setError('Failed to generate hanbok image. Please try again.');
        setLoading(false);
        return false;
      }
    } catch (e) {
      setError('An error occurred: ${e.toString()}');
      setLoading(false);
      return false;
    }
  }
  
  // Delete a saved result
  Future<bool> deleteResult(String resultId) async {
    try {
      final success = await _hanbokService.deleteResultImage(resultId);
      if (success) {
        // If the current result is the one being deleted, clear it
        if (resultHanbok != null && resultHanbok!.id == resultId) {
          resultHanbok = null;
          resultImagePath = null;
        }
        notifyListeners();
      }
      return success;
    } catch (e) {
      setError('Failed to delete result: ${e.toString()}');
      return false;
    }
  }
  
  // Clean up temporary files
  Future<void> cleanupTempFiles() async {
    await _hanbokService.cleanupTempFiles();
  }
  
  // Reset for a new session
  void reset() {
    selectedHanbok = null;
    userImage = null;
    resultImagePath = null;
    resultHanbok = null;
    isLoading = false;
    errorMessage = null;
    _currentPage = 1;
    _selectedCategory = 'traditional';
    notifyListeners();
  }
}