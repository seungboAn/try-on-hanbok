import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import 'dart:async';
import '../models/hanbok_image.dart';
import 'inference_service.dart';
import 'supabase_service.dart';

class HanbokService {
  // Singleton pattern
  static final HanbokService _instance = HanbokService._internal();
  factory HanbokService() => _instance;
  HanbokService._internal();
  
  // In-memory cache of hanbok images
  List<HanbokImage> _traditionalHanboks = [];
  List<HanbokImage> _modernHanboks = [];
  
  // Services
  final InferenceService _inferenceService = InferenceService();
  final SupabaseService _supabaseService = SupabaseService();
  
  // Provide access to the inference service
  InferenceService getInferenceService() {
    return _inferenceService;
  }
  
  // Load hanbok images from Supabase via Edge Function
  Future<void> loadHanbokImages() async {
    try {
      // Use Edge Function to fetch preset images
      debugPrint('Fetching hanbok presets from Edge Function...');
      final List<HanbokImage> presets = await _supabaseService.getPresetImages();
      
      if (presets.isEmpty) {
        debugPrint('No presets found from Edge Function');
        return;
      }
      
      _traditionalHanboks = presets
          .where((preset) => preset.category == 'traditional')
          .toList();
          
      _modernHanboks = presets
          .where((preset) => preset.category == 'modern')
          .toList();
          
      debugPrint('Loaded ${_traditionalHanboks.length} traditional and ${_modernHanboks.length} modern hanbok images from Supabase');
    } catch (e) {
      debugPrint('Error loading hanbok images from Supabase: $e');
      rethrow; // 에러를 상위로 전파하여 UI에서 처리할 수 있도록 함
    }
  }
  
  // Get all hanbok images
  List<HanbokImage> getHanbokImages() {
    return [..._traditionalHanboks, ..._modernHanboks];
  }
  
  // Get all hanbok images by category
  List<HanbokImage> getHanboksByCategory(String category) {
    switch (category.toLowerCase()) {
      case 'traditional':
        return _traditionalHanboks;
      case 'modern':
        return _modernHanboks;
      case 'fusion':
        return _modernHanboks.where((hanbok) => 
          hanbok.category.toLowerCase() == 'fusion'
        ).toList();
      default:
        return getHanbokImages();
    }
  }
  
  // Use actual API to generate hanbok image
  Future<String?> generateHanbokImage(String sourceImagePath, String presetImagePath) async {
    try {
      debugPrint('Generating hanbok image:');
      debugPrint('- Source image: $sourceImagePath');
      debugPrint('- Preset image: $presetImagePath');
      
      // Call the inference service to generate the image
      return await _inferenceService.generateHanbokFitting(
        sourcePath: sourceImagePath,
        targetPath: presetImagePath,
        webhookUrl: null, // We're not using webhooks directly in this implementation
      );
    } catch (e) {
      debugPrint('Error in generateHanbokImage: $e');
      rethrow; // 에러를 상위로 전파하여 UI에서 처리할 수 있도록 함
    }
  }
} 