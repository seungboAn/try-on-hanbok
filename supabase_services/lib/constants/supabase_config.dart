import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  // Supabase project URL and anon key
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? 'YOUR_SUPABASE_URL';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? 'YOUR_SUPABASE_ANON_KEY';
  
  // Edge Function endpoints
  static String get uploadUserImageEndpoint => '$supabaseUrl/functions/v1/upload-user-image';
  static String get getPresetImagesEndpoint => '$supabaseUrl/functions/v1/get-presets';
  static String get generateHanbokImageEndpoint => '$supabaseUrl/functions/v1/generate-hanbok-image';
  static String get checkStatusEndpoint => '$supabaseUrl/functions/v1/check-status';
  
  // Storage bucket paths
  static const String userImagesBucket = 'user-images';
  static const String presetImagesBucket = 'preset-images';
  static const String resultImagesBucket = 'result-images';
} 