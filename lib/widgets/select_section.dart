import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'dart:math' as math;
import 'package:test02/constants/exports.dart';
import 'package:provider/provider.dart';
import 'package:supabase_services/hanbok_state.dart';
import 'package:supabase_services/models/hanbok_image.dart';

class SelectSection extends StatefulWidget {
  // 이미지 클릭 이벤트 핸들러
  final Future<void> Function(String)? onImageClick;
  // 필터 변경 이벤트 핸들러
  final Function(String?)? onFilterChange;
  // 필터 버튼 표시 여부
  final bool showFilterButtons; // 필터 버튼 표시 여부 (자식 BestSection에서 false로 설정)
  // 상위 컴포넌트의 스크롤 컨트롤러
  final ScrollController? parentScrollController;
  // 현재 선택된 이미지
  final String? selectedImage;

  const SelectSection({
    Key? key,
    this.onImageClick,
    this.onFilterChange,
    this.showFilterButtons = true, // 기본값은 표시함
    this.parentScrollController,
    this.selectedImage,
  }) : super(key: key);

  @override
  State<SelectSection> createState() => _SelectSectionState();
}

class _SelectSectionState extends State<SelectSection> {
  String? activeFilter;

  // 롤오버 상태를 위한 맵 (인덱스를 키로 사용)
  final Map<String, bool> hoverStates = {};
  // 필터 버튼 롤오버 상태
  final Map<String, bool> filterHoverStates = {};

  // 더보기 버튼 상태
  bool showMoreImages = false;
  // 롤오버 상태
  bool isMoreButtonHovered = false;

  // 캐싱된 이미지 목록
  List<String>? _cachedModernImages;
  List<String>? _cachedTraditionalImages;
  List<String>? _cachedArrangedImages;

  final List<int> clickCounts = List.filled(16, 0); // 클릭 카운트

