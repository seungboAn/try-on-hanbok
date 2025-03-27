import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants/app_constants.dart';
import 'screens/index_screen.dart';
import 'screens/photo_upload_screen.dart';
import 'screens/result_screen.dart';
import 'services/app_state.dart';
import 'services/env_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  final envService = EnvService();
  await envService.load();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: envService.supabaseUrl,
    anonKey: envService.supabaseAnonKey,
    debug: true,
  );
  
  // Initialize app state
  final appState = AppState();
  await appState.initialize();
  
  runApp(
    provider.ChangeNotifierProvider.value(
      value: appState,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hanbok Virtual Fitting',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppConstants.primaryColor,
        scaffoldBackgroundColor: AppConstants.backgroundColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.primaryColor,
          primary: AppConstants.primaryColor,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const HanbokVirtualFittingApp(),
    );
  }
}

class HanbokVirtualFittingApp extends StatelessWidget {
  const HanbokVirtualFittingApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = provider.Provider.of<AppState>(context);
    
    // Choose which screen to display based on the current step
    switch (appState.currentStep) {
      case 0:
        return const IndexScreen();
      case 1:
        return const PhotoUploadScreen();
      case 2:
        return const ResultScreen();
      default:
        return const IndexScreen();
    }
  }
} 