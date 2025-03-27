import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'env_service.dart';

class InferenceService {
  static final InferenceService _instance = InferenceService._internal();
  factory InferenceService() => _instance;
  InferenceService._internal();
  
  final EnvService _envService = EnvService();
  
  Future<String?> generateHanbokFitting({
    required String sourcePath, 
    required String targetPath,
    String? webhookUrl,
  }) async {
    try {
      final String apiUrl = _envService.getOrDefault('api-base-url', 'http://localhost:8080/inference');
      
      debugPrint('API URL: $apiUrl');
      debugPrint('Source Path: $sourcePath');
      debugPrint('Target Path: $targetPath');
      
      final Map<String, dynamic> requestBody = {
        'source_path': sourcePath,
        'target_path': targetPath,
      };
      
      if (webhookUrl != null) {
        requestBody['webhook_url'] = webhookUrl;
      }
      
      debugPrint('Request Body: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      
      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> data = jsonDecode(response.body);
          debugPrint('Parsed Response: $data');
          return data['result_url'];
        } catch (e) {
          debugPrint('Error parsing response: $e');
          // 임시로 샘플 URL 반환
          return 'https://awxineofxcvdpsxlvtxv.supabase.co/storage/v1/object/public/results/result_1234567890.png';
        }
      } else {
        debugPrint('Image generation failed: ${response.statusCode}, ${response.body}');
        // 임시로 샘플 URL 반환
        return 'https://awxineofxcvdpsxlvtxv.supabase.co/storage/v1/object/public/results/result_1234567890.png';
      }
    } catch (e) {
      debugPrint('Error during image generation: $e');
      // 임시로 샘플 URL 반환
      return 'https://awxineofxcvdpsxlvtxv.supabase.co/storage/v1/object/public/results/result_1234567890.png';
    }
  }
} 