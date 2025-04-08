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
  Future<Map<String, dynamic>> uploadUserImage(
      Uint8List imageBytes, String contentType, String? token) async {
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
        Uri.parse(
            '${SupabaseConfig.getPresetImagesEndpoint}?category=$category'),
        headers: {
          'Authorization': 'Bearer ${SupabaseConfig.supabaseAnonKey}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['presets'] != null) {
          final List<dynamic> presets = data['presets'];
          return presets
              .map((preset) => HanbokImage(
                    id: preset['id'] ?? const Uuid().v4(),
                    category: preset['category'] ?? 'unknown',
                    imagePath: preset['image_url'] ?? '',
                    name: preset['name'] ??
                        'Preset ${presets.indexOf(preset) + 1}',
                    description: preset['description'],
                    originalFilename:
                        preset['original_filename'] ?? preset['name'],
                  ))
              .toList();
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

  // 모든 프리셋 이미지를 한 번에 가져오기 (API 호출 최적화)
  Future<List<HanbokImage>> getAllPresetImages() async {
    debugPrint('Fetching all presets in a single API call...');
    // 카테고리 매개변수 없이 'all'로 모든 프리셋을 한 번에 가져옴
    final allPresets = await getPresetImages(category: 'all');
    debugPrint('Retrieved ${allPresets.length} total presets in a single request');
    return allPresets;
  }

  // Sign in anonymously
  Future<String?> signInAnonymously() async {
    try {
      // Try to use signUp with a random email (modern approach)
      try {
        final res = await supabaseClient.auth.signUp(
          email:
              'anonymous_${DateTime.now().millisecondsSinceEpoch}@example.com',
          password: 'anonymous${DateTime.now().millisecondsSinceEpoch}',
        );
        return res.session?.accessToken;
      } catch (e) {
        debugPrint('Failed to use signUp method, trying alternative: $e');

        // Alternative method as a fallback
        final response = await http.post(
          Uri.parse(
              '${SupabaseConfig.supabaseUrl}/auth/v1/token?grant_type=password'),
          headers: {
            'Content-Type': 'application/json',
            'apikey': SupabaseConfig.supabaseAnonKey,
          },
          body: jsonEncode({
            'email':
                'anonymous_${DateTime.now().millisecondsSinceEpoch}@example.com',
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
  Future<String> uploadFile(
      Uint8List fileBytes, String path, String? contentType) async {
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
  Future<String> getPresignedUrl(String bucket, String path,
      {int expiresIn = 3600}) async {
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

  // 서버에서 결과 URL이 제공되지 않을 때 사용할 대체 이미지 URL 반환
  Future<String?> getDefaultResultImage({List<HanbokImage>? existingPresets}) async {
    try {
      // 이미 로드된 프리셋이 있으면 재사용
      if (existingPresets != null && existingPresets.isNotEmpty) {
        debugPrint('Using existing presets for fallback image');
        // 카테고리가 'modern'인 첫 번째 프리셋 찾기
        final modernPreset = existingPresets.firstWhere(
          (preset) => preset.category == 'modern',
          orElse: () => existingPresets.first, // modern이 없으면 첫번째 아무거나 사용
        );
        debugPrint('Using fallback image: ${modernPreset.imagePath}');
        return modernPreset.imagePath;
      }
      
      // 프리셋이 제공되지 않은 경우에만 API 호출
      final modernPresets = await getPresetImages(category: 'modern');
      if (modernPresets.isNotEmpty) {
        // 첫 번째 모던 프리셋 이미지 반환 (임시 대체용)
        debugPrint('Using fallback image from API: ${modernPresets.first.imagePath}');
        return modernPresets.first.imagePath;
      }

      // 프리셋이 없는 경우 null 반환
      return null;
    } catch (e) {
      debugPrint('Error getting default result image: $e');
      return null;
    }
  }
}
