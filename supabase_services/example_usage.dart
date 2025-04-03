import 'package:flutter/material.dart';
import 'package:supabase_services/supabase_services.dart';
import 'dart:typed_data';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase services
  await SupabaseServices.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supabase Integration Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SupabaseExampleScreen(),
    );
  }
}

class SupabaseExampleScreen extends StatefulWidget {
  const SupabaseExampleScreen({Key? key}) : super(key: key);

  @override
  State<SupabaseExampleScreen> createState() => _SupabaseExampleScreenState();
}

class _SupabaseExampleScreenState extends State<SupabaseExampleScreen> {
  final _supabaseService = SupabaseServices.supabaseService;
  final _inferenceService = SupabaseServices.inferenceService;
  
  bool _isLoading = false;
  String? _authToken;
  List<HanbokImage> _presets = [];
  String? _resultImageUrl;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _initialize();
  }
  
  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    
    try {
      // Sign in anonymously
      _authToken = await _supabaseService.signInAnonymously();
      
      // Fetch presets
      _presets = await _supabaseService.getPresetImages();
    } catch (e) {
      _errorMessage = 'Error initializing: $e';
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _uploadImage(Uint8List imageBytes) async {
    setState(() => _isLoading = true);
    
    try {
      if (_authToken == null) {
        // Try to sign in again if needed
        _authToken = await _supabaseService.signInAnonymously();
      }
      
      if (_authToken != null) {
        // Upload the image
        final result = await _supabaseService.uploadUserImage(
          imageBytes,
          'image/jpeg',
          _authToken!
        );
        
        if (result['success'] == true && result['image'] != null) {
          final String sourceImageUrl = result['image']['image_url'];
          
          // Use the first preset for demonstration
          if (_presets.isNotEmpty) {
            final targetImageUrl = _presets.first.imagePath;
            
            // Generate fitting
            final resultUrl = await _inferenceService.generateHanbokFitting(
              sourcePath: sourceImageUrl,
              targetPath: targetImageUrl,
            );
            
            if (resultUrl != null) {
              // Got immediate result
              setState(() => _resultImageUrl = resultUrl);
            } else {
              // Need to poll for result
              _pollForResults();
            }
          }
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _pollForResults() async {
    if (_inferenceService.taskIds.isEmpty) return;
    
    final latestTaskId = _inferenceService.taskIds.last;
    
    try {
      final result = await _inferenceService.checkTaskStatus(latestTaskId);
      
      if (result['status'] == 'completed' && result['image_url'] != null) {
        setState(() => _resultImageUrl = result['image_url']);
      } else if (result['status'] == 'error') {
        setState(() => _errorMessage = result['error_message'] ?? 'An error occurred');
      } else {
        // Still processing, poll again after a delay
        Future.delayed(const Duration(seconds: 3), _pollForResults);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error checking status: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Integration Example'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }
  
  Widget _buildContent() {
    if (_errorMessage != null) {
      return Center(child: Text('Error: $_errorMessage'));
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_resultImageUrl != null) ...[
            Image.network(_resultImageUrl!),
            const SizedBox(height: 20),
          ],
          
          if (_presets.isNotEmpty) ...[
            Text('${_presets.length} presets loaded'),
            const SizedBox(height: 20),
          ],
          
          ElevatedButton(
            onPressed: _authToken == null
                ? null
                : () {
                    // In real app, you would pick an image here
                    // and call _uploadImage with the image bytes
                  },
            child: const Text('Select Image to Process'),
          ),
        ],
      ),
    );
  }
} 