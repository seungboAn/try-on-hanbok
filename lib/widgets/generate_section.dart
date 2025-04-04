import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:math' as math;
// dart:io는 웹에서 지원되지 않으므로 조건부 import
// ignore: avoid_web_libraries_in_flutter
import 'package:try_on_hanbok/constants/exports.dart';
import 'package:try_on_hanbok/widgets/select_section.dart';
import 'package:flutter/services.dart';
import 'package:supabase_services/hanbok_state.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_services/supabase_services.dart';
import 'dart:async';

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
    super.key,
    this.selectedHanbokImage,
    this.usePadding = false,
    this.externalScrollController,
  });

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

  // 이미지 업로드 중 상태 변수
  bool _isUploading = false;

  // 이미지 업로드 진행률 (0.0 ~ 1.0)
  double _uploadProgress = 0.0;

  // 업로드 타임아웃을 위한 타이머
  Timer? _uploadTimeoutTimer;

  // 최대 업로드 시간 (초)
  final int _maxUploadTimeSeconds = 10;

  // 업로드 오류 메시지
  String? _uploadErrorMessage;

  // 허용되는 이미지 파일 크기 (10MB)
  final int _maxImageSizeBytes = 10 * 1024 * 1024;

  // 허용되는 최소/최대 해상도
  final int _minImageDimension = 200;
  final int _maxImageDimension = 4000;

  @override
  void initState() {
    super.initState();

    // 디버그 로그 추가
    debugPrint(
      'GenerateSection initState 실행, 외부 이미지: ${widget.selectedHanbokImage}',
    );

    // 외부에서 전달된 이미지가 있으면 설정
    if (widget.selectedHanbokImage != null) {
      debugPrint(
        'GenerateSection: 외부에서 선택된 이미지 설정 - ${widget.selectedHanbokImage}',
      );
      _selectedHanbokImage = widget.selectedHanbokImage;
    }

    // 초기화 작업
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 최근 선택한 한복 이미지 불러오기
      await _loadRecentlySelectedHanboks();

      // 외부에서 전달된 이미지가 있으면 최근 목록에 추가
      if (widget.selectedHanbokImage != null) {
        debugPrint(
          'GenerateSection: 최근 목록에 이미지 추가 - ${widget.selectedHanbokImage}',
        );
        await _addToRecentHanboks(widget.selectedHanbokImage!);
      }

      // Hanbok State 초기화 (프리셋이 비어있을 때만 초기화)
      final hanbokState = context.read<HanbokState>();
      debugPrint(
        'Hanbok State 상태 - Modern: ${hanbokState.modernPresets.length}, '
        'Traditional: ${hanbokState.traditionalPresets.length}',
      );

      if (hanbokState.modernPresets.isEmpty ||
          hanbokState.traditionalPresets.isEmpty) {
        debugPrint('Hanbok State 초기화 시작');
        await hanbokState.initialize();
        debugPrint(
          'Hanbok State 초기화 완료 - Modern: ${hanbokState.modernPresets.length}, '
          'Traditional: ${hanbokState.traditionalPresets.length}',
        );

        // 외부에서 이미지를 받지 않았는데 HanbokState가 비어있었다면,
        // HanbokState가 채워진 후 첫 번째 이미지를 선택
        if (_selectedHanbokImage == null &&
            hanbokState.modernPresets.isNotEmpty) {
          debugPrint('선택된 이미지가 없어 첫 번째 이미지로 설정');
          setState(() {
            _selectedHanbokImage = hanbokState.modernPresets.first.imagePath;
          });
        }
      }
    });
  }

  @override
  void didUpdateWidget(GenerateSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 속성이 변경되었을 때 상태 업데이트
    if (widget.selectedHanbokImage != null &&
        widget.selectedHanbokImage != oldWidget.selectedHanbokImage) {
      debugPrint(
        'GenerateSection: didUpdateWidget에서 이미지 업데이트 - ${widget.selectedHanbokImage}',
      );
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

      debugPrint(
        'Loaded ${savedHanboks.length} recently selected hanboks from preferences',
      );

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
      debugPrint(
        'Saved ${_recentlySelectedHanboks.length} recently selected hanboks to preferences',
      );
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
    // 업로드 오류 메시지 초기화
    setState(() {
      _uploadErrorMessage = null;
    });

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        // 1. 파일 사전 검증
        // 파일 크기 검증
        final int fileSize = await image.length();
        if (fileSize > _maxImageSizeBytes) {
          setState(() {
            _uploadErrorMessage = 'Image is too large (max 10MB)';
          });
          _showErrorMessage('Image is too large (max 10MB)');
          return;
        }

        // 이미지 바이트 읽기
        final bytes = await image.readAsBytes();

        // 이미지 해상도 검증은 웹 환경에서 제한적으로 동작하므로 스킵
        // 파일 크기 제한으로 간접적으로 해상도를 제한함

        // 이미지 로딩 중 상태로 설정
        setState(() {
          _isUploading = true;
          _uploadProgress = 0.0;
        });

        // 2. 업로드 제한 시간 설정
        _uploadTimeoutTimer?.cancel();
        _uploadTimeoutTimer = Timer(
          Duration(seconds: _maxUploadTimeSeconds),
          () {
            if (_isUploading) {
              // 타임아웃 발생 시 업로드 상태 초기화
              setState(() {
                _isUploading = false;
                _uploadProgress = 0.0;
                _uploadErrorMessage = 'Upload timeout. Please try again.';
              });
              _showErrorMessage('Upload timeout. Please try again.');
            }
          },
        );

        // HanbokState를 일회성으로 가져옴 (구독 없음)
        final hanbokState = Provider.of<HanbokState>(context, listen: false);

        // 디버그 로그 추가
        debugPrint('Uploading image...');

        // 업로드 진행 시뮬레이션 (실제 진행률을 추적할 수 없는 경우를 위한 시각적 피드백)
        _startUploadProgressSimulation();

        try {
          // 5. 캐싱 및 서버 응답 최적화 (헤더 추가)
          // 백엔드에 이미지 업로드 수행
          await hanbokState.uploadUserImage(bytes, 'image/jpeg');

          // 타이머 취소
          _uploadTimeoutTimer?.cancel();

          // 업로드 상태 로그
          debugPrint('Upload status: ${hanbokState.taskStatus}');
          debugPrint('Uploaded image URL: ${hanbokState.uploadedImageUrl}');

          // 업로드 성공 여부 확인 (taskStatus가 completed이고 URL이 존재하는지)
          final bool uploadSuccess =
              hanbokState.taskStatus == 'completed' &&
              hanbokState.uploadedImageUrl != null;

          if (mounted) {
            setState(() {
              _isUploading = false;
              _uploadProgress = 0.0;

              // 업로드 성공 시에만 이미지 표시
              if (uploadSuccess) {
                _imageBytes = bytes;
                _uploadErrorMessage = null;
              } else {
                // 실패 시 오류 메시지 표시
                _uploadErrorMessage =
                    hanbokState.errorMessage ?? 'Failed to upload image';
                _showErrorMessage(_uploadErrorMessage!);
              }
            });
          }
        } catch (uploadError) {
          // 타이머 취소
          _uploadTimeoutTimer?.cancel();

          // 업로드 과정에서 발생한 오류 처리
          debugPrint('Upload error: $uploadError');
          if (mounted) {
            setState(() {
              _isUploading = false;
              _uploadProgress = 0.0;
              _uploadErrorMessage = 'Error uploading image: $uploadError';
            });

            _showErrorMessage('Error uploading image: $uploadError');
          }
        }
      }
    } catch (e) {
      // 타이머 취소
      _uploadTimeoutTimer?.cancel();

      // 이미지 선택 과정에서 발생한 오류 처리
      debugPrint('Image picking error: $e');
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
          _uploadErrorMessage = 'Error selecting image: $e';
        });

        _showErrorMessage('Error selecting image: $e');
      }
    }
  }

  // 오류 메시지 표시 메서드
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // 업로드 진행률 시뮬레이션 (시각적 피드백을 위한 목적)
  void _startUploadProgressSimulation() {
    const progressUpdateInterval = Duration(milliseconds: 150);
    const progressIncrementPerUpdate = 0.05;

    // 진행률 시뮬레이션을 위한 타이머
    Timer.periodic(progressUpdateInterval, (timer) {
      if (!_isUploading) {
        timer.cancel();
        return;
      }

      setState(() {
        // 90%까지만 채우고, 실제 완료되면 100%로 설정
        if (_uploadProgress < 0.9) {
          _uploadProgress += progressIncrementPerUpdate;
          if (_uploadProgress > 0.9) {
            _uploadProgress = 0.9;
          }
        }
      });
    });
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
    if (!hanbokState.isLoading &&
        (hanbokState.modernPresets.isNotEmpty ||
            hanbokState.traditionalPresets.isNotEmpty)) {
      debugPrint('Presets already loaded, skipping initialization');
      _updatePresetList(hanbokState);
      return;
    }

    // 디버그 로그: 한복 상태 확인
    debugPrint('Loading preset images...');

    // 이미지 목록이 비어 있는 경우만 초기화
    if (hanbokState.modernPresets.isEmpty &&
        hanbokState.traditionalPresets.isEmpty) {
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
                            width: 1,
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
                              if (_imageBytes != null &&
                                  _selectedHanbokImage != null) {
                                // HanbokState를 일회성으로 가져옴 (구독 없음)
                                final hanbokState = Provider.of<HanbokState>(
                                  context,
                                  listen: false,
                                );

                                try {
                                  // 이미 처리 중이면 중복 실행 방지
                                  if (hanbokState.isLoading ||
                                      hanbokState.taskStatus == 'processing') {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('처리 중입니다. 잠시만 기다려주세요.'),
                                        backgroundColor: AppColors.primary,
                                      ),
                                    );
                                    return;
                                  }

                                  // 로딩 상태로 설정 (결과 페이지에서 로딩 UI 표시)
                                  hanbokState.setTaskStatus('processing');
                                  hanbokState.setLoading(true);
                                  // 진행률 초기화
                                  hanbokState.setProgress(0.0);

                                  // 결과 페이지로 즉시 이동
                                  if (mounted) {
                                    Navigator.pushNamed(
                                      context,
                                      AppConstants.resultRoute,
                                    );
                                  }

                                  // 업로드된 이미지 URL 확인 및 에러 처리
                                  if (hanbokState.uploadedImageUrl == null) {
                                    throw Exception(
                                      'Image was not properly uploaded. Please try again.',
                                    );
                                  }

                                  // 백그라운드에서 생성 요청 시도
                                  await hanbokState.generateHanbokFitting(
                                    _selectedHanbokImage!,
                                  );
                                } catch (e) {
                                  // 오류 발생 시 상태 업데이트 (화면 전환 후 에러 표시)
                                  debugPrint('Try On error: $e');
                                  hanbokState.setErrorMessage(e.toString());
                                  hanbokState.setTaskStatus('error');
                                  hanbokState.setLoading(false);
                                  hanbokState.setProgress(0.0); // 오류 시 진행률 초기화
                                }
                              } else {
                                // 이미지 선택 안됨 메시지
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please select both user image and hanbok image'),
                                    backgroundColor: AppColors.primary,
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
                                  fontFamily: 'Times',
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
              isBestMode: false, // 일반 모드 사용 (BestSection 모드 아님)
              parentScrollController: _scrollController, // 스크롤 컨트롤러 전달
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
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
                              'Please select a hanbok',
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
                          fit: BoxFit.cover, // 이미지를 꽉 채우도록 변경
                          height: totalPresetHeight,
                          alignment: Alignment.topCenter, // 상단 정렬
                          width: double.infinity, // 너비를 최대로 설정
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              // 로딩 완료
                              debugPrint('이미지 로딩 완료: $_selectedHanbokImage');
                              return child;
                            }
                            // 로딩 중 상태
                            debugPrint(
                              '이미지 로딩 중: ${loadingProgress.cumulativeBytesLoaded} / '
                              '${loadingProgress.expectedTotalBytes ?? 'unknown'}',
                            );
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value:
                                        loadingProgress.expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Loading image...',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF888888),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            // 에러 발생 시
                            debugPrint('이미지 로드 에러: $error');
                            debugPrint('이미지 URL: $_selectedHanbokImage');
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              // 에러 발생 시 HanbokState 재초기화 시도
                              if (mounted) {
                                final hanbokState = Provider.of<HanbokState>(
                                  context,
                                  listen: false,
                                );
                                if (hanbokState.modernPresets.isEmpty) {
                                  hanbokState.initialize();
                                }
                              }
                            });
                            return GestureDetector(
                              onTap: () {
                                // 탭 시 이미지 재로드 시도
                                debugPrint('이미지 재로드 시도');
                                if (mounted) {
                                  final hanbokState = Provider.of<HanbokState>(
                                    context,
                                    listen: false,
                                  );
                                  // 재초기화
                                  hanbokState.initialize().then((_) {
                                    if (hanbokState.modernPresets.isNotEmpty) {
                                      // modernPresets가 있으면 첫 번째 이미지로 설정
                                      setState(() {
                                        _selectedHanbokImage =
                                            hanbokState
                                                .modernPresets
                                                .first
                                                .imagePath;
                                      });
                                    }
                                  });
                                }
                              },
                              child: Container(
                                color: AppColors.backgroundMedium,
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.broken_image,
                                        size: 48,
                                        color: AppColors.textSecondary,
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        'Failed to load image',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Tap to retry',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
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
                            'Please select a hanbok',
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
                        fit: BoxFit.cover, // 이미지를 꽉 채우도록 변경
                        height: containerHeight,
                        alignment: Alignment.topCenter, // 상단 정렬
                        width: double.infinity, // 너비를 최대로 설정
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            // 로딩 완료
                            debugPrint('이미지 로딩 완료: $_selectedHanbokImage');
                            return child;
                          }
                          // 로딩 중 상태
                          debugPrint(
                            '이미지 로딩 중: ${loadingProgress.cumulativeBytesLoaded} / '
                            '${loadingProgress.expectedTotalBytes ?? 'unknown'}',
                          );
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                          : null,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Loading image...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF888888),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          // 에러 발생 시
                          debugPrint('이미지 로드 에러: $error');
                          debugPrint('이미지 URL: $_selectedHanbokImage');
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            // 에러 발생 시 HanbokState 재초기화 시도
                            if (mounted) {
                              final hanbokState = Provider.of<HanbokState>(
                                context,
                                listen: false,
                              );
                              if (hanbokState.modernPresets.isEmpty) {
                                hanbokState.initialize();
                              }
                            }
                          });
                          return GestureDetector(
                            onTap: () {
                              // 탭 시 이미지 재로드 시도
                              debugPrint('이미지 재로드 시도');
                              if (mounted) {
                                final hanbokState = Provider.of<HanbokState>(
                                  context,
                                  listen: false,
                                );
                                // 재초기화
                                hanbokState.initialize().then((_) {
                                  if (hanbokState.modernPresets.isNotEmpty) {
                                    // modernPresets가 있으면 첫 번째 이미지로 설정
                                    setState(() {
                                      _selectedHanbokImage =
                                          hanbokState
                                              .modernPresets
                                              .first
                                              .imagePath;
                                    });
                                  }
                                });
                              }
                            },
                            child: Container(
                              color: AppColors.backgroundMedium,
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      size: 48,
                                      color: AppColors.textSecondary,
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Failed to load image',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Tap to retry',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
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
      onTap: _isUploading ? null : _pickImage, // 업로드 중에는 클릭 불가
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.background,
        ),
        child:
            _isUploading
                // 업로드 중 - 진행률 및 스피닝 애니메이션 표시
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 스피닝 로더
                      SizedBox(
                        width: buttonSize * 0.3,
                        height: buttonSize * 0.3,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                      // 진행률 텍스트
                      const SizedBox(height: 5),
                      Text(
                        '${(_uploadProgress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      // 진행률 바
                      const SizedBox(height: 2),
                      Container(
                        width: buttonSize * 0.6,
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: AppColors.backgroundMedium,
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _uploadProgress,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                // 업로드 오류 상태
                : _uploadErrorMessage != null
                // 오류 아이콘 표시
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[700],
                        size: buttonSize * 0.25,
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        width: buttonSize * 0.8,
                        child: Text(
                          'Tap to retry',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 9, color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                )
                // 이미지 업로드 완료 또는 기본 상태
                : _imageBytes != null
                // 업로드된 이미지 표시
                ? ClipOval(
                  child: Image.memory(
                    _imageBytes!,
                    fit: BoxFit.cover, // 상하 fit
                    width: buttonSize,
                    height: buttonSize,
                    alignment: Alignment.topCenter, // 상단 정렬
                  ),
                )
                // 기본 상태 - 점선 원과 아이콘 표시
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
                        Icon(
                          Icons.add,
                          size: buttonSize * 0.25,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'your image',
                          style: TextStyle(
                            fontSize: isMobile ? 8 : 10,
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
    final double innerRadius =
        isSelected ? 11 : AppConstants.defaultCardBorderRadius;

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
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 이미지
                    Image.network(
                      imagePath,
                      fit: BoxFit.fitHeight, // 상하가 꽉 차도록 fitHeight 사용
                      alignment: Alignment.center, // 중앙 정렬
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value:
                                loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.backgroundMedium,
                          child: const Center(
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
      },
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
        borderRadius: BorderRadius.circular(
          AppConstants.defaultCardBorderRadius,
        ),
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
              'No image',
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
