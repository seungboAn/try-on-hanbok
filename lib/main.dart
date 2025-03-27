import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'services/hanbok_service.dart';
import 'state/app_state.dart';
import 'screens/index_screen.dart';
import 'screens/hanbok_selection_screen.dart';
import 'screens/photo_upload_screen.dart';
import 'screens/result_screen.dart';
import 'constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Preload hanbok images
  final hanbokService = HanbokService();
  await hanbokService.loadHanbokImages();
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VirtualHanbok',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.primaryColor,
        ),
        useMaterial3: true,
        fontFamily: AppConstants.fontFamily,
        scaffoldBackgroundColor: AppConstants.backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppConstants.backgroundColor,
          foregroundColor: AppConstants.textColor,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: AppConstants.fontFamily,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: AppConstants.textColor,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: AppConstants.primaryColor,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            textStyle: const TextStyle(
              fontFamily: AppConstants.fontFamily,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const IndexScreen(),
        '/hanbok-selection': (context) => const HanbokSelectionScreen(),
        '/photo-upload': (context) => const PhotoUploadScreen(),
        '/result': (context) => const ResultScreen(),
      },
    );
  }
}