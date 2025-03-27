import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../models/hanbok_image.dart';
import 'hanbok_service.dart';
import 'supabase_service.dart';
import 'package:http/http.dart' as http;

class AppState extends ChangeNotifier {
  // App step tracking
  int _currentStep = 0;
  int get currentStep => _currentStep;
  
  // Filter category
  String _selectedCategory = 'All';
  String get selectedCategory => _selectedCategory;
  
  // Selected hanbok preset
  HanbokImage? _selectedHanbokPreset;
  HanbokImage? get selectedHanbokPreset => _selectedHanbokPreset;
  
  // Source image (user uploaded)
  File? _sourceImage;
  File? get sourceImage => _sourceImage;
  
  // For web platform
  XFile? _sourceXFile;
  XFile? get sourceXFile => _sourceXFile;
  
  // For web platform - image URL
  String? _sourceImageUrl;
  String? get sourceImageUrl => _sourceImageUrl;
  
  // Backup public URL (in case the signed URL expires)
  String? _publicBackupUrl;
  String? get publicBackupUrl => _publicBackupUrl;
  
  // Storage URL expiry time
  DateTime? _storageExpiry;
  DateTime? get storageExpiry => _storageExpiry;
  
  // Result image
  String? _resultImagePath;
  String? get resultImagePath => _resultImagePath;
  
  // Loading states
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  // Error state
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  
  // Authentication token
  String? _authToken;
  bool get isAuthenticated => _authToken != null;
  
  // Services
  final HanbokService _hanbokService = HanbokService();
  final SupabaseService _supabaseService = SupabaseService();
  
  // 카테고리 관련 상태
  final List<String> categories = ['All', 'Traditional', 'Modern', 'Fusion'];
  String get currentCategory => _selectedCategory;
  
