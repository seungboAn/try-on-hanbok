library supabase_services;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants/supabase_config.dart';
import 'services/env_service.dart';
import 'services/supabase_service.dart';
import 'services/inference_service.dart';

export 'models/hanbok_image.dart';
export 'services/supabase_service.dart';
export 'services/inference_service.dart';
export 'constants/supabase_config.dart';

/// Main class for Supabase Services
class SupabaseServices {
  /// Initialize Supabase services
  static Future<void> initialize() async {
    // Load environment variables
    final envService = EnvService();
    await envService.load();
    
    // Get Supabase URL and anon key
    final supabaseUrl = SupabaseConfig.supabaseUrl;
    final supabaseAnonKey = SupabaseConfig.supabaseAnonKey;
    
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      debugPrint('Warning: Missing Supabase credentials');
      return;
    }
    
    // Initialize Supabase
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: kDebugMode,
    );
    
    debugPrint('Supabase initialized successfully');
  }
  
  /// Get the Supabase service instance
  static SupabaseService get supabaseService => SupabaseService();
  
  /// Get the inference service instance
  static InferenceService get inferenceService => InferenceService();
  
  /// Get the Supabase client
  static SupabaseClient get supabaseClient => Supabase.instance.client;
  
  /// Check if Supabase is initialized
  static bool get isInitialized {
    try {
      Supabase.instance.client;
      return true;
    } catch (e) {
      return false;
    }
  }
} 