import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/hanbok_image.dart';

class AppState extends ChangeNotifier {
  // User selections
  HanbokImage? selectedHanbok;
  dynamic userImage; // Can be File on mobile or Uint8List on web
  String? resultImagePath;
  bool isLoading = false;

  // For pagination
  int _pageSize = 8;
  int _currentPage = 1;
  String _selectedCategory = 'traditional';
  
  int get pageSize => _pageSize;
  int get currentPage => _currentPage;
  String get selectedCategory => _selectedCategory;
  
  bool get hasUserImage => userImage != null;
  bool get hasSelectedHanbok => selectedHanbok != null;
  bool get hasResult => resultImagePath != null;
  
  // For web compatibility
  bool get isUserImageFile => userImage is File;
  bool get isUserImageBytes => userImage is Uint8List;
  
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
    notifyListeners();
  }
  
  void setLoading(bool loading) {
    isLoading = loading;
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
  
  void reset() {
    selectedHanbok = null;
    userImage = null;
    resultImagePath = null;
    isLoading = false;
    _currentPage = 1;
    _selectedCategory = 'traditional';
    notifyListeners();
  }
}