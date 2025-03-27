import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class StorageService {
  // Singleton pattern
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();
  
  // Directory paths
  String? _appDocPath;
  String? _tempPath;
  
  // Initialize the service and create necessary directories
  Future<void> initialize() async {
    if (_appDocPath != null && _tempPath != null) return;
    
    try {
      // Get application documents directory
      final appDocDir = await getApplicationDocumentsDirectory();
      _appDocPath = appDocDir.path;
      
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      _tempPath = tempDir.path;
      
      // Create subdirectories
      await Directory('$_appDocPath/hanbok_results').create(recursive: true);
      await Directory('$_tempPath/temp_uploads').create(recursive: true);
      
      print('Storage initialized: $_appDocPath, $_tempPath');
    } catch (e) {
      print('Error initializing storage: $e');
      rethrow;
    }
  }
  
  // Save an image from a network URL to local storage
  Future<String> saveImageFromUrl(String imageUrl, {String? customFilename}) async {
    await initialize();
    
    try {
      // Generate a filename if not provided
      final filename = customFilename ?? 'hanbok_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '$_appDocPath/hanbok_results/$filename';
      
      // Download the image
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image: ${response.statusCode}');
      }
      
      // Save the image to local storage
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      
      print('Image saved to: $filePath');
      return filePath;
    } catch (e) {
      print('Error saving image from URL: $e');
      rethrow;
    }
  }
  
  // Save image data to local storage
  Future<String> saveImageData(Uint8List imageData, {String? customFilename}) async {
    await initialize();
    
    try {
      // Generate a filename if not provided
      final filename = customFilename ?? 'hanbok_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '$_appDocPath/hanbok_results/$filename';
      
      // Save the image to local storage
      final file = File(filePath);
      await file.writeAsBytes(imageData);
      
      print('Image data saved to: $filePath');
      return filePath;
    } catch (e) {
      print('Error saving image data: $e');
      rethrow;
    }
  }
  
  // Save a temporary file for upload purposes
  Future<String> saveTempFile(Uint8List fileData, String extension) async {
    await initialize();
    
    try {
      final filename = 'temp_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final filePath = '$_tempPath/temp_uploads/$filename';
      
      // Save the file
      final file = File(filePath);
      await file.writeAsBytes(fileData);
      
      print('Temporary file saved to: $filePath');
      return filePath;
    } catch (e) {
      print('Error saving temporary file: $e');
      rethrow;
    }
  }
  
  // Get all saved result images
  Future<List<String>> getSavedImages() async {
    await initialize();
    
    try {
      final directory = Directory('$_appDocPath/hanbok_results');
      if (!await directory.exists()) {
        return [];
      }
      
      List<String> files = [];
      await for (var entity in directory.list()) {
        if (entity is File && entity.path.endsWith('.png')) {
          files.add(entity.path);
        }
      }
      
      // Sort files by modification time (newest first)
      files.sort((a, b) {
        return File(b).lastModifiedSync().compareTo(File(a).lastModifiedSync());
      });
      
      return files;
    } catch (e) {
      print('Error getting saved images: $e');
      return [];
    }
  }
  
  // Delete a saved image
  Future<bool> deleteImage(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        print('Image deleted: $filePath');
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
    await initialize();
    
    try {
      final directory = Directory('$_tempPath/temp_uploads');
      if (await directory.exists()) {
        await directory.delete(recursive: true);
        await directory.create();
        print('Temporary files cleaned up');
      }
    } catch (e) {
      print('Error cleaning up temporary files: $e');
    }
  }
}