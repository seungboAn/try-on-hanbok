import 'package:flutter/material.dart';
import 'package:try_on_hanbok/widgets/header.dart';
import 'package:try_on_hanbok/widgets/result_section.dart';
import 'package:try_on_hanbok/constants/exports.dart';
import 'package:provider/provider.dart';
import 'package:supabase_services/hanbok_state.dart';

class ResultPage extends StatelessWidget {
  const ResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    bool isMobile = AppSizes.isMobile(context);
    final hanbokState = context.watch<HanbokState>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            children: [
              // 헤더
              const Header(),
              SizedBox(height: AppSizes.getHeaderBottomPadding(context)),

              // 결과 섹션 (모든 기능을 포함)
              const ResultSection(),

              // 하단 여백
              SizedBox(height: AppSizes.getFooterPadding(context)),
            ],
          ),
        ),
      ),
    );
  }
}