  // 스크롤 컨트롤러 추가
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollController.addListener(() {});
      }
    });
  }

  @override
  void dispose() {
    // 스크롤 컨트롤러 해제
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SelectSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 선택된 이미지가 변경된 경우 UI 업데이트 필요
    if (widget.selectedImage != oldWidget.selectedImage) {
      setState(() {});
    }
    
    // 부모 스크롤 컨트롤러가 변경된 경우
    if (widget.parentScrollController != oldWidget.parentScrollController) {
      // 필요한 경우 여기서 처리
    }
    
    // onFilterChange 콜백이 변경된 경우
    if (widget.onFilterChange != oldWidget.onFilterChange) {
      // 필요한 경우 여기서 처리
    }
  }
  
  // HanbokState가 갱신될 때마다 캐시를 초기화하는 메서드 (새로운 프리셋 이미지가 로드되었을 수 있음)
  void _resetCache() {
    _cachedModernImages = null;
    _cachedTraditionalImages = null;
    _cachedArrangedImages = null;
  }

  // 이미지 리스트는 HanbokState에서 가져오기 (캐싱 적용)
  List<String> getModernImageList(HanbokState hanbokState) {
    if (_cachedModernImages != null) {
      return _cachedModernImages!;
    }
    final modernImages = hanbokState.modernPresets.map((preset) => preset.imagePath).toList();
    _cachedModernImages = modernImages;
    return modernImages;
  }
  
  List<String> getTraditionalImageList(HanbokState hanbokState) {
    if (_cachedTraditionalImages != null) {
      return _cachedTraditionalImages!;
    }
    final traditionalImages = hanbokState.traditionalPresets.map((preset) => preset.imagePath).toList();
    _cachedTraditionalImages = traditionalImages;
    return traditionalImages;
  }

  // 최상단으로 스크롤
  void _scrollToTop() {
    // 부모 컴포넌트의 스크롤 컨트롤러가 있으면 사용
    if (widget.parentScrollController != null &&
        widget.parentScrollController!.hasClients) {
      widget.parentScrollController!.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      return;
    }

    // 부모 컨트롤러가 없으면 PrimaryScrollController 사용
    final scrollController = PrimaryScrollController.of(context);
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  // 필터링된 이미지 목록 반환 (최적화)
  List<String> getFilteredImages() {
    final hanbokState = context.watch<HanbokState>();
    
    // 로딩 중이거나 초기화되지 않은 경우 빈 배열 반환
    if (hanbokState.isLoading || 
        (hanbokState.modernPresets.isEmpty && hanbokState.traditionalPresets.isEmpty)) {
      return [];
    }
    
    // 필터에 따라 이미지 목록 반환 (이미 캐싱된 리스트 사용)
    if (activeFilter == AppConstants.filterModern) {
      return getModernImageList(hanbokState);
    } else if (activeFilter == AppConstants.filterTraditional) {
      return getTraditionalImageList(hanbokState);
    }
    
    // 필터가 없는 경우에는 _getArrangedImages에서 모던+전통 배열을 처리하므로
    // 여기서는 단순히 두 리스트를 합치기만 함
    return [
      ...getModernImageList(hanbokState),
      ...getTraditionalImageList(hanbokState)
    ];
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = AppSizes.isMobile(context);
    bool isTablet = AppSizes.isTablet(context);
    bool isDesktop = AppSizes.isDesktop(context);

    return Column(
      children: [
        // Filter buttons - showFilterButtons가 true일 때만 표시
        if (widget.showFilterButtons)
          Padding(
            padding: EdgeInsets.only(
              bottom: 20, // AppSizes.getSectionSpacing(context) / 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFilterButton(AppConstants.filterModern),
                const SizedBox(width: 40),
                _buildFilterButton(AppConstants.filterTraditional),
              ],
            ),
          ),

        // 이미지 그리드 섹션
        _buildImageGridSection(context),
      ],
    );
  }

  Widget _buildFilterButton(String filterName) {
    final bool isActive = activeFilter == filterName;
    final bool isHovered = filterHoverStates[filterName] == true;

    return MouseRegion(
      onEnter: (_) => setState(() => filterHoverStates[filterName] = true),
      onExit: (_) => setState(() => filterHoverStates[filterName] = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(
            AppConstants.defaultButtonBorderRadius,
          ),
          onTap: () => _changeFilter(filterName),
          child: Container(
            width: AppConstants.filterButtonWidth,
            height: AppConstants.filterButtonHeight,
            decoration: BoxDecoration(
              color:
                  isHovered && !isActive
                      ? AppColors.backgroundLight
                      : AppColors.background,
              borderRadius: BorderRadius.circular(
                AppConstants.defaultButtonBorderRadius,
              ),
              border: Border.all(
                color: isActive ? const Color(0xFF6E6E6E) : AppColors.border,
                width:
                    isActive
                        ? AppConstants.borderWidthThick
                        : AppConstants.borderWidthMedium,
              ),
            ),
            child: Center(
              child: Text(
                filterName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 이미지 그리드 섹션 (기존 BestSection의 주요 기능)
  Widget _buildImageGridSection(BuildContext context) {
    bool isMobile = AppSizes.isMobile(context);
    bool isTablet = AppSizes.isTablet(context);
    bool isDesktop = AppSizes.isDesktop(context);

    // 화면 크기에 따라 컬럼 수 설정
    int crossAxisCount;
    if (isMobile) {
      crossAxisCount = 2; // 모바일: 2개
    } else if (isTablet) {
      crossAxisCount = 3; // 태블릿: 3개
    } else {
      crossAxisCount = 4; // 데스크탑: 4개
    }

    return Column(
      children: [
        Consumer<HanbokState>(
          builder: (context, hanbokState, child) {
            // HanbokState가 변경될 때마다 캐시를 초기화 (실제로는 참조변경 감지)
            if (hanbokState.modernPresets.isNotEmpty || hanbokState.traditionalPresets.isNotEmpty) {
              if (_cachedModernImages == null || _cachedTraditionalImages == null) {
                // 초기에 null이거나 캐시가 초기화된 경우에만 새로 캐싱
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _resetCache();
                });
              }
            }
            
            // 프리셋 로딩 중이거나 비어있는 경우 로딩 표시
            if (hanbokState.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            
            // 프리셋이 비어있는 경우 처리
            if (hanbokState.modernPresets.isEmpty && hanbokState.traditionalPresets.isEmpty) {
              return const Center(
                child: Text('한복 이미지를 불러올 수 없습니다.'),
              );
            }
            
            // 필터링된 이미지와 정렬된 인덱스 가져오기 (매번 재계산하지 않고 한 번만 계산)
            final List<String> filteredImages = getFilteredImages();
            List<int> sortedIndices = List.generate(filteredImages.length, (index) => index);
            
            // 필터링되지 않은 경우(전체 이미지)만 모던/트래디셔널 이미지 재배열
            List<String> arrangedImages = filteredImages;
            if (activeFilter == null && filteredImages.isNotEmpty) {
              // 모던 이미지와 트래디셔널 이미지를 번갈아 배치 (한 줄에 모던 2장, 트래디셔널 2장)
              arrangedImages = _getArrangedImages(hanbokState);
              sortedIndices = List.generate(arrangedImages.length, (index) => index);
            }
            
            // 최대 표시 개수 설정
            final int displayCount = showMoreImages ? arrangedImages.length : math.min(8, arrangedImages.length);
            
            if (arrangedImages.isEmpty) {
              return const Center(
                child: Text('필터링된 이미지가 없습니다.'),
              );
            }
            
            return MasonryGridView.count(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              itemCount: displayCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                bottom: AppSizes.getSection1BottomPadding(context) * 0.5,
              ), // 하단 패딩 줄임
              itemBuilder: (context, index) {
                final imageIndex = sortedIndices[index % sortedIndices.length];
                final bool isSmallImage = imageIndex % 3 == 1; // Every third image is smaller
                final String imagePath = arrangedImages[imageIndex];
                
                // 선택된 이미지인지 확인
                final bool isSelected = widget.selectedImage == imagePath;
                // 롤오버 효과 상태 확인
                final bool isHovered = hoverStates[imagePath] == true;

                // 이미지 사전 로드 (깜빡임 방지)
                precacheImage(NetworkImage(imagePath), context);

                // 외부 컨테이너 (외부 테두리)의 모서리 둥글기
                final double outerRadius = AppConstants.defaultCardBorderRadius;
                // 내부 이미지 컨테이너의 모서리 둥글기 (롤오버/선택 시 약간 줄어듦)
                final double innerRadius = isHovered ? 11 : AppConstants.defaultCardBorderRadius;

                return MouseRegion(
                  onEnter: (_) => setState(() => hoverStates[imagePath] = true),
                  onExit: (_) => setState(() => hoverStates[imagePath] = false),
                  child: RepaintBoundary(
                    // 성능 최적화
                    child: GestureDetector(
                      onTap: () {
                        // 클릭 카운트 증가
                        setState(() {
                          if (imageIndex < clickCounts.length) {
                            clickCounts[imageIndex]++;
                          }
                        });

                        // 이미지 클릭 핸들러 호출 (비동기)
                        if (widget.onImageClick != null) {
                          widget.onImageClick!(imagePath);
                        }

                        // 페이지 최상단으로 스크롤
                        _scrollToTop();
                      },
                      child: AspectRatio(
                        aspectRatio: isSmallImage ? 0.8 : 0.7, // 가로세로 비율 설정
                        child: AnimatedContainer(
                          duration: AppConstants.defaultAnimationDuration,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(outerRadius),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? AppColors.primary
                                      : (isHovered
                                          ? AppColors.imageStrokeHover
                                          : AppColors.border.withOpacity(0.3)),
                              width:
                                  isSelected
                                      ? AppConstants.borderWidthThick
                                      : (isHovered
                                          ? AppConstants.borderWidthHover
                                          : AppConstants.borderWidthThin),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(innerRadius),
                            child: Image.network(
                              imagePath,
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                              // 이미지 캐싱 활성화하여 성능 향상
                              cacheWidth: (MediaQuery.of(context).size.width / crossAxisCount).ceil(),
                              filterQuality: FilterQuality.high,
                              gaplessPlayback: true,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppColors.backgroundMedium,
                                  child: Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                );
                              },
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
        ),

        // 버튼 간격
        const SizedBox(height: 20),

        // "More Images" 버튼 - 항상 표시
        if (!showMoreImages)
          MouseRegion(
            onEnter: (_) => setState(() => isMoreButtonHovered = true),
            onExit: (_) => setState(() => isMoreButtonHovered = false),
            child: AnimatedContainer(
              duration: AppConstants.defaultAnimationDuration,
              width: AppConstants.moreButtonWidth,
              height: AppConstants.moreButtonHeight,
              decoration: BoxDecoration(
                color:
                    isMoreButtonHovered
                        ? AppColors.backgroundLight
                        : AppColors.background,
                borderRadius: BorderRadius.circular(
                  AppConstants.defaultButtonBorderRadius,
                ),
                border: Border.all(
                  color: AppColors.border,
                  width: AppConstants.borderWidthMedium,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(
                    AppConstants.defaultButtonBorderRadius,
                  ),
                  onTap: () {
                    setState(() {
                      showMoreImages = true;
                    });
                  },
                  child: Center(
                    child: Text(
                      "More Images",
                      style: AppTextStyles.body2(context),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  // 모던 이미지와 트래디셔널 이미지를 번갈아 배치하는 로직 (캐싱 적용)
  List<String> _getArrangedImages(HanbokState hanbokState) {
    // 캐시된 결과가 있으면 그대로 반환
    if (_cachedArrangedImages != null) {
      return _cachedArrangedImages!;
    }
    
    final modernImages = getModernImageList(hanbokState);
    final traditionalImages = getTraditionalImageList(hanbokState);
    List<String> arrangedImages = [];
    
    // 각 이미지 타입별로 지정된 수만큼 번갈아가며 추가
    // 한 줄에 모던 2장, 트래디셔널 2장씩 배치
    for (int i = 0; i < math.max(modernImages.length, traditionalImages.length); i += 2) {
      // 모던 이미지 2장 추가
      for (int j = 0; j < 2; j++) {
        int modernIndex = i + j;
        if (modernIndex < modernImages.length) {
          arrangedImages.add(modernImages[modernIndex]);
        }
      }

      // 트래디셔널 이미지 2장 추가
      for (int j = 0; j < 2; j++) {
        int traditionalIndex = i + j;
        if (traditionalIndex < traditionalImages.length) {
          arrangedImages.add(traditionalImages[traditionalIndex]);
        }
      }
    }
    
    // 결과 캐싱
    _cachedArrangedImages = arrangedImages;
    return arrangedImages;
  }
  
  // 필터 변경 시 호출되는 메서드
  void _changeFilter(String? newFilter) {
    setState(() {
      activeFilter = activeFilter == newFilter ? null : newFilter;
      
      // 필터 변경 시 더보기 상태 초기화
      showMoreImages = false;
      
      // 캐시 초기화 (필터가 변경되면 표시할 이미지가 달라짐)
      _cachedArrangedImages = null;
      
      // 필터 변경 콜백 호출
      if (widget.onFilterChange != null) {
        widget.onFilterChange!(activeFilter);
      }
    });
  }
}
