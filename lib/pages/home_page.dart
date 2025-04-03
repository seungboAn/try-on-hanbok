import 'package:flutter/material.dart';
import 'package:test02/widgets/header.dart';
import 'package:test02/widgets/home_section.dart';
import 'package:test02/widgets/best_section.dart';
import 'package:test02/widgets/tutorial_section.dart';
import 'package:test02/constants/exports.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isMobile = AppSizes.isMobile(context);

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
              child: BestSection(),
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
