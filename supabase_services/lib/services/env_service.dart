import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvService {
  static final EnvService _instance = EnvService._internal();
  factory EnvService() => _instance;
  EnvService._internal();

  // Use const String.fromEnvironment to access dart-define values
  static const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  Future<void> load() async {
    try {
      // Load .env file if available
      await dotenv.load();
    } catch (e) {
      debugPrint('Warning: Could not load .env file: $e');
    }

    // Use either the .env values or the dart-define values
    final url = supabaseUrl;
    final key = supabaseAnonKey;
    
    if (url.isEmpty || key.isEmpty) {
      debugPrint('Warning: Missing Supabase credentials - URL: $url, Key: $key');
    } else {
      debugPrint('Supabase credentials loaded successfully');
    }
  }

  String? get(String key) {
    // Try .env file first
    final envValue = dotenv.env[key];
    if (envValue != null && envValue.isNotEmpty) {
      return envValue;
    }
    
    // Try dart-define values
    if (key == 'SUPABASE_URL') return _supabaseUrl;
    if (key == 'SUPABASE_ANON_KEY') return _supabaseAnonKey;
    
    return null;
  }

  String getOrDefault(String key, String defaultValue) {
    return get(key) ?? defaultValue;
  }

  // Supabase specific getters
  String get supabaseUrl => get('SUPABASE_URL') ?? _supabaseUrl;
  String get supabaseAnonKey => get('SUPABASE_ANON_KEY') ?? _supabaseAnonKey;
} 