import 'package:flutter/material.dart';
import 'package:supabase_services/supabase_services.dart';
import 'dart:typed_data';

class HanbokState extends ChangeNotifier {
  final _supabaseService = SupabaseServices.supabaseService;
  final _inferenceService = SupabaseServices.inferenceService;
  
  bool _isLoading = false;
  String? _authToken;
  List<HanbokImage> _modernPresets = [];
  List<HanbokImage> _traditionalPresets = [];
  String? _resultImageUrl;
  String? _uploadedImageUrl;
  String? _currentTaskId;
  String _taskStatus = 'idle'; // 'idle', 'processing', 'completed', 'error'
  String? _errorMessage;
  
  bool get isLoading => _isLoading;
  String? get authToken => _authToken;
  List<HanbokImage> get modernPresets => _modernPresets;
  List<HanbokImage> get traditionalPresets => _traditionalPresets;
  String? get resultImageUrl => _resultImageUrl;
  String? get uploadedImageUrl => _uploadedImageUrl;
  String get taskStatus => _taskStatus;
  String? get errorMessage => _errorMessage;
  
  // Initialize and authenticate
  Future<void> initialize() async {
    // 이미 프리셋이 로드되어 있으면 다시 로드하지 않음
    if (!_isLoading && _modernPresets.isNotEmpty && _traditionalPresets.isNotEmpty) {
      print('Presets already loaded, skipping initialization');
      return;
    }
    
    _isLoading = true;
    _taskStatus = 'idle';
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Anonymous login (토큰이 없는 경우에만)
      if (_authToken == null) {
        _authToken = await _supabaseService.signInAnonymously();
      }
      
      // Get presets by category (프리셋이 비어있는 경우에만)
      if (_modernPresets.isEmpty) {
        _modernPresets = await _supabaseService.getPresetImages(category: 'modern');
      }
      
      if (_traditionalPresets.isEmpty) {
        _traditionalPresets = await _supabaseService.getPresetImages(category: 'traditional');
      }
    } catch (e) {
      print('Initialization error: $e');
      _errorMessage = e.toString();
      _taskStatus = 'error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Upload user image
  Future<void> uploadUserImage(Uint8List imageBytes, String contentType) async {
    _isLoading = true;
    _taskStatus = 'processing';
    _errorMessage = null;
    notifyListeners();

    try {
      if (_authToken == null) {
        throw Exception('Authentication token is required');
      }

      final result = await _supabaseService.uploadUserImage(
        imageBytes,
        contentType,
        _authToken!
      );

      if (result == null || result['image'] == null || result['image']['image_url'] == null) {
        throw Exception('Failed to upload image: Invalid response');
      }

      _uploadedImageUrl = result['image']['image_url'];
      _taskStatus = 'completed';
    } catch (e) {
      print('Image upload error: $e');
      _errorMessage = e.toString();
      _taskStatus = 'error';
      _uploadedImageUrl = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Generate hanbok fitting
  Future<void> generateHanbokFitting(String presetImageUrl) async {
    if (_uploadedImageUrl == null) {
      print('No source image uploaded');
      _errorMessage = 'No source image uploaded';
      _taskStatus = 'error';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _taskStatus = 'processing';
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _inferenceService.generateHanbokFitting(
        sourcePath: _uploadedImageUrl!,
        targetPath: presetImageUrl,
      );

      if (result == null) {
        // Start polling for results
        _currentTaskId = _inferenceService.taskIds.last;
        await _pollForResults(_currentTaskId!);
      } else {
        _resultImageUrl = result;
        _taskStatus = 'completed';
      }
    } catch (e) {
      print('Generation error: $e');
      _errorMessage = e.toString();
      _taskStatus = 'error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Poll for results
  Future<void> _pollForResults(String taskId) async {
    while (true) {
      try {
        final status = await _inferenceService.checkTaskStatus(taskId);
        
        if (status['status'] == 'completed') {
          _resultImageUrl = status['image_url'];
          _taskStatus = 'completed';
          notifyListeners();
          break;
        } else if (status['status'] == 'error') {
          _errorMessage = status['error_message'] ?? 'An error occurred during processing';
          _taskStatus = 'error';
          notifyListeners();
          break;
        }
        
        await Future.delayed(const Duration(seconds: 3));
      } catch (e) {
        print('Polling error: $e');
        _errorMessage = e.toString();
        _taskStatus = 'error';
        notifyListeners();
        break;
      }
    }
  }
} 