import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'dart:math' as math;
// dart:io는 웹에서 지원되지 않으므로 조건부 import
// ignore: avoid_web_libraries_in_flutter
import 'dart:io' if (dart.library.html) 'dart:ui' as ui;
import 'package:test02/constants/exports.dart';
import 'package:test02/widgets/select_section.dart';
import 'package:flutter/services.dart';
import 'package:supabase_services/hanbok_state.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 점선 원 그리는 커스텀 페인터
class DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gapSize;
  final double dashSize;

  DashedCirclePainter({
    required this.color,
    required this.strokeWidth,
    required this.gapSize,
    required this.dashSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;

    // 원의 중심과 반지름 계산
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // 원 둘레 계산
    final circumference = 2 * math.pi * radius;

    // 각 점선 호의 각도 계산
    final dashAngle = (dashSize / circumference) * 2 * math.pi;
    final gapAngle = (gapSize / circumference) * 2 * math.pi;

    // 시작 각도
    double startAngle = 0;

    // 원을 따라 점선 그리기
    while (startAngle < 2 * math.pi) {
      // 현재 각도에서 dash 길이만큼 호 그리기
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );

      // 다음 dash의 시작 위치로 이동
      startAngle += dashAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class GenerateSection extends StatefulWidget {
  // 외부에서 선택된 한복 이미지를 받을 수 있도록 속성 추가
  final String? selectedHanbokImage;
  // 패딩 적용 여부 (페이지에서 직접 사용할 때는 true, 다른 위젯에 포함될 때는 false)
  final bool usePadding;
  // 외부 스크롤 컨트롤러 추가
  final ScrollController? externalScrollController;

  const GenerateSection({
    Key? key,
    this.selectedHanbokImage,
    this.usePadding = false,
    this.externalScrollController,
  }) : super(key: key);

  @override
  State<GenerateSection> createState() => _GenerateSectionState();
}

class _GenerateSectionState extends State<GenerateSection> {
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  // 한복 프리셋 이미지를 API로부터 가져오도록 수정
  List<String> _hanbokPresets = [];
  
  // 최근 선택한 한복 이미지를 저장하는 리스트 (최대 5개)
  List<String> _recentlySelectedHanboks = [];

  // 선택된 한복 이미지
  String? _selectedHanbokImage;

  // 현재 활성화된 필터
  String? _currentFilter;

  // 내부 스크롤 컨트롤러
  final ScrollController _internalScrollController = ScrollController();

  // 사용할 스크롤 컨트롤러 얻기
  ScrollController get _scrollController =>
      widget.externalScrollController ?? _internalScrollController;

  @override
  void initState() {
    super.initState();
    // 외부에서 전달된 이미지가 있으면 설정
    if (widget.selectedHanbokImage != null) {
      _selectedHanbokImage = widget.selectedHanbokImage;
    }
    
    // 초기화 작업
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 최근 선택한 한복 이미지 불러오기
      await _loadRecentlySelectedHanboks();
      
      // 외부에서 전달된 이미지가 있으면 최근 목록에 추가
      if (widget.selectedHanbokImage != null) {
        await _addToRecentHanboks(widget.selectedHanbokImage!);
      }
      
      // Hanbok State 초기화 (프리셋이 비어있을 때만 초기화)
      final hanbokState = context.read<HanbokState>();
      if (hanbokState.modernPresets.isEmpty || hanbokState.traditionalPresets.isEmpty) {
        await hanbokState.initialize();
      }
    });
  }

  @override
  void didUpdateWidget(GenerateSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 속성이 변경되었을 때 상태 업데이트
    if (widget.selectedHanbokImage != null &&
        widget.selectedHanbokImage != oldWidget.selectedHanbokImage) {
      setState(() {
        _selectedHanbokImage = widget.selectedHanbokImage;
      });
      
      // 비동기로 최근 선택 목록에 추가
      if (widget.selectedHanbokImage != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await _addToRecentHanboks(widget.selectedHanbokImage!);
        });
      }
    }
  }

  @override
  void dispose() {
    // 내부 컨트롤러만 해제 (외부는 외부에서 관리)
    if (widget.externalScrollController == null) {
      _internalScrollController.dispose();
    }
    super.dispose();
  }

  // 최근 선택한 한복 리스트에 추가 (순서 유지 버전)
  Future<void> _addToRecentHanboks(String imagePath) async {
    setState(() {
      // 이미 목록에 있는 이미지인 경우 순서 유지 (맨 앞으로 이동하지 않음)
      if (!_recentlySelectedHanboks.contains(imagePath)) {
        // 새로운 이미지만 추가 (맨 앞이 아닌 현재 선택한 위치에 추가)
        if (_recentlySelectedHanboks.length < 5) {
          // 목록이 5개 미만일 때는 맨 뒤에 추가
          _recentlySelectedHanboks.add(imagePath);
        } else {
          // 목록이 이미 5개 이상이면 마지막 항목 제거 후 새 항목 추가
          _recentlySelectedHanboks.removeLast();
          _recentlySelectedHanboks.add(imagePath);
        }
      }
    });
    
    // 로컬 저장소에 저장
    await _saveRecentlySelectedHanboks();
  }
  
  // 로컬 저장소에서 최근 선택한 한복 이미지 불러오기
  Future<void> _loadRecentlySelectedHanboks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedHanboks = prefs.getStringList('recent_hanboks') ?? [];
      
      debugPrint('Loaded ${savedHanboks.length} recently selected hanboks from preferences');
      
      if (mounted) {
        setState(() {
          _recentlySelectedHanboks = savedHanboks;
        });
      }
    } catch (e) {
      debugPrint('Error loading recent hanboks: $e');
      // 에러 발생 시 빈 리스트로 초기화
      if (mounted) {
        setState(() {
          _recentlySelectedHanboks = [];
        });
      }
    }
  }
  
  // 로컬 저장소에 최근 선택한 한복 이미지 저장
  Future<void> _saveRecentlySelectedHanboks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('recent_hanboks', _recentlySelectedHanboks);
      debugPrint('Saved ${_recentlySelectedHanboks.length} recently selected hanboks to preferences');
    } catch (e) {
      debugPrint('Error saving recent hanboks: $e');
    }
  }

  // 이미지가 선택되었을 때 호출되는 함수 (순서 변경 방지)
  Future<void> _onImageSelected(String imagePath) async {
    setState(() {
      _selectedHanbokImage = imagePath;
    });
    
    // 최근 선택 목록에 추가 (이미 있는 이미지의 순서는 변경하지 않음)
    await _addToRecentHanboks(imagePath);
  }

  // 최상단으로 스크롤
  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: AppConstants.pageTransitionDuration,
        curve: Curves.easeInOut,
      );
    }
  }

  // SelectSection을 위한 스크롤 메서드
  void scrollToTop() {
    _scrollToTop();
  }

  // 재배열된 이미지 목록에서 정확한 이미지 경로 가져오기
  String _getImagePathFromIndex(int index, {String? filter}) {
    // 상수 클래스의 이미지 리스트 사용
    final List<String> modernImages = AppConstants.modernHanbokList;
    final List<String> traditionalImages = AppConstants.traditionalHanbokList;

    // 필터가 적용된 경우
    if (filter == AppConstants.filterModern) {
      // Modern 필터 - 인덱스가 modernImages 범위 내에 있으면 해당 이미지 반환
      if (index < modernImages.length) {
        return modernImages[index];
      }
      return modernImages[0]; // 기본값
    } else if (filter == AppConstants.filterTraditional) {
      // Traditional 필터 - 인덱스가 traditionalImages 범위 내에 있으면 해당 이미지 반환
      if (index < traditionalImages.length) {
        return traditionalImages[index];
      }
      return traditionalImages[0]; // 기본값
    }

    // 필터가 없는 경우 (전체 이미지 보기)
    // 2장씩 배치 로직에 맞춘 인덱스 계산
    int row = index ~/ 4; // 몇 번째 줄인지 계산
    int col = index % 4; // 줄 내 위치 (0,1: 모던, 2,3: 트래디셔널)

    if (col < 2) {
      // 모던 이미지 (0,1번 열)
      int modernIndex = row * 2 + col;
      if (modernIndex < modernImages.length) {
        return modernImages[modernIndex];
      }
    } else {
      // 트래디셔널 이미지 (2,3번 열)
      int traditionalIndex = row * 2 + (col - 2);
      if (traditionalIndex < traditionalImages.length) {
        return traditionalImages[traditionalIndex];
      }
    }

    // 기본값으로 첫 번째 이미지 반환
    return modernImages[0];
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });

        // Upload image using Supabase service
        final hanbokState = context.read<HanbokState>();
        
        // 로딩 상태 표시
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('이미지를 업로드 중입니다...'),
            duration: Duration(seconds: 1),
          ),
        );
        
        await hanbokState.uploadUserImage(bytes, 'image/jpeg');

        // Show error if upload failed
        if (hanbokState.taskStatus == 'error') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(hanbokState.errorMessage ?? '이미지 업로드에 실패했습니다.'),
              ),
            );
          }
        } else if (hanbokState.uploadedImageUrl != null) {
          // 업로드 성공 메시지
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('이미지가 성공적으로 업로드되었습니다.'),
                duration: Duration(seconds: 1),
              ),
            );
          }
        }
      }
    } catch (e) {
      // 에러 처리
      debugPrint('Error picking image: $e');
      // 사용자에게 오류 메시지 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지를 선택하는 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  // 한복 이미지 선택 함수 (순서 유지 버전)
  Future<void> _selectHanbokImage(String imagePath) async {
    setState(() {
      _selectedHanbokImage = imagePath;
    });
    
    // 최근 선택 목록에 추가 (순서 유지)
    await _addToRecentHanboks(imagePath);
  }

  // 한복 프리셋 이미지를 HanbokState에서 가져오는 메서드 (최적화)
  // 이 메서드는 초기화 시에만 호출되도록 변경
  Future<void> _loadPresetImages() async {
    final hanbokState = context.read<HanbokState>();
    
    // 프리셋이 이미 로드되어 있으면 다시 로드하지 않음
    if (!hanbokState.isLoading && (hanbokState.modernPresets.isNotEmpty || hanbokState.traditionalPresets.isNotEmpty)) {
      debugPrint('Presets already loaded, skipping initialization');
      _updatePresetList(hanbokState);
      return;
    }
    
    // 디버그 로그: 한복 상태 확인
    debugPrint('Loading preset images...');
    
    // 이미지 목록이 비어 있는 경우만 초기화
    if (hanbokState.modernPresets.isEmpty && hanbokState.traditionalPresets.isEmpty) {
      debugPrint('Presets are empty, initializing...');
      await hanbokState.initialize();
    }
    
    _updatePresetList(hanbokState);
  }
  
  // 프리셋 목록 업데이트
  void _updatePresetList(HanbokState hanbokState) {
    List<String> presets = [];
    
    // 모던 한복 이미지 경로 추가
    for (var modern in hanbokState.modernPresets) {
      presets.add(modern.imagePath);
    }
    
    // 전통 한복 이미지 경로 추가
    for (var traditional in hanbokState.traditionalPresets) {
      presets.add(traditional.imagePath);
    }
    
    if (presets.isNotEmpty) {
      debugPrint('Updated preset list with ${presets.length} items');
      // 이미지 URL 샘플 출력
      if (presets.isNotEmpty) {
        debugPrint('First preset image URL: ${presets.first}');
      }
    } else {
      debugPrint('No presets available after update');
    }
    
    if (mounted) {
      setState(() {
        _hanbokPresets = presets;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = AppSizes.isMobile(context);
    bool isTablet = AppSizes.isTablet(context);

    // 모바일과 태블릿에서는 세로로 배치, 데스크탑에서는 가로로 배치
    Widget mainContent =
        isMobile || isTablet
            ? _buildMobileTabletContent(context)
            : _buildDesktopContent(context);

    // 전체 위젯
    Widget content = SingleChildScrollView(
      controller: _scrollController,
      physics: const ClampingScrollPhysics(),
      child: Column(
        children: [
          // 상단 한복 선택 및 업로드 섹션
          Container(
            width: double.infinity,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                mainContent,

                // Constants/exports.dart에 정의된 반응형 패딩 사용
                SizedBox(height: AppSizes.getTryOnButtonTopPadding(context)),

                // Try On button
                StatefulBuilder(
                  builder: (context, setState) {
                    bool isHovered = false;
                    bool isMobile = AppSizes.isMobile(context);
                    bool isTablet = AppSizes.isTablet(context);

                    return MouseRegion(
                      onEnter: (_) => setState(() => isHovered = true),
                      onExit: (_) => setState(() => isHovered = false),
                      child: AnimatedContainer(
                        duration: AppConstants.defaultAnimationDuration,
                        width: AppSizes.getButtonWidth(context),
                        height: AppSizes.getButtonHeight(context),
                        decoration: BoxDecoration(
                          color:
                              isHovered
                                  ? AppColors.buttonHover
                                  : AppColors.background,
                          borderRadius: BorderRadius.circular(
                            AppConstants.defaultButtonBorderRadius,
                          ),
                          border: Border.all(
                            color:
                                isHovered
                                    ? AppColors.primary
                                    : AppColors.border,
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
                            onTap: () async {
                              // 양쪽 이미지가 모두 선택되었는지 확인
                              if (_imageBytes != null && _selectedHanbokImage != null) {
                                final hanbokState = context.read<HanbokState>();
                                
                                try {
                                  // 업로드된 이미지 URL이 있는지 확인
                                  if (hanbokState.uploadedImageUrl == null) {
                                    throw Exception('이미지가 제대로 업로드되지 않았습니다.');
                                  }
                                  
                                  await hanbokState.generateHanbokFitting(_selectedHanbokImage!);
                                  if (mounted) {
                                Navigator.pushNamed(
                                  context,
                                  AppConstants.resultRoute,
                                );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(hanbokState.errorMessage ?? '가상 피팅 생성에 실패했습니다.'),
                                      ),
                                    );
                                  }
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('사용자 이미지와 한복 이미지를 모두 선택해주세요'),
                                  ),
                                );
                              }
                            },
                            child: Center(
                              child: Text(
                                'Try On',
                                style: AppTextStyles.button(context).copyWith(
                                  color:
                                      isHovered
                                          ? AppColors.textButton
                                          : AppColors.textPrimary,
                                  fontWeight:
                                      isHovered
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                  fontSize:
                                      isMobile ? 14 : (isTablet ? 16 : null),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // 한복 선택 섹션
          SizedBox(height: AppSizes.getSection1BottomPadding(context)),

          // SelectSection 통합
          Padding(
            padding: AppSizes.getScreenPadding(context),
            child: SelectSection(
              onImageClick: (imagePath) async {
                // 이미지 선택 및 최근 목록에 추가
                await _onImageSelected(imagePath);

                // 최상단으로 스크롤
                _scrollToTop();
              },
              selectedImage: _selectedHanbokImage,
            ),
          ),
        ],
      ),
    );

    // usePadding이 true인 경우 패딩 적용
    if (widget.usePadding) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32),
        child: content,
      );
    }

    return content;
  }

  // 데스크탑 레이아웃 (좌: 업로드 버튼, 중앙: 한복 이미지, 우: 최근 선택한 한복)
  Widget _buildDesktopContent(BuildContext context) {
    final presetSize = AppSizes.getPresetImageSize(context);
    // 프리셋 5개의 높이 + 간격(20px * 4개) 계산
    final totalPresetHeight = (presetSize * 5) + (20 * 4);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upload button (왼쪽)
          _buildUploadButton(context),

          const SizedBox(width: 20),

          // 중앙 - 한복 이미지 디스플레이
          Expanded(
            child: Container(
              height: totalPresetHeight, // 프리셋 높이와 일치
              decoration: BoxDecoration(
                color: AppColors.backgroundMedium,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border, width: 0.2),
              ),
              child:
                  _selectedHanbokImage == null
                      ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '+',
                              style: TextStyle(
                                fontSize: 48,
                                color: Color(0xFFAAAAAA),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              '한복을 선택해주세요',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFFAAAAAA),
                              ),
                            ),
                          ],
                        ),
                      )
                      : ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          _selectedHanbokImage!,
                          fit: BoxFit.contain,
                          height: totalPresetHeight,
                          alignment: Alignment.center,
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
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      size: 48,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      '이미지를 불러올 수 없습니다',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                      ),
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

          const SizedBox(width: 20),

          // 최근 선택한 한복 이미지 표시 (오른쪽)
          // 항상 5개의 영역을 표시
          SizedBox(
            width: presetSize,
            child: Column(
              children: [
                for (int i = 0; i < 5; i++) ...[
                  if (i < _recentlySelectedHanboks.length) 
                    _buildPresetButton(context, _recentlySelectedHanboks[i])
                  else 
                    _buildEmptyPresetButton(context),
                  if (i < 4) const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 모바일 및 태블릿 레이아웃 (이미지 컨테이너 내부에 업로드 버튼 위치)
  Widget _buildMobileTabletContent(BuildContext context) {
    bool isMobile = AppSizes.isMobile(context);
    bool isTablet = AppSizes.isTablet(context);
    final buttonSize = AppSizes.getUploadButtonSize(context);

    // 데스크탑 레이아웃에서 사용하는 프리셋 높이 계산 (참조용)
    final presetSize = AppSizes.getPresetImageSize(context);
    final totalPresetHeightDesktop = (presetSize * 5) + (20 * 4);

    // 타블렛은 데스크탑보다 50px 작게, 모바일은 더 작게 설정
    final containerHeight =
        isMobile ? 270.0 : (totalPresetHeightDesktop - 50.0);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 20,
        vertical: isMobile ? 15 : 25,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // 이미지 컨테이너 (upload 버튼이 내부에 포함됨)
          Container(
            width: double.infinity,
            height: containerHeight,
            decoration: BoxDecoration(
              color: AppColors.backgroundMedium,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border, width: 0.2),
            ),
            child: Stack(
              children: [
                // 한복 이미지
                _selectedHanbokImage == null
                    ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '+',
                            style: TextStyle(
                              fontSize: 48,
                              color: Color(0xFFAAAAAA),
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            '한복을 선택해주세요',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFFAAAAAA),
                            ),
                          ),
                        ],
                      ),
                    )
                    : ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        _selectedHanbokImage!,
                        fit: BoxFit.contain,
                        height: containerHeight,
                        alignment: Alignment.center,
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
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    size: 48,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '이미지를 불러올 수 없습니다',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                // 업로드 버튼을 좌측 상단에 위치
                Positioned(
                  top: 15, // 상단 패딩
                  left: 15, // 좌측 패딩
                  child: _buildUploadButton(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 하단 부분: 최근 선택한 한복 이미지 5개 표시 (항상 5개 영역 표시)
          SizedBox(
            height: presetSize,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (int i = 0; i < 5; i++) ...[
                    if (i < _recentlySelectedHanboks.length) 
                      _buildPresetButton(context, _recentlySelectedHanboks[i])
                    else 
                      _buildEmptyPresetButton(context),
                    if (i < 4) const SizedBox(width: 10),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton(BuildContext context) {
    // 반응형 크기 적용
    final buttonSize = AppSizes.getUploadButtonSize(context);
    // isMobile 추가
    bool isMobile = AppSizes.isMobile(context);

    return InkWell(
      onTap: _pickImage,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.background,
          // 실선 테두리 제거
        ),
        child:
            _imageBytes != null
                ? ClipOval(child: Image.memory(_imageBytes!, fit: BoxFit.cover))
                : Stack(
                  alignment: Alignment.center,
                  children: [
                    // 점선 테두리를 위한 CustomPaint
                    CustomPaint(
                      size: Size(buttonSize, buttonSize),
                      painter: DashedCirclePainter(
                        color: AppColors.border,
                        strokeWidth: 1.5,
                        gapSize: 5.0,
                        dashSize: 5.0,
                      ),
                    ),
                    // 아이콘과 텍스트를 수직으로 배치
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 기존의 + 아이콘 (크기 축소)
                        Icon(
                          Icons.add,
                          size: buttonSize * 0.25, // 크기 축소
                          color: AppColors.textSecondary,
                        ),
                        // 간격 축소 (5px → 2px)
                        SizedBox(height: 2),
                        // your image 텍스트 크기 더 작게 설정
                        Text(
                          'your image',
                          style: TextStyle(
                            fontSize: isMobile ? 8 : 10, // 모바일에서는 더 작게
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
      ),
    );
  }

  // 프리셋 버튼 위젯 (최근 선택한 한복 이미지)
  Widget _buildPresetButton(BuildContext context, String imagePath) {
    final bool isSelected = _selectedHanbokImage == imagePath;
    
    // 반응형 크기 적용
    final presetSize = AppSizes.getPresetImageSize(context);

    // 외부 컨테이너 (외부 테두리)의 모서리 둥글기
    final double outerRadius = AppConstants.defaultCardBorderRadius;
    // 내부 이미지 컨테이너의 모서리 둥글기 (선택 시 약간 줄어듦)
    final double innerRadius = isSelected ? 11 : AppConstants.defaultCardBorderRadius;

    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;

        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: GestureDetector(
            onTap: () async => await _selectHanbokImage(imagePath),
            child: AnimatedContainer(
              duration: AppConstants.defaultAnimationDuration,
              width: presetSize,
              height: presetSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(outerRadius),
                border: Border.all(
                  color: isSelected
                              ? AppColors.primary
                      : (isHovered
                          ? AppColors.imageStrokeHover
                          : AppColors.border.withOpacity(0.3)),
                  width: isSelected
                          ? AppConstants.borderWidthThick
                      : (isHovered
                          ? AppConstants.borderWidthHover
                          : AppConstants.borderWidthThin),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(innerRadius),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 이미지
                    Image.network(
                  imagePath,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
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
                              size: 24,
                              color: AppColors.textSecondary,
            ),
          ),
        );
      },
                    ),
                    
                    // 선택됨 표시 (체크 아이콘)
                    if (isSelected)
                      Positioned(
                        top: 5,
                        right: 5,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    );
  }

  // 빈 프리셋 버튼 위젯 (선택된 이미지가 없는 경우)
  Widget _buildEmptyPresetButton(BuildContext context) {
    // 반응형 크기 적용
    final presetSize = AppSizes.getPresetImageSize(context);
    
    return Container(
      width: presetSize,
      height: presetSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.defaultCardBorderRadius),
        border: Border.all(
          color: AppColors.border.withOpacity(0.2),
          width: AppConstants.borderWidthThin,
        ),
        color: AppColors.backgroundMedium,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 24,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              '이미지 없음',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
