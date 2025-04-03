import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../constants/supabase_config.dart';
import '../models/hanbok_image.dart';

class SupabaseService {
  // Singleton pattern
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();
  
  // Get Supabase client (for public operations only)
  SupabaseClient get supabaseClient => Supabase.instance.client;
  
  // Current user session
  Session? get currentSession => supabaseClient.auth.currentSession;
  
  // Current user JWT token
  String? get currentUserToken => currentSession?.accessToken;
  
  // Headers for API requests
  Map<String, String> _getHeaders(String? token) {
    final headers = {
      'Content-Type': 'application/json',
      'apikey': SupabaseConfig.supabaseAnonKey,
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }
  
  // Upload user image via Edge Function
  Future<Map<String, dynamic>> uploadUserImage(Uint8List imageBytes, String contentType, String? token) async {
    if (token == null) {
      throw Exception('Authentication token required for image upload');
    }
    
    try {
      // Convert image to base64
      final base64Image = base64Encode(imageBytes);
      
      final response = await http.post(
        Uri.parse(SupabaseConfig.uploadUserImageEndpoint),
        headers: _getHeaders(token),
        body: jsonEncode({
          'file': {
            'base64': 'data:$contentType;base64,$base64Image',
            'contentType': contentType,
          },
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Error uploading image: ${response.body}');
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in uploadUserImage: $e');
      throw Exception('Failed to upload user image: $e');
    }
  }
  
  // Get preset images via Edge Function
  Future<List<HanbokImage>> getPresetImages({String category = 'all'}) async {
    try {
      debugPrint('Fetching presets from Edge Function...');
      
      final response = await http.get(
        Uri.parse('${SupabaseConfig.getPresetImagesEndpoint}?category=$category'),
        headers: {
          'Authorization': 'Bearer ${SupabaseConfig.supabaseAnonKey}',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['presets'] != null) {
          final List<dynamic> presets = data['presets'];
          return presets.map((preset) => HanbokImage(
            id: preset['id'] ?? const Uuid().v4(),
            category: preset['category'] ?? 'unknown',
            imagePath: preset['image_url'] ?? '',
            name: preset['name'] ?? 'Preset ${presets.indexOf(preset) + 1}',
            description: preset['description'],
            originalFilename: preset['original_filename'] ?? preset['name'],
          )).toList();
        } else {
          debugPrint('Empty presets or success not true: ${response.body}');
          return [];
        }
      } else {
        debugPrint('Error getting preset images: ${response.body}');
        throw Exception('Failed to get preset images: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in getPresetImages: $e');
      throw Exception('Failed to get preset images: $e');
    }
  }
  
  // Sign in anonymously
  Future<String?> signInAnonymously() async {
    try {
      // Try to use signUp with a random email (modern approach)
      try {
        final res = await supabaseClient.auth.signUp(
          email: 'anonymous_${DateTime.now().millisecondsSinceEpoch}@example.com',
          password: 'anonymous${DateTime.now().millisecondsSinceEpoch}',
        );
        return res.session?.accessToken;
      } catch (e) {
        debugPrint('Failed to use signUp method, trying alternative: $e');
        
        // Alternative method as a fallback
        final response = await http.post(
          Uri.parse('${SupabaseConfig.supabaseUrl}/auth/v1/token?grant_type=password'),
          headers: {
            'Content-Type': 'application/json',
            'apikey': SupabaseConfig.supabaseAnonKey,
          },
          body: jsonEncode({
            'email': 'anonymous_${DateTime.now().millisecondsSinceEpoch}@example.com',
            'password': 'anonymous${DateTime.now().millisecondsSinceEpoch}',
          }),
        );
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['access_token'];
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error signing in anonymously: $e');
      return null;
    }
  }
  
  // Sign out current user
  Future<void> signOut() async {
    try {
      await supabaseClient.auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      throw Exception('Failed to sign out: $e');
    }
  }
  
  // Upload file to Supabase storage
  Future<String> uploadFile(Uint8List fileBytes, String path, String? contentType) async {
    try {
      final response = await supabaseClient.storage
          .from(SupabaseConfig.userImagesBucket)
          .uploadBinary(
            path,
            fileBytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: true,
            ),
          );
      
      // Get public URL
      final publicUrl = supabaseClient.storage
          .from(SupabaseConfig.userImagesBucket)
          .getPublicUrl(path);
          
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      throw Exception('Failed to upload file: $e');
    }
  }
  
  // Get presigned URL for a file
  Future<String> getPresignedUrl(String bucket, String path, {int expiresIn = 3600}) async {
    try {
      final response = await supabaseClient.storage
          .from(bucket)
          .createSignedUrl(path, expiresIn);
          
      return response;
    } catch (e) {
      debugPrint('Error getting presigned URL: $e');
      throw Exception('Failed to get presigned URL: $e');
    }
  }
} 