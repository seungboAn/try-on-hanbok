import 'package:flutter/material.dart';
import 'package:try_on_hanbok/widgets/header.dart';
import 'package:try_on_hanbok/widgets/generate_section.dart';
import 'package:try_on_hanbok/constants/exports.dart';
import 'package:provider/provider.dart';
import 'package:supabase_services/hanbok_state.dart';

// StatefulWidget으로 변경하여 스크롤 컨트롤러 관리
class GeneratePage extends StatefulWidget {
  final String? selectedHanbok;

  const GeneratePage({super.key, this.selectedHanbok});

  @override
  State<GeneratePage> createState() => _GeneratePageState();
}

class _GeneratePageState extends State<GeneratePage> {
  // 스크롤 컨트롤러 추가
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // 디버그 로그 추가
    debugPrint('GeneratePage initState 실행, 선택된 한복: ${widget.selectedHanbok}');

    // 페이지 초기화 시 HanbokState 상태 확인 및 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final hanbokState = context.read<HanbokState>();

      // HanbokState가 비어있는 경우 초기화
      if (hanbokState.modernPresets.isEmpty ||
          hanbokState.traditionalPresets.isEmpty) {
        debugPrint('GeneratePage: HanbokState가 비어있어 초기화 시작');
        await hanbokState.initialize();
        debugPrint(
          'GeneratePage: HanbokState 초기화 완료 - Modern: ${hanbokState.modernPresets.length}, '
          'Traditional: ${hanbokState.traditionalPresets.length}',
        );
      } else {
        debugPrint(
          'GeneratePage: HanbokState가 이미 초기화되어 있음 - Modern: ${hanbokState.modernPresets.length}, '
          'Traditional: ${hanbokState.traditionalPresets.length}',
        );
      }
    });
  }

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
