import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// Helper class for web-specific functionality
class WebHelper {
  /// Downloads a file from a URL on web platforms
  static void downloadFileFromUrl(String url, String filename) {
    // Create an anchor element
    final anchor = html.AnchorElement(href: url);
    
    // Set the download attribute with the filename
    anchor.download = filename;
    
    // Simulate a click on the anchor element
    anchor.click();
  }
  
  /// Downloads a file from bytes on web platforms
  static void downloadFileFromBytes(Uint8List bytes, String filename, {String mimeType = 'image/png'}) {
    // Convert bytes to a data URL
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    // Create an anchor element
    final anchor = html.AnchorElement(href: url);
    
    // Set the download attribute with the filename
    anchor.download = filename;
    
    // Append to the document body, click, and remove
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    
    // Release the object URL to free memory
    html.Url.revokeObjectUrl(url);
  }
  
  /// Converts a base64 string to Uint8List
  static Uint8List base64ToBytes(String base64String) {
    return base64Decode(base64String);
  }
  
  /// Attempts to share content using the Web Share API
  /// Returns true if sharing was successful, false otherwise
  static Future<bool> shareContent({
    String? title,
    String? text,
    String? url,
  }) async {
    try {
      // Check if the Web Share API is available
      if (html.window.navigator.share != null) {
        // Create the share data
        final Map<String, dynamic> shareData = {};
        
        if (title != null) shareData['title'] = title;
        if (text != null) shareData['text'] = text;
        if (url != null) shareData['url'] = url;
        
        // Use the Web Share API
        await html.window.navigator.share(shareData);
        return true;
      } else {
        // Fallback for browsers that don't support the Web Share API
        if (url != null) {
          // Open the URL in a new tab
          html.window.open(url, '_blank');
          return true;
        }
        return false;
      }
    } catch (e) {
      print('Error in web sharing: $e');
      return false;
    }
  }
}