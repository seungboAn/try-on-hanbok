import 'package:flutter/material.dart';
import 'package:try_on_hanbok/widgets/header.dart';
import 'package:try_on_hanbok/widgets/home_section.dart';
import 'package:try_on_hanbok/widgets/best_section.dart';
import 'package:try_on_hanbok/widgets/tutorial_section.dart';
import 'package:try_on_hanbok/constants/exports.dart';
import 'package:provider/provider.dart';
import 'package:supabase_services/hanbok_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    bool isMobile = AppSizes.isMobile(context);

    // HanbokState 확인 (listen: true로 변경 상태 감지)
    final hanbokState = Provider.of<HanbokState>(context);
    final bool isLoading = hanbokState.isLoading;
    final bool hasPresets =
        hanbokState.modernPresets.isNotEmpty ||
        hanbokState.traditionalPresets.isNotEmpty;

    // 초기화가 안 되어있으면 다시 시도
    if (!isLoading && !hasPresets) {
      debugPrint('홈페이지: HanbokState가 비어있습니다. 초기화를 다시 시도합니다.');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        hanbokState.initialize();
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            // 헤더
            const Header(),
            SizedBox(height: AppSizes.getHeaderBottomPadding(context)),

            // 홈 섹션
            const HomeSection(),
            SizedBox(height: AppSizes.getSection1BottomPadding(context)),

            // 베스트 섹션 (이미지 선택과 페이지 이동 로직을 내부에서 처리)
            Padding(
              padding: AppSizes.getScreenPadding(context),
              child:
                  isLoading
                      ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 50),
                          child: Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 20),
                              Text('Loading Images...'),
                            ],
                          ),
                        ),
                      )
                      : const BestSection(),
            ),
            SizedBox(height: AppSizes.getSection2BottomPadding(context)),

            // 튜토리얼 섹션
            const TutorialSection(),

            // 하단 여백
            SizedBox(height: AppSizes.getFooterPadding(context)),
          ],
        ),
      ),
    );
  }
}
