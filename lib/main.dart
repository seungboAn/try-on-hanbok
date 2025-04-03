import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:test02/pages/home_page.dart';
import 'package:test02/pages/generate_page.dart';
import 'package:test02/pages/result_page.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:test02/constants/exports.dart';
import 'package:provider/provider.dart';
import 'package:supabase_services/hanbok_state.dart';
import 'package:supabase_services/supabase_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase services
  await SupabaseServices.initialize();
  
  configureApp();
  runApp(const MyApp());
}

void configureApp() {
  setUrlStrategy(PathUrlStrategy());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HanbokState()..initialize(),
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme.copyWith(
          textTheme: AppTextStyles.getTextTheme(),
          useMaterial3: true,
        ),
        builder: AppResponsive.responsiveBuilder,
        initialRoute: AppConstants.homeRoute,
        routes: {AppConstants.homeRoute: (context) => const HomePage()},
        onGenerateRoute: (settings) {
          if (settings.name == AppConstants.generateRoute) {
            // 선택된 한복 이미지 가져오기
            final selectedHanbok = settings.arguments as String?;

            return MaterialPageRoute(
              builder: (context) => GeneratePage(selectedHanbok: selectedHanbok),
            );
          }

          if (settings.name == AppConstants.resultRoute) {
            return MaterialPageRoute(builder: (context) => const ResultPage());
          }

          // 기본 홈 라우트
          return MaterialPageRoute(builder: (context) => const HomePage());
        },
      ),
    );
  }
}
