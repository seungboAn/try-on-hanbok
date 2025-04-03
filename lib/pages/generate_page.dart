import 'package:flutter/material.dart';
import 'package:test02/widgets/header.dart';
import 'package:test02/widgets/generate_section.dart';
import 'package:test02/constants/exports.dart';

// StatefulWidget으로 변경하여 스크롤 컨트롤러 관리
class GeneratePage extends StatefulWidget {
  final String? selectedHanbok;

  const GeneratePage({Key? key, this.selectedHanbok}) : super(key: key);

  @override
  State<GeneratePage> createState() => _GeneratePageState();
}

class _GeneratePageState extends State<GeneratePage> {
  // 스크롤 컨트롤러 추가
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    // 컨트롤러 해제
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = AppSizes.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController, // 스크롤 컨트롤러 설정
          physics: const ClampingScrollPhysics(),
          child: Column(
            children: [
              // 헤더
              const Header(),
              SizedBox(height: AppSizes.getHeaderBottomPadding(context)),

              // GenerateSection (모든 기능을 포함)
              // 스크롤 컨트롤러 전달
              GenerateSection(
                selectedHanbokImage: widget.selectedHanbok,
                usePadding: true,
                externalScrollController: _scrollController,
              ),

              // 하단 여백
              SizedBox(height: AppSizes.getSection2BottomPadding(context)),
            ],
          ),
        ),
      ),
    );
  }
}