  // Change the category filter
  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }
  
  // Get hanbok images by current category
  List<HanbokImage> getHanboksByCurrentCategory() {
    if (_selectedCategory.toLowerCase() == 'all') {
      return _hanbokService.getHanbokImages();
    }
    return _hanbokService.getHanbokImages().where((hanbok) => 
      hanbok.category.toLowerCase() == _selectedCategory.toLowerCase()
    ).toList();
  }

  // Initialize the state
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Sign in anonymously to get token for Edge Function calls
      await _signInAnonymously();
      
      // Load hanbok presets from Edge Function
      await _hanbokService.loadHanbokImages();
    } catch (e) {
      debugPrint('Error during initialization: $e');
      _errorMessage = 'Failed to initialize app: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Sign in anonymously to get a token for Edge Function calls
  Future<void> _signInAnonymously() async {
    try {
      _authToken = await _supabaseService.signInAnonymously();
      if (_authToken != null) {
        debugPrint('Signed in anonymously with token');
      } else {
        debugPrint('Failed to sign in anonymously');
      }
    } catch (e) {
      debugPrint('Error signing in anonymously: $e');
      // Continue without auth token, some functionality will be limited
    }
  }
  
  // Change the current step
  void setStep(int step) {
    _currentStep = step;
    notifyListeners();
  }
  
  // Select a hanbok preset
  void selectHanbokPreset(HanbokImage preset) {
    _selectedHanbokPreset = preset;
    notifyListeners();
  }
  
  // Pick and set source image
  Future<void> pickSourceImage() async {
    // If not authenticated, try to sign in anonymously first
    if (!isAuthenticated) {
      await _signInAnonymously();
      if (!isAuthenticated) {
        _errorMessage = "Authentication required to upload images.";
        notifyListeners();
        return;
      }
    }
    
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedImage != null) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      try {
        // Read image bytes
        final imageBytes = await pickedImage.readAsBytes();
        final contentType = 'image/jpeg'; // Adjust based on actual type if needed
        
        // Store temporary local reference for UI preview
        if (kIsWeb) {
          _sourceXFile = pickedImage;
        } else {
          _sourceImage = File(pickedImage.path);
          debugPrint('Selected image: ${pickedImage.path}');
        }
        
        // Upload to Supabase via Edge Function
        if (_authToken != null) {
          final result = await _supabaseService.uploadUserImage(
            imageBytes,
            contentType,
            _authToken!
          );
          
          if (result['success'] == true && result['image'] != null) {
            // 만료 기간이 있는 Presigned URL 사용
            _sourceImageUrl = result['image']['image_url'];
            
            // 백업 URL 정보 저장
            _publicBackupUrl = result['image']['public_url'];
            
            // 백업 URL 정보 로깅 (디버깅용)
            final expiresAt = result['image']['expires_at'];
            
            debugPrint('Image uploaded to Supabase');
            debugPrint('Signed URL (expires ${expiresAt}): $_sourceImageUrl');
            debugPrint('Public URL (backup): $_publicBackupUrl');
            
            // 만료 시간 정보 저장 (나중에 만료 확인용)
            _storageExpiry = DateTime.parse(expiresAt);
          } else {
            throw Exception('Failed to upload image: ${result['error'] ?? 'Unknown error'}');
          }
        } else {
          throw Exception('Authentication token required for image upload');
        }
      } catch (e) {
        debugPrint('Error handling picked image: $e');
        _errorMessage = 'Failed to process image: $e';
        
        // Keep the local reference for preview even if upload fails
        if (kIsWeb) {
          // For web, use the XFile path as URL (limited functionality)
          _sourceImageUrl = pickedImage.path;
        }
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }
  
  // 이미지 URL이 만료되었는지 확인하고 필요한 경우 백업 URL 반환
  String? getValidImageUrl() {
    // URL이 없으면 null 반환
    if (_sourceImageUrl == null) return null;
    
    // 만료 시간이 없거나 미래인 경우 서명된 URL 사용
    if (_storageExpiry == null || _storageExpiry!.isAfter(DateTime.now())) {
      return _sourceImageUrl;
    }
    
    // 만료된 경우 백업 URL 사용
    debugPrint('Signed URL has expired, using backup public URL');
    return _publicBackupUrl;
  }
  
  // Generate result image
  Future<void> generateResultImage() async {
    if (_sourceImage == null && _sourceImageUrl == null) {
      _errorMessage = "Please upload a photo.";
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      String sourcePath;
      String targetPath;
      
      // Use the valid Supabase URL if available, otherwise use the local file path
      final validUrl = getValidImageUrl();
      sourcePath = validUrl ?? _sourceImage!.path;
      
      // Selected hanbok preset's image path
      if (_selectedHanbokPreset == null) {
        _errorMessage = "Please select a Hanbok design.";
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      targetPath = _selectedHanbokPreset!.imagePath;
      
      debugPrint("Using source path: $sourcePath");
      debugPrint("Using target path: $targetPath");
      
      // Call the inference service to generate the image
      final result = await _hanbokService.generateHanbokImage(
        sourcePath,
        targetPath
      );
      
      if (result != null) {
        // If we got an immediate result (cached), use it directly
        _resultImagePath = result;
        // Move to the result step
        _currentStep = 2;
      } else {
        // Otherwise, this indicates a task was submitted and we need to poll for results
        // Move to the result step which will handle polling
        _currentStep = 2;
      }
    } catch (e) {
      _errorMessage = "Error generating image: $e";
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Poll for task results
  Future<void> pollTaskResults() async {
    try {
      final inferenceService = _hanbokService.getInferenceService();
      final taskIds = inferenceService.taskIds;
      
      if (taskIds.isEmpty) {
        debugPrint('No task IDs available to poll');
        return;
      }
      
      // We'll only check the latest task submitted
      final latestTaskId = taskIds.last;
      debugPrint('Polling for task ID: $latestTaskId');
      
      final result = await inferenceService.checkTaskStatus(latestTaskId);
      debugPrint('Poll result: ${result.toString()}');
      
      if (result['status'] == 'completed' && result['image_url'] != null) {
        // Add a cache-busting timestamp to the URL
        String imageUrl = result['image_url'];
        if (!imageUrl.contains('?')) {
          imageUrl = '$imageUrl?t=${DateTime.now().millisecondsSinceEpoch}';
        } else {
          imageUrl = '$imageUrl&t=${DateTime.now().millisecondsSinceEpoch}';
        }
        
        debugPrint('Task completed! Image URL with cache buster: $imageUrl');
        
        // Verify if the image is accessible before updating UI
        try {
          final response = await http.head(Uri.parse(imageUrl));
          debugPrint('Image URL validation status: ${response.statusCode}');
          
          if (response.statusCode >= 200 && response.statusCode < 300) {
            debugPrint('Image URL is valid and accessible');
            _resultImagePath = imageUrl;
            _isLoading = false;
            notifyListeners();
            debugPrint('State updated with result image path');
          } else {
            debugPrint('Image URL returned error status ${response.statusCode}, retrying...');
            // Try an alternative way - add metadata to URL or retry with original URL
            final originalUrl = result['image_url'];
            _resultImagePath = originalUrl;
            _isLoading = false;
            notifyListeners();
          }
        } catch (validateError) {
          debugPrint('Error validating image URL: $validateError');
          // Still use the URL despite validation error
          _resultImagePath = imageUrl;
          _isLoading = false;
          notifyListeners();
        }
      } else if (result['status'] == 'error') {
        debugPrint('Task error: ${result['error_message']}');
        _errorMessage = result['error_message'] ?? 'An error occurred during image generation';
        _isLoading = false;
        notifyListeners();
      } else {
        debugPrint('Task still processing. Status: ${result['status']}');
      }
      // If still processing, continue polling
    } catch (e) {
      _errorMessage = "Error checking task status: $e";
      _isLoading = false;
      debugPrint(_errorMessage);
      notifyListeners();
    }
  }
  
  // Reset the state to start over
  void reset() {
    _currentStep = 0;
    _selectedHanbokPreset = null;
    _sourceImage = null;
    _sourceXFile = null;
    _sourceImageUrl = null;
    _publicBackupUrl = null;
    _storageExpiry = null;
    _resultImagePath = null;
    _errorMessage = null;
    notifyListeners();
  }
} 