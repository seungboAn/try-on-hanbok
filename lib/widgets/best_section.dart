import 'package:flutter/material.dart';
import 'package:test02/widgets/select_section.dart';
import 'package:test02/constants/exports.dart';

class BestSection extends StatelessWidget {
  final Future<void> Function(String)? onImageClick;
  final String? filter;

  const BestSection({Key? key, this.onImageClick, this.filter})
    : super(key: key);

  // 이미지 클릭 핸들러
  Future<void> _handleImageClick(BuildContext context, String imagePath) async {
    // 외부에서 제공된 콜백이 있으면 그것을 사용
    if (onImageClick != null) {
      await onImageClick!(imagePath);
      return;
    }

    // 내부 처리 로직
    // 해당 이미지를 선택한 상태로 GeneratePage로 이동
    Navigator.pushNamed(
      context,
      AppConstants.generateRoute,
      arguments: imagePath, // 클릭한 이미지의 경로를 전달
    );
  }

  @override
  Widget build(BuildContext context) {
    // SelectSection을 사용하되, showFilterButtons를 false로 설정하여 필터 버튼을 숨김
    return SelectSection(
      onImageClick: (imagePath) async => await _handleImageClick(context, imagePath),
      showFilterButtons: false, // Best Section은 필터 버튼을 표시하지 않음
    );
  }
}
