import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/hanbok_image.dart';
import '../constants/supabase_config.dart';
import 'package:uuid/uuid.dart';

class SupabaseService {
  // Get Supabase client (for public operations only)
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Edge Function endpoints
  final String uploadUserImageEndpoint = SupabaseConfig.uploadUserImageEndpoint;
  final String getPresetImagesEndpoint = SupabaseConfig.getPresetImagesEndpoint;
  
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
        Uri.parse(uploadUserImageEndpoint),
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
      debugPrint('Category: $category');
      debugPrint('Endpoint: $getPresetImagesEndpoint');

      final response = await http.get(
        Uri.parse('$getPresetImagesEndpoint?category=$category'),
        headers: {
          'Authorization': 'Bearer ${SupabaseConfig.supabaseAnonKey}',
          'Content-Type': 'application/json',
        },
      );
      
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['presets'] != null) {
          final List<dynamic> presets = data['presets'];
          return presets.map((preset) => HanbokImage(
            id: preset['id'] ?? const Uuid().v4(),
            category: preset['category'] ?? 'traditional',
            imagePath: preset['image_url'] ?? '',
            name: preset['name'] ?? 'Hanbok ${presets.indexOf(preset) + 1}',
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
  
  // Mock 데이터 로드 헬퍼 메서드
  List<HanbokImage> _loadMockPresets(String category) {
    try {
      debugPrint('Loading mock preset data for category: $category');
      final mockData = [
        HanbokImage(
          id: 'traditional_001',
          category: 'traditional',
          imagePath: 'data/traditional/1.png',
          name: 'Traditional Style 1',
        ),
        HanbokImage(
          id: 'traditional_002',
          category: 'traditional',
          imagePath: 'data/traditional/2.png',
          name: 'Traditional Style 2',
        ),
        HanbokImage(
          id: 'modern_001',
          category: 'modern',
          imagePath: 'data/modern/1.png',
          name: 'Modern Style 1',
        ),
        HanbokImage(
          id: 'modern_002',
          category: 'modern',
          imagePath: 'data/modern/2.png',
          name: 'Modern Style 2',
        ),
      ];

      if (category == 'all') {
        return mockData;
      }
      return mockData.where((preset) => preset.category == category).toList();
    } catch (e) {
      debugPrint('Error loading mock presets: $e');
      return [];
    }
  }
  
  // Get current user JWT token if available
  String? get currentUserToken => _supabase.auth.currentSession?.accessToken;
  
  // Sign in anonymously (for testing purposes)
  Future<String?> signInAnonymously() async {
    try {
      // 현재 Supabase Flutter SDK 버전에 따라 메서드가 다릅니다.
      // 최신 버전에서는 signInAnonymously가 아닌 다른 방법을 사용
      try {
        // 최신 버전 시도
        final res = await _supabase.auth.signUp(
          email: 'anonymous_${DateTime.now().millisecondsSinceEpoch}@example.com',
          password: 'anonymous${DateTime.now().millisecondsSinceEpoch}',
        );
        return res.session?.accessToken;
      } catch (e) {
        debugPrint('Failed to use signUp method, trying alternative: $e');
        // 대체 방법으로 게스트 세션 생성 시도
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
} 