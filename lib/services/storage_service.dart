import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  // Singleton pattern
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();
  
  // Directories
  Directory? _appDir;
  Directory? _tempDir;
  Directory? _resultsDir;
  
  // Constants
  final String _resultsDirName = 'hanbok_results';
  final String _tempDirName = 'temp';
  
  // Initialize storage
  Future<void> initialize() async {
    if (_appDir != null) return; // Already initialized
    
    if (kIsWeb) {
      // Web doesn't use local filesystem in the same way
      // For web, methods will handle cases differently
      return;
    }
    
    try {
      // Get application directory
      _appDir = await getApplicationDocumentsDirectory();
      
      // Create results directory if it doesn't exist
      _resultsDir = Directory(path.join(_appDir!.path, _resultsDirName));
      if (!await _resultsDir!.exists()) {
        await _resultsDir!.create(recursive: true);
      }
      
      // Create temp directory if it doesn't exist
      _tempDir = Directory(path.join(_appDir!.path, _tempDirName));
      if (!await _tempDir!.exists()) {
        await _tempDir!.create(recursive: true);
      }
      
      print('Storage initialized: ${_appDir!.path}');
    } catch (e) {
      print('Error initializing storage: $e');
    }
  }
  
  // Save an image from a URL to the results directory
  Future<String?> saveImageFromUrl(String imageUrl) async {
    if (kIsWeb) {
      // For web, just return the URL since we can't save files locally
      return imageUrl;
    }
    
    try {
      await initialize();
      
      // Download the image
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        print('Error downloading image: ${response.statusCode}');
        return null;
      }
      
      // Generate a filename
      final filename = 'hanbok_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = path.join(_resultsDir!.path, filename);
      
      // Save the file
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      
      return filePath;
    } catch (e) {
      print('Error saving image from URL: $e');
      return null;
    }
  }
  
  // Save image data (Uint8List) to the results directory
  Future<String?> saveImageData(Uint8List imageData) async {
    if (kIsWeb) {
      // For web, we'll create a temporary object URL
      // This is just a placeholder behavior since web can't save files
      return 'blob:${const Uuid().v4()}';
    }
    
    try {
      await initialize();
      
      // Generate a filename
      final filename = 'hanbok_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = path.join(_resultsDir!.path, filename);
      
      // Save the file
      final file = File(filePath);
      await file.writeAsBytes(imageData);
      
      return filePath;
    } catch (e) {
      print('Error saving image data: $e');
      return null;
    }
  }
  
  // Save a file to temporary storage
  Future<String?> saveTempFile(File imageFile) async {
    if (kIsWeb) {
      // For web, this would require a different approach
      return null;
    }
    
    try {
      await initialize();
      
      // Generate a filename
      final filename = 'temp_${path.basename(imageFile.path)}';
      final filePath = path.join(_tempDir!.path, filename);
      
      // Copy the file
      await imageFile.copy(filePath);
      
      return filePath;
    } catch (e) {
      print('Error saving temp file: $e');
      return null;
    }
  }
  
  // Save an image from local path to the results directory
  Future<String?> saveImage(String imagePath) async {
    // Handle asset paths
    if (imagePath.startsWith('assets/')) {
      // We can't copy an asset directly
      print('Cannot save asset images directly');
      return null;
    }
    
    // Handle web
    if (kIsWeb) {
      // For web, just return the path since we can't save files locally
      return imagePath;
    }
    
    try {
      await initialize();
      
      // Check if the file exists
      final sourceFile = File(imagePath);
      if (!await sourceFile.exists()) {
        print('Source file does not exist: $imagePath');
        return null;
      }
      
      // Generate a filename
      final filename = 'hanbok_${DateTime.now().millisecondsSinceEpoch}${path.extension(imagePath)}';
      final destPath = path.join(_resultsDir!.path, filename);
      
      // Copy the file
      await sourceFile.copy(destPath);
      
      return destPath;
    } catch (e) {
      print('Error saving image: $e');
      return null;
    }
  }
  
  // Get all saved images
  Future<List<String>> getSavedImages() async {
    if (kIsWeb) {
      // For web, we can't access the filesystem directly
      // Return empty list for now
      return [];
    }
    
    try {
      await initialize();
      
      final dir = _resultsDir!;
      final files = await dir.list().toList();
      
      // Filter for image files
      final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif'];
      return files
          .where((file) => 
              file is File && 
              imageExtensions.any((ext) => file.path.toLowerCase().endsWith(ext)))
          .map((file) => file.path)
          .toList();
    } catch (e) {
      print('Error getting saved images: $e');
      return [];
    }
  }
  
  // Delete image by path
  Future<bool> deleteImage(String imagePath) async {
    if (kIsWeb) {
      // For web, just return true since we can't save files locally
      return true;
    }
    
    try {
      await initialize();
      
      // Handle asset paths
      if (imagePath.startsWith('assets/')) {
        // Can't delete assets
        return false;
      }
      
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }
  
  // Clean up temporary files
  Future<void> cleanupTempFiles() async {
    if (kIsWeb) return; // No temp files in web
    
    try {
      await initialize();
      
      final dir = _tempDir!;
      final files = await dir.list().toList();
      
      for (var file in files) {
        if (file is File) {
          await file.delete();
        }
      }
    } catch (e) {
      print('Error cleaning up temp files: $e');
    }
  }
}