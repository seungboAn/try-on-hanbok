import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';

class TutorialSection extends StatelessWidget {
  const TutorialSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.background,
      child: Column(
        children: [
          const SizedBox(height: AppConstants.spacingLarge),
          Text(
            AppConstants.tutorialTitle,
            style: AppTextStyles.headline1(context),
          ),
          const SizedBox(height: 20),
          _buildTutorialSteps(context),
          const SizedBox(height: AppConstants.spacingLarge),
          _buildFooter(context),
          const SizedBox(height: AppConstants.spacingLarge),
        ],
      ),
    );
  }

  // 튜토리얼 스텝 3개를 구성합니다
  Widget _buildTutorialSteps(BuildContext context) {
    // 디바이스 크기에 따라 다른 레이아웃 적용
    bool isMobile = AppSizes.isMobile(context);
    bool isTablet = AppSizes.isTablet(context);

    if (isMobile) {
      // 모바일에서는 세로로 3개 나열
      return Column(
        children: [
          _buildTutorialStep(
            context,
            AppConstants.tutorialStep1Title,
            AppConstants.tutorialStep1Description,
            AppConstants.tutorialStep1Image,
          ),
          const SizedBox(height: 20),
          _buildTutorialStep(
            context,
            AppConstants.tutorialStep2Title,
            AppConstants.tutorialStep2Description,
            AppConstants.tutorialStep2Image,
          ),
          const SizedBox(height: 20),
          _buildTutorialStep(
            context,
            AppConstants.tutorialStep3Title,
            AppConstants.tutorialStep3Description,
            AppConstants.tutorialStep3Image,
          ),
        ],
      );
    } else if (isTablet) {
      // 태블릿에서는 2개는 한 줄에, 1개는 아래 중앙에
      return Column(
        children: [
          // 상단 2개 이미지
          Row(
            children: [
              Expanded(
                child: _buildTutorialStep(
                  context,
                  AppConstants.tutorialStep1Title,
                  AppConstants.tutorialStep1Description,
                  AppConstants.tutorialStep1Image,
                ),
              ),
              Expanded(
                child: _buildTutorialStep(
                  context,
                  AppConstants.tutorialStep2Title,
                  AppConstants.tutorialStep2Description,
                  AppConstants.tutorialStep2Image,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 하단 1개 이미지 (중앙 정렬)
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.5, // 화면 너비의 50%
            child: _buildTutorialStep(
              context,
              AppConstants.tutorialStep3Title,
              AppConstants.tutorialStep3Description,
              AppConstants.tutorialStep3Image,
            ),
          ),
        ],
      );
    } else {
      // 데스크탑에서는 3개 모두 한 줄에
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: _buildTutorialStep(
              context,
              AppConstants.tutorialStep1Title,
              AppConstants.tutorialStep1Description,
              AppConstants.tutorialStep1Image,
            ),
          ),
          Expanded(
            child: _buildTutorialStep(
              context,
              AppConstants.tutorialStep2Title,
              AppConstants.tutorialStep2Description,
              AppConstants.tutorialStep2Image,
            ),
          ),
          Expanded(
            child: _buildTutorialStep(
              context,
              AppConstants.tutorialStep3Title,
              AppConstants.tutorialStep3Description,
              AppConstants.tutorialStep3Image,
            ),
          ),
        ],
      );
    }
  }

  // 튜토리얼 하단 섹션
  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMedium),
      child: Column(
        children: [
          Text(
            AppConstants.tutorialFooter,
            style: AppTextStyles.body1(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingMedium),
          _buildTryOnButton(context),
        ],
      ),
    );
  }

  Widget _buildTutorialStep(
    BuildContext context,
    String title,
    String description,
    String imagePath,
  ) {
    bool isMobile = AppSizes.isMobile(context);
    bool isTablet = AppSizes.isTablet(context);

    // 고정 너비 대신 패딩으로 조정
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image - 화면 크기에 맞게 비율 유지하도록 설정
          AspectRatio(
            aspectRatio: 1.35, // 이미지 비율 (가로:세로 = 4:3)
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  AppConstants.defaultCardBorderRadius,
                ),
                image: DecorationImage(
                  image: AssetImage(imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Title
          Text(title, style: AppTextStyles.headline3(context)),
          const SizedBox(height: 10),
          // Description
          Text(
            description,
            style: AppTextStyles.body1(
              context,
            ).copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadStep(BuildContext context) {
    bool isMobile = AppSizes.isMobile(context);
    double containerWidth = isMobile ? 300 : 411;

    return Container(
      width: containerWidth,
      height: 465,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Step 2 UI
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background elements
                Container(
                  color: AppColors.background,
                  margin: const EdgeInsets.all(20),
                ),

                // Upload circle
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.border,
                          width: 2,
                          style: BorderStyle.none,
                        ),
                      ),
                      child: CustomPaint(
                        painter: DashedCircleBorderPainter(
                          color: AppColors.border,
                          strokeWidth: 2.0,
                          dashWidth: 4.0,
                          dashSpace: 4.0,
                        ),
                        child: const Center(
                          child: Text(
                            '+',
                            style: TextStyle(
                              fontSize: 60,
                              color: AppColors.border,
                              height: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'your image',
                      style: TextStyle(
                        fontSize: 20,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Title
          const Text(
            'Step 2 Upload your faces',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          // Description
          const Text(
            'Upload your face image, and you can change it to a different photo anytime.',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTryOnButton(BuildContext context) {
    bool isMobile = AppSizes.isMobile(context);
    bool isTablet = AppSizes.isTablet(context);

    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;

        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: AnimatedContainer(
            duration: AppConstants.defaultAnimationDuration,
            width: AppSizes.getButtonWidth(context),
            height: AppSizes.getButtonHeight(context),
            decoration: BoxDecoration(
              color: isHovered ? AppColors.buttonHover : AppColors.background,
              borderRadius: BorderRadius.circular(
                AppConstants.defaultButtonBorderRadius,
              ),
              border: Border.all(
                color: isHovered ? AppColors.primary : AppColors.border,
                width:
                    isHovered
                        ? AppConstants.borderWidthThick
                        : AppConstants.borderWidthThin,
              ),
              boxShadow:
                  isHovered
                      ? [
                        BoxShadow(
                          color: AppColors.shadowColor,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                      : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(
                  AppConstants.defaultButtonBorderRadius,
                ),
                onTap: () {
                  // Navigate to generate page with first preset hanbok image
                  Navigator.pushNamed(
                    context,
                    AppConstants.generateRoute,
                    arguments: AppConstants.modernHanbokList[0],
                  );
                },
                child: Center(
                  child: Text(
                    AppConstants.tutorialButtonText,
                    style: AppTextStyles.button(context).copyWith(
                      color:
                          isHovered
                              ? AppColors.textButton
                              : AppColors.textPrimary,
                      fontWeight:
                          isHovered ? FontWeight.bold : FontWeight.normal,
                      // 모바일/태블릿에서 버튼 텍스트 크기 조정
                      fontSize: isMobile ? 14 : (isTablet ? 16 : null),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class DashedCircleBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  DashedCircleBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Paint paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;

    double dashCount = (2 * radius * 3.14159) / (dashWidth + dashSpace);
    double angle = (dashWidth + dashSpace) / radius;
    double startAngle = 0;

    for (int i = 0; i < dashCount.floor(); i++) {
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(radius, radius),
          radius: radius - (strokeWidth / 2),
        ),
        startAngle,
        dashWidth / radius,
        false,
        paint,
      );
      startAngle += angle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
