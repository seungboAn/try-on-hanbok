import 'package:flutter/material.dart';
import 'package:supabase_services/supabase_services.dart';
import 'package:provider/provider.dart';
import 'hanbok_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase services
  await SupabaseServices.initialize();
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => HanbokState()..initialize(),
      child: const MyApp(),
    ),
  );
}

// ... existing code ... 