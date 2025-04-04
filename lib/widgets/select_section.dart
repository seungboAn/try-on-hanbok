import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'dart:math' as math;
import 'package:try_on_hanbok/constants/exports.dart';
import 'package:provider/provider.dart';
import 'package:supabase_services/hanbok_state.dart';

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
  // 모드 설정 - best 모드일 때 true (BestSection 역할 대체)
  final bool isBestMode;
  // 기본 필터 값 (best 모드에서 사용)
  final String? defaultFilter;

  const SelectSection({
    super.key,
    this.onImageClick,
    this.onFilterChange,
    this.showFilterButtons = true, // 기본값은 표시함
    this.parentScrollController,
    this.selectedImage,
    this.isBestMode = false, // 기본값은 일반 모드
    this.defaultFilter,
  });

  @override
  State<SelectSection> createState() => _SelectSectionState();
}

class _SelectSectionState extends State<SelectSection> {
  String? activeFilter;

  // 롤오버 상태를 위한 맵 (인덱스를 키로 사용)
  final Map<String, bool> hoverStates = {};
  // 필터 버튼 롤오버 상태
  final Map<String, bool> filterHoverStates = {};

  // 현재 표시중인 이미지 수
  int currentDisplayCount = 8;
  // 롤오버 상태
  bool isMoreButtonHovered = false;

  // 캐싱된 이미지 목록
  List<String>? _cachedModernImages;
  List<String>? _cachedTraditionalImages;
  List<String>? _cachedArrangedImages;

  final List<int> clickCounts = List.filled(16, 0); // 클릭 카운트

  // 스크롤 컨트롤러 추가
  final ScrollController _scrollController = ScrollController();

  // 초기화 중인지 여부
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();

    // 기본 필터 설정 (BestSection 모드일 때)
    if (widget.isBestMode && widget.defaultFilter != null) {
      activeFilter = widget.defaultFilter;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollController.addListener(() {});

        // 최초 한 번만 이미지 로드 (캐싱)
        _loadImagesOnce();
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

    // defaultFilter가 변경된 경우 필터 업데이트
    if (widget.defaultFilter != oldWidget.defaultFilter && widget.isBestMode) {
      setState(() {
        activeFilter = widget.defaultFilter;
      });
    }
  }

  // 이미지를 최초 한 번만 로드하는 메서드
  void _loadImagesOnce() {
    if (_cachedModernImages == null || _cachedTraditionalImages == null) {
      final hanbokState = Provider.of<HanbokState>(context, listen: false);

      // 디버그 로그 추가
      debugPrint('SelectSection: _loadImagesOnce 호출됨');
      debugPrint(
        'HankbokState 상태 확인 - 모던: ${hanbokState.modernPresets.length}, 전통: ${hanbokState.traditionalPresets.length}',
      );

      if (hanbokState.modernPresets.isNotEmpty ||
          hanbokState.traditionalPresets.isNotEmpty) {
        setState(() {
          _cachedModernImages =
              hanbokState.modernPresets
                  .map<String>((preset) => preset.imagePath)
                  .toList();
          _cachedTraditionalImages =
              hanbokState.traditionalPresets
                  .map<String>((preset) => preset.imagePath)
                  .toList();
        });
        debugPrint(
          '이미지 캐싱 완료 - 모던: ${_cachedModernImages?.length}, 전통: ${_cachedTraditionalImages?.length}',
        );
      } else {
        // HanbokState가 비어있으면 초기화 시도
        debugPrint('HankbokState가 비어있음, 초기화 시도');
        _initializeHanbokState();
      }
    }
  }

  // HanbokState 초기화 메소드
  Future<void> _initializeHanbokState() async {
    if (_isInitializing) {
      debugPrint('이미 초기화 중, 중복 초기화 방지');
      return; // 이미 초기화 중이면 중복 실행 방지
    }

    _isInitializing = true;

    try {
      final hanbokState = Provider.of<HanbokState>(context, listen: false);
      debugPrint('HanbokState 초기화 시작...');

      await hanbokState.initialize();

      if (mounted) {
        debugPrint('HanbokState 초기화 완료, 이미지 캐싱 시작');
        setState(() {
          _cachedModernImages =
              hanbokState.modernPresets
                  .map<String>((preset) => preset.imagePath)
                  .toList();
          _cachedTraditionalImages =
              hanbokState.traditionalPresets
                  .map<String>((preset) => preset.imagePath)
                  .toList();
          _cachedArrangedImages = null; // 재배열된 이미지도 초기화
        });
        debugPrint(
          '캐싱 완료 - 모던: ${_cachedModernImages?.length}, 전통: ${_cachedTraditionalImages?.length}',
        );
      }
    } catch (e) {
      debugPrint('HanbokState 초기화 오류: $e');
    } finally {
      _isInitializing = false;
    }
  }

