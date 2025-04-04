import 'package:flutter/material.dart';
import 'package:try_on_hanbok/widgets/select_section.dart';

class BestSection extends StatelessWidget {
  final Future<void> Function(String)? onImageClick;
  final String? filter;

  const BestSection({super.key, this.onImageClick, this.filter});

  @override
  Widget build(BuildContext context) {
    // 통합된 SelectSection을 사용하고 isBestMode=true로 설정하여 BestSection 역할을 수행하도록 함
    return SelectSection(
      onImageClick: onImageClick, // 외부에서 제공된 콜백이 있으면 그대로 전달
      showFilterButtons: false, // 필터 버튼을 표시하지 않음
      isBestMode: true, // BestSection 모드 활성화
      defaultFilter: filter, // 필터 값을 전달 (있는 경우)
    );
  }
}
