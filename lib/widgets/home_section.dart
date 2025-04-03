import 'package:flutter/material.dart';
import 'package:test02/constants/exports.dart';

class HomeSection extends StatelessWidget {
  const HomeSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isDesktop = AppSizes.isDesktop(context);

    // 데스크탑과 모바일/태블릿의 레이아웃을 분리
    return isDesktop
        ? _buildDesktopLayout(context)
        : _buildMobileTabletLayout(context);
  }

  // 데스크탑 레이아웃 (기존 레이아웃 유지)
  Widget _buildDesktopLayout(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 900,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/landing_image.png'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          left: 100,
          top: 200,
          bottom: 100,
          right: 100,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 740),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // First text
                  Container(
                    width: 740,
                    child: Text(
                      'We create your own special moments.',
                      style: AppTextStyles.headline1(context).copyWith(
                        color: AppColors.background,
                        shadows: [
                          BoxShadow(
                            color: AppColors.shadowColor,
                            blurRadius: 4,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      softWrap: false,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Second text
                  Container(
                    width: 720,
                    child: Text(
                      'Experience the beauty of Hanbok.',
                      style: AppTextStyles.headline1(context).copyWith(
                        color: AppColors.background,
                        fontSize: AppTextStyles.headline2(context).fontSize,
                        shadows: [
                          BoxShadow(
                            color: AppColors.shadowColor,
                            blurRadius: 4,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      softWrap: false,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // 데스크탑 모드에서는 원래 간격(30px) 유지
                  const SizedBox(height: 30),

                  // Try On Button
                  _buildTryOnButton(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 모바일/태블릿 레이아웃 (우측 이미지와 같은 모습)
  Widget _buildMobileTabletLayout(BuildContext context) {
    bool isMobile = AppSizes.isMobile(context);
    bool isTablet = AppSizes.isTablet(context);

    return Container(
      width: double.infinity,
      height: isMobile ? 400 : 600,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/landing_image.png'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      // 텍스트와 버튼이 하단에 오도록 정렬 (태블릿 및 모바일)
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 컨텐츠를 담을 컨테이너 - 아래쪽 패딩 추가
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(bottom: isMobile ? 40 : 60),
            child: Column(
              children: [
                // First text
                Container(
                  width: double.infinity,
                  child: Text(
                    'We create your own special moments.',
                    style: AppTextStyles.headline1(context).copyWith(
                      color: AppColors.background,
                      shadows: [
                        BoxShadow(
                          color: AppColors.shadowColor,
                          blurRadius: 4,
                          offset: const Offset(2, 2),
                        ),
                      ],
                      // 모바일/태블릿에서 더 작은 텍스트 크기 적용
                      fontSize:
                          isMobile
                              ? 22
                              : (isTablet ? 32 : null), // 모바일은 더 작게, 태블릿은 중간 크기
                    ),
                    softWrap: false,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 8),

                // Second text
                Container(
                  width: double.infinity,
                  child: Text(
                    'Experience the beauty of Hanbok.',
                    style: AppTextStyles.headline1(context).copyWith(
                      color: AppColors.background,
                      // 모바일/태블릿에서 더 작은 텍스트 크기 적용
                      fontSize:
                          isMobile
                              ? 16
                              : (isTablet ? 22 : null), // 모바일은 더 작게, 태블릿은 중간 크기
                      shadows: [
                        BoxShadow(
                          color: AppColors.shadowColor,
                          blurRadius: 4,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    softWrap: false,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                ),

                // 모바일에서만 15px, 태블릿에서는 원래 간격(30px) 유지
                SizedBox(height: isMobile ? 15 : 30),

                // Try On Button
                _buildTryOnButton(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Try On 버튼 (코드 중복 방지)
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
                  // Navigate to generate page with preselected hanbok
                  Navigator.pushNamed(
                    context,
                    AppConstants.generateRoute,
                    arguments: AppConstants.modernHanbokList[0], // 최상단 프리셋 이미지
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