  // HanbokState가 갱신될 때마다 캐시를 초기화하는 메서드 (필요시 직접 호출)
  void _resetCache() {
    setState(() {
      _cachedModernImages = null;
      _cachedTraditionalImages = null;
      _cachedArrangedImages = null;
    });

    // 캐시 초기화 후 다시 로드
    _loadImagesOnce();
  }

  // 필터링된 이미지 목록 반환 (리스트만 가져오고 상태 구독 안함)
  List<String> getFilteredImages() {
    final hanbokState = context.read<HanbokState>();

    // 디버그 로그 추가
    debugPrint('SelectSection: getFilteredImages 호출됨, 현재 필터: $activeFilter');

    // 캐시가 비어있으면 초기화
    if (_cachedModernImages == null ||
        _cachedTraditionalImages == null ||
        (_cachedModernImages?.isEmpty ?? true) &&
            (_cachedTraditionalImages?.isEmpty ?? true)) {
      debugPrint('이미지 캐시가 비어있음');

      if (hanbokState.modernPresets.isNotEmpty ||
          hanbokState.traditionalPresets.isNotEmpty) {
        debugPrint('HankbokState에서 이미지 로드');
        _cachedModernImages =
            hanbokState.modernPresets
                .map<String>((preset) => preset.imagePath)
                .toList();
        _cachedTraditionalImages =
            hanbokState.traditionalPresets
                .map<String>((preset) => preset.imagePath)
                .toList();
        debugPrint(
          '캐싱 완료 - 모던: ${_cachedModernImages?.length}, 전통: ${_cachedTraditionalImages?.length}',
        );
      } else {
        // HanbokState가 비어있으면 빈 리스트 반환하고 초기화를 요청
        debugPrint('HankbokState가 비어있음, 초기화 요청');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _initializeHanbokState();
        });
        return <String>[];
      }
    }

    // 필터에 따라 이미지 목록 반환 (이미 캐싱된 리스트 사용)
    if (activeFilter == AppConstants.filterModern) {
      debugPrint('모던 필터 적용 - ${_cachedModernImages?.length}개 이미지 반환');
      return _cachedModernImages ?? <String>[];
    } else if (activeFilter == AppConstants.filterTraditional) {
      debugPrint('전통 필터 적용 - ${_cachedTraditionalImages?.length}개 이미지 반환');
      return _cachedTraditionalImages ?? <String>[];
    }

    // 필터가 없는 경우 두 리스트 합치기
    final List<String> allImages = [
      ...(_cachedModernImages ?? <String>[]),
      ...(_cachedTraditionalImages ?? <String>[]),
    ];
    debugPrint('필터 없음 - 전체 ${allImages.length}개 이미지 반환');
    return allImages;
  }

  // 이미지 클릭 핸들러 - BestSection과 일반 모드 통합
  Future<void> _handleImageClick(String imagePath) async {
    // 이미지 클릭 카운트 증가 로직은 그대로 유지

    if (widget.onImageClick != null) {
      // 기존 SelectSection 모드: 콜백 호출 후 스크롤
      await widget.onImageClick!(imagePath);
      _scrollToTop();
    } else {
      // 콜백이 없는 경우 직접 GeneratePage로 이동 (BestSection과 동일한 동작)
      if (context.mounted) {
        Navigator.pushNamed(
          context,
          AppConstants.generateRoute,
          arguments: imagePath, // 클릭한 이미지의 경로를 전달
        );
      }
    }
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
            padding: const EdgeInsets.only(
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
                style: const TextStyle(
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
        Builder(
          builder: (context) {
            // listen: false로 HanbokState 가져오기
            final hanbokState = Provider.of<HanbokState>(
              context,
              listen: false,
            );

            // 이미지 목록은 빌드 시 한 번만 가져옴
            // 필터링된 이미지와 정렬된 인덱스 가져오기
            final List<String> filteredImages = getFilteredImages();
            List<int> sortedIndices = List.generate(
              filteredImages.length,
              (index) => index,
            );

            // 필터링되지 않은 경우(전체 이미지)만 모던/트래디셔널 이미지 재배열
            List<String> arrangedImages = filteredImages;
            if (activeFilter == null && filteredImages.isNotEmpty) {
              arrangedImages = _getArrangedImages(hanbokState);
              sortedIndices = List.generate(
                arrangedImages.length,
                (index) => index,
              );
            }

            // 최대 표시 개수 설정
            final int displayCount = math.min(
              currentDisplayCount,
              arrangedImages.length,
            );

            if (arrangedImages.isEmpty) {
              // 이미지가 없을 때 로딩 표시 추가
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isInitializing)
                      const CircularProgressIndicator()
                    else
                      const Icon(
                        Icons.image_not_supported,
                        size: 48,
                        color: Color(0xFFAAAAAA),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      _isInitializing
                          ? 'Loading images...'
                          : 'No images available.',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFFAAAAAA),
                      ),
                    ),
                    // 재시도 버튼
                    if (!_isInitializing)
                      TextButton(
                        onPressed: () {
                          _resetCache();
                          _initializeHanbokState();
                        },
                        child: const Text('Try again'),
                      ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                MasonryGridView.count(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  itemCount: displayCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: AppSizes.getSection1BottomPadding(context) * 0.5,
                  ),
                  itemBuilder: (context, index) {
                    final imageIndex =
                        sortedIndices[index % sortedIndices.length];
                    final bool isSmallImage = imageIndex % 3 == 1;
                    final String imagePath = arrangedImages[imageIndex];

                    // 선택된 이미지인지 확인
                    final bool isSelected = widget.selectedImage == imagePath;
                    // 롤오버 효과 상태 확인
                    final bool isHovered = hoverStates[imagePath] == true;

                    // 이미지 사전 로드 (깜빡임 방지)
                    precacheImage(NetworkImage(imagePath), context);

                    final double outerRadius =
                        AppConstants.defaultCardBorderRadius;
                    final double innerRadius =
                        isHovered ? 11 : AppConstants.defaultCardBorderRadius;

                    return MouseRegion(
                      onEnter:
                          (_) => setState(() => hoverStates[imagePath] = true),
                      onExit:
                          (_) => setState(() => hoverStates[imagePath] = false),
                      child: RepaintBoundary(
                        child: GestureDetector(
                          onTap: () {
                            if (imageIndex < clickCounts.length) {
                              setState(() => clickCounts[imageIndex]++);
                            }
                            _handleImageClick(imagePath);
                          },
                          child: Container(
                            constraints: BoxConstraints(
                              maxHeight:
                                  isSmallImage ? 300 : 350, // 이미지 최대 높이 제한
                            ),
                            child: AspectRatio(
                              aspectRatio: isSmallImage ? 0.8 : 0.7,
                              child: AnimatedContainer(
                                duration: AppConstants.defaultAnimationDuration,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    outerRadius,
                                  ),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? AppColors.primary
                                            : (isHovered
                                                ? AppColors.imageStrokeHover
                                                : AppColors.border.withOpacity(
                                                  0.3,
                                                )),
                                    width:
                                        isSelected
                                            ? AppConstants.borderWidthThick
                                            : (isHovered
                                                ? AppConstants.borderWidthHover
                                                : AppConstants.borderWidthThin),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    innerRadius,
                                  ),
                                  child: Image.network(
                                    imagePath,
                                    fit: BoxFit.cover, // 이미지를 꽉 채우도록 변경
                                    alignment: Alignment.topCenter, // 상단 정렬로 변경
                                    loadingBuilder: (
                                      context,
                                      child,
                                      loadingProgress,
                                    ) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value:
                                              loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                  : null,
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      debugPrint(
                                        '이미지 로드 에러: $error, URL: $imagePath',
                                      );
                                      return Container(
                                        color: AppColors.backgroundMedium,
                                        child: const Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.broken_image,
                                                color: AppColors.textSecondary,
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                '이미지 로드 실패',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
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
                      ),
                    );
                  },
                ),

                // 버튼 간격
                const SizedBox(height: 20),

                // "More Images" 버튼 - 더 표시할 이미지가 있을 때만 표시
                if (displayCount < arrangedImages.length)
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
                              currentDisplayCount += 8; // 8장씩 추가
                            });
                          },
                          child: Center(
                            child: Text(
                              'More Images',
                              style: AppTextStyles.body2(context),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  // 모던 이미지와 트래디셔널 이미지를 번갈아 배치하는 로직 (캐싱 적용)
  List<String> _getArrangedImages(HanbokState hanbokState) {
    // 캐시된 결과가 있으면 그대로 반환
    if (_cachedArrangedImages != null && _cachedArrangedImages!.isNotEmpty) {
      return _cachedArrangedImages!;
    }

    // 캐시된 이미지 리스트 사용
    final List<String> modernImages = _cachedModernImages ?? <String>[];
    final List<String> traditionalImages =
        _cachedTraditionalImages ?? <String>[];
    List<String> arrangedImages = <String>[];

    // 각 이미지 타입별로 지정된 수만큼 번갈아가며 추가
    // 한 줄에 모던 2장, 트래디셔널 2장씩 배치
    for (
      int i = 0;
      i < math.max(modernImages.length, traditionalImages.length);
      i += 2
    ) {
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
      currentDisplayCount = 8; // 필터 변경 시 표시 개수 초기화
      _cachedArrangedImages = null;

      // 필터 변경 콜백 호출
      if (widget.onFilterChange != null) {
        widget.onFilterChange!(activeFilter);
      }
    });
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
}
