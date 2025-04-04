import 'package:flutter/material.dart';
import 'package:try_on_hanbok/pages/home_page.dart';
import 'package:try_on_hanbok/pages/generate_page.dart';
import 'package:try_on_hanbok/pages/result_page.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:try_on_hanbok/constants/exports.dart';
import 'package:provider/provider.dart';
import 'package:supabase_services/hanbok_state.dart';
import 'package:supabase_services/supabase_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase services
  await SupabaseServices.initialize();

  // HankbokState 인스턴스 미리 생성하고 초기화 시작
  final hanbokState = HanbokState();
  hanbokState.initialize(); // 백그라운드에서 초기화 시작

  configureApp();
  runApp(MyApp(hanbokState: hanbokState));
}

void configureApp() {
  setUrlStrategy(PathUrlStrategy());
}

class MyApp extends StatelessWidget {
  final HanbokState hanbokState;

  const MyApp({super.key, required this.hanbokState});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: hanbokState, // 이미 초기화를 시작한 인스턴스 사용
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme.copyWith(
          textTheme: AppTextStyles.getTextTheme(),
        ),
        builder: AppResponsive.responsiveBuilder,
        initialRoute: AppConstants.homeRoute,
        routes: {AppConstants.homeRoute: (context) => const HomePage()},
        onGenerateRoute: (settings) {
          if (settings.name == AppConstants.generateRoute) {
            // 선택된 한복 이미지 가져오기
            final selectedHanbok = settings.arguments as String?;

            return MaterialPageRoute(
              builder:
                  (context) => GeneratePage(selectedHanbok: selectedHanbok),
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
