import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/api_config.dart';
import '../models/hanbok_image.dart';
import 'storage_service.dart';

class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();
  
  final StorageService _storageService = StorageService();
  
  // Create HTTP client with timeout settings
  final http.Client _client = http.Client();
  
  Future<Map<String, String>> _getHeaders() async {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${ApiConfig.apiKey}',
    };
  }
  
  // Generate a Hanbok image by sending a user image to the GKE API
  Future<HanbokImage?> generateHanbokImage(dynamic userImage, HanbokImage selectedHanbok) async {
    try {
      // Initialize storage
      await _storageService.initialize();
      
      // Convert user image to required format for API
      late String imagePath;
      late List<int> imageBytes;
      
      if (userImage is File) {
        // For mobile platforms
        imageBytes = await userImage.readAsBytes();
        imagePath = userImage.path;
      } else if (userImage is Uint8List) {
        // For web platform
        imageBytes = userImage;
        imagePath = await _storageService.saveTempFile(userImage, 'png');
      } else {
        throw Exception('Unsupported image format');
      }
      
      // Prepare the API request
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.generateHanbokEndpoint}');
      
      // Create a multipart request
      final request = http.MultipartRequest('POST', uri);
      
      // Add headers
      final headers = await _getHeaders();
      request.headers.addAll(headers);
      
      // Add user image file
      request.files.add(http.MultipartFile.fromBytes(
        'user_image',
        imageBytes,
        filename: 'user_image.png',
        contentType: MediaType('image', 'png'),
      ));
      
      // Add selected hanbok information
      request.fields['hanbok_id'] = selectedHanbok.id;
      request.fields['hanbok_category'] = selectedHanbok.category;
      
      // Send the request and wait for response
      print('Sending request to GKE API: $uri');
      final streamedResponse = await request.send().timeout(
        Duration(milliseconds: ApiConfig.connectionTimeout),
      );
      
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        print('GKE API response received: ${response.statusCode}');
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData.containsKey('image_url')) {
          // Download and save the generated image
          final imageUrl = responseData['image_url'] as String;
          final localImagePath = await _storageService.saveImageFromUrl(
            imageUrl,
            customFilename: 'result_${DateTime.now().millisecondsSinceEpoch}.png',
          );
          
          // Create and return a new HanbokImage object with the result
          return HanbokImage(
            id: 'result-${selectedHanbok.id}-${DateTime.now().millisecondsSinceEpoch}',
            imagePath: localImagePath,
            title: 'Your Custom Hanbok',
            category: selectedHanbok.category,
            description: 'A personalized hanbok based on your photo',
          );
        } else if (responseData.containsKey('image_data')) {
          // Handle base64 encoded image data response
          final base64Image = responseData['image_data'] as String;
          final imageData = base64Decode(base64Image);
          
          final localImagePath = await _storageService.saveImageData(
            Uint8List.fromList(imageData),
            customFilename: 'result_${DateTime.now().millisecondsSinceEpoch}.png',
          );
          
          // Create and return a new HanbokImage object with the result
          return HanbokImage(
            id: 'result-${selectedHanbok.id}-${DateTime.now().millisecondsSinceEpoch}',
            imagePath: localImagePath,
            title: 'Your Custom Hanbok',
            category: selectedHanbok.category,
            description: 'A personalized hanbok based on your photo',
          );
        } else {
          throw Exception('No image data found in API response');
        }
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to generate image: ${response.statusCode}');
      }
    } catch (e) {
      print('Error generating hanbok image: $e');
      // Clean up temp files on error
      await _storageService.cleanupTempFiles();
      return null;
    }
  }
  
  // Handle API errors and provide user-friendly messages
  String getErrorMessage(dynamic error) {
    if (error is SocketException) {
      return 'Network error. Please check your internet connection.';
    } else if (error is HttpException) {
      return 'Could not reach the server. Please try again later.';
    } else if (error is FormatException) {
      return 'Invalid response from server. Please try again.';
    } else if (error is TimeoutException) {
      return 'Connection timed out. Please try again.';
    } else {
      return 'An unexpected error occurred. Please try again later.';
    }
  }
  
  // Close the HTTP client when done
  void dispose() {
    _client.close();
  }
}