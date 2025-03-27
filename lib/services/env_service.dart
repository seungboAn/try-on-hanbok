import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvService {
  static final EnvService _instance = EnvService._internal();
  factory EnvService() => _instance;
  EnvService._internal();
  
  Future<void> load() async {
    try {
      await dotenv.load(fileName: '.env');
      debugPrint('Environment variables loaded: ${dotenv.env.length}');
    } catch (e) {
      debugPrint('Error loading environment variables: $e');
      // Create fallback environment variables for development
      dotenv.env['SUPABASE_URL'] = 'YOUR_SUPABASE_URL';
      dotenv.env['SUPABASE_ANON_KEY'] = 'YOUR_SUPABASE_ANON_KEY';
    }
  }
  
  String? get(String key) {
    return dotenv.env[key];
  }
  
  String getOrDefault(String key, String defaultValue) {
    return dotenv.env[key] ?? defaultValue;
  }
  
  // Supabase specific getters
  String get supabaseUrl => 
      getOrDefault('SUPABASE_URL', 'YOUR_SUPABASE_URL');
      
  String get supabaseAnonKey => 
      getOrDefault('SUPABASE_ANON_KEY', 'YOUR_SUPABASE_ANON_KEY');
} 