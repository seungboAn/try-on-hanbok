import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Helper class for mobile-specific functionality
/// This class provides the same interface as WebHelper but for mobile platforms
class WebHelper {
  /// Dummy method to maintain API compatibility with web version
  static void downloadFileFromUrl(String url, String filename) {
    // This method is only called on web platforms
    print('downloadFileFromUrl is only supported on web platforms');
  }
  
  /// Dummy method to maintain API compatibility with web version
  static void downloadFileFromBytes(Uint8List bytes, String filename, {String mimeType = 'image/png'}) {
    // This method is only called on web platforms
    print('downloadFileFromBytes is only supported on web platforms');
  }
  
  /// Dummy method to maintain API compatibility with web version
  static Future<bool> shareContent({
    String? title,
    String? text,
    String? url,
  }) async {
    // This method is only called on web platforms
    print('shareContent is only supported on web platforms');
    return false;
  }
}

/// Helper class for mobile-specific functionality
class MobileHelper {
  /// Save image to device gallery
  static Future<String?> saveImageToGallery(File imageFile) async {
    try {
      // Create a directory for saved images if it doesn't exist
      final appDir = await getApplicationDocumentsDirectory();
      final saveDir = Directory(path.join(appDir.path, 'saved_images'));
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }
      
      // Generate a unique filename
      final filename = 'hanbok_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
      final savePath = path.join(saveDir.path, filename);
      
      // Copy the file
      final File savedFile = await imageFile.copy(savePath);
      return savedFile.path;
    } catch (e) {
      print('Error saving image to gallery: $e');
      return null;
    }
  }
  
  /// Save bytes to gallery
  static Future<String?> saveBytesToGallery(Uint8List bytes, {String extension = '.jpg'}) async {
    try {
      // Create a directory for saved images if it doesn't exist
      final appDir = await getApplicationDocumentsDirectory();
      final saveDir = Directory(path.join(appDir.path, 'saved_images'));
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }
      
      // Generate a unique filename
      final filename = 'hanbok_${DateTime.now().millisecondsSinceEpoch}$extension';
      final savePath = path.join(saveDir.path, filename);
      
      // Write bytes to file
      final File savedFile = File(savePath);
      await savedFile.writeAsBytes(bytes);
      return savedFile.path;
    } catch (e) {
      print('Error saving bytes to gallery: $e');
      return null;
    }
  }
}