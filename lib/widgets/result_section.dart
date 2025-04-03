import 'package:flutter/material.dart';
import 'package:test02/constants/exports.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'package:provider/provider.dart';
import 'package:supabase_services/hanbok_state.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// 웹에서만 사용할 라이브러리
// ignore: depend_on_referenced_packages
import 'package:image_gallery_saver/image_gallery_saver.dart';
// ignore: depend_on_referenced_packages
import 'package:share_plus/share_plus.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider/path_provider.dart';

class ResultSection extends StatefulWidget {
  const ResultSection({Key? key}) : super(key: key);

  @override
  State<ResultSection> createState() => _ResultSectionState();
}

class _ResultSectionState extends State<ResultSection> {
  // 결과 이미지를 캡처하기 위한 GlobalKey
  final GlobalKey _resultImageKey = GlobalKey();
  bool _isSaving = false;
  // 원본 이미지 데이터를 저장하기 위한 변수
  Uint8List? _originalImageBytes;

  @override
  void initState() {
    super.initState();
    _loadOriginalImage();
  }

  Future<void> _loadOriginalImage() async {
    final hanbokState = context.read<HanbokState>();
    if (hanbokState.resultImageUrl != null) {
      try {
        final response = await http.get(Uri.parse(hanbokState.resultImageUrl!));
        if (response.statusCode == 200) {
          setState(() {
            _originalImageBytes = response.bodyBytes;
          });
        }
      } catch (e) {
        debugPrint('Error loading result image: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = AppSizes.isMobile(context);
    bool isTablet = AppSizes.isTablet(context);
    final hanbokState = context.watch<HanbokState>();

    // 디바이스별 이미지 컨테이너 높이 설정
    double containerHeight = isMobile ? 500 : (isTablet ? 700 : 900);

    return Column(
      children: [
        // 결과 이미지 영역
        RepaintBoundary(
          key: _resultImageKey,
          child: Container(
            width: double.infinity,
            height: containerHeight,
            padding: EdgeInsets.zero,
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border, width: 0.2),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundMedium,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border, width: 0.2),
                ),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: isMobile ? 300 : 800,
                      ),
                      child: _buildResultContent(hanbokState),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // 이미지와 버튼 사이 간격 - AppSizes 사용하여 디바이스별 간격 설정
        Builder(
          builder: (context) {
            // 디바이스별 간격 설정: 웹 80px, 태블릿 60px, 모바일 20px
            double spacing = 0;
            if (AppSizes.isDesktop(context)) {
              spacing = 80;
            } else if (AppSizes.isTablet(context)) {
              spacing = 60;
            } else {
              spacing = 20; // 모바일
            }
            return SizedBox(height: spacing);
          },
        ),

        // 액션 버튼 영역 - 결과가 완료되었을 때만 표시
        if (hanbokState.taskStatus == 'completed')
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 0),
            child:
                isMobile
                    ? Column(
                      children: [
                        _buildActionButton(
                          context,
                          'Download',
                          Icons.download,
                          _saveImage,
                        ),
                        const SizedBox(height: 20),
                        _buildActionButton(
                          context,
                          'Share',
                          Icons.share,
                          _shareImage,
                        ),
                        const SizedBox(height: 20),
                        _buildActionButton(
                          context,
                          'Try On',
                          Icons.refresh,
                          _navigateToGenerate,
                        ),
                      ],
                    )
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildActionButton(
                          context,
                          'Download',
                          Icons.download,
                          _saveImage,
                        ),
                        const SizedBox(width: 50),
                        _buildActionButton(
                          context,
                          'Share',
                          Icons.share,
                          _shareImage,
                        ),
                        const SizedBox(width: 50),
                        _buildActionButton(
                          context,
                          'Try On',
                          Icons.refresh,
                          _navigateToGenerate,
                        ),
                      ],
                    ),
          ),
      ],
    );
  }

  Widget _buildResultContent(HanbokState hanbokState) {
    if (hanbokState.isLoading || hanbokState.taskStatus == 'processing') {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            '한복 가상 피팅 중입니다...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      );
    }

    if (hanbokState.taskStatus == 'error') {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 48,
          ),
          const SizedBox(height: 20),
          Text(
            '오류가 발생했습니다',
            style: TextStyle(
              color: AppColors.error,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (hanbokState.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                hanbokState.errorMessage!,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      );
    }

    if (hanbokState.taskStatus == 'completed' && hanbokState.resultImageUrl != null) {
      return Image.network(
        hanbokState.resultImageUrl!,
        fit: BoxFit.fitHeight,
        width: double.infinity,
        height: double.infinity,
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
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image,
                color: AppColors.error,
                size: 48,
              ),
              const SizedBox(height: 20),
              Text(
                '이미지를 불러올 수 없습니다',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 16,
                ),
              ),
            ],
          );
        },
      );
    }

    return const Center(
      child: Text(
        '결과를 기다리는 중입니다...',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 16,
        ),
      ),
    );
  }

  // 액션 버튼 위젯
  Widget _buildActionButton(
    BuildContext context,
    String text,
    IconData icon,
    VoidCallback onPressed,
  ) {
    // 모든 버튼의 너비를 Download 버튼 기준으로 통일
    final double buttonWidth = 150.0; // 모든 버튼의 고정 너비 설정
    final bool isMobile = AppSizes.isMobile(context);

    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;

        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: AnimatedContainer(
            duration: AppConstants.defaultAnimationDuration,
            width: buttonWidth, // 고정 너비 적용
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
                onTap: _isSaving ? null : onPressed,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child:
                      _isSaving && (text == 'Download' || text == 'Share')
                          ? Center(
                            // 로딩 인디케이터 중앙 정렬
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.textSecondary,
                                ),
                              ),
                            ),
                          )
                          : Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center, // 내용 중앙 정렬
                            children: [
                              Icon(
                                icon,
                                size: 16,
                                color:
                                    isHovered
                                        ? AppColors.textButton
                                        : AppColors.textPrimary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                text,
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
                                      isMobile ? 14 : null, // 모바일에서 텍스트 크기 조정
                                ),
                              ),
                            ],
                          ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // 결과 이미지 저장 함수
  Future<void> _saveImage() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // 원본 이미지 바이트가 로드되지 않았을 경우 다시 로드 시도
      if (_originalImageBytes == null) {
        await _loadOriginalImage();
        if (_originalImageBytes == null) {
          _showMessage('이미지를 불러올 수 없습니다.');
          return;
        }
      }

      if (kIsWeb) {
        // 웹에서는 다운로드 팝업을 표시
        _downloadImageForWeb(_originalImageBytes!);
        _showMessage('이미지 다운로드가 시작되었습니다.');
      } else {
        // 모바일에서는 갤러리에 저장
        try {
          final result = await ImageGallerySaver.saveImage(
            _originalImageBytes!,
            quality: 100,
            name: 'hanbok_tryon_${DateTime.now().millisecondsSinceEpoch}.png',
          );

          // 결과 확인
          if (result['isSuccess'] == true) {
            _showMessage('이미지가 갤러리에 저장되었습니다.');
          } else {
            _showMessage('이미지 저장에 실패했습니다.');
          }
        } catch (e) {
          _showMessage('갤러리 저장 중 오류: $e');
        }
      }
    } catch (e) {
      _showMessage('오류가 발생했습니다: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // 웹에서 이미지 다운로드 처리
  void _downloadImageForWeb(Uint8List bytes) {
    // 이미지를 data URL로 변환
    final base64 = base64Encode(bytes);
    final url = 'data:image/png;base64,$base64';

    // 다운로드 링크 생성
    final anchor =
        html.AnchorElement(href: url)
          ..setAttribute(
            'download',
            'hanbok_tryon_${DateTime.now().millisecondsSinceEpoch}.png',
          )
          ..style.display = 'none';

    // 문서에 링크 추가 및 클릭
    html.document.body?.append(anchor);
    anchor.click();

    // 링크 제거
    anchor.remove();
  }

  // 이미지 공유 함수
  Future<void> _shareImage() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // 원본 이미지 바이트가 로드되지 않았을 경우 다시 로드 시도
      if (_originalImageBytes == null) {
        await _loadOriginalImage();
        if (_originalImageBytes == null) {
          _showMessage('이미지를 불러올 수 없습니다.');
          return;
        }
      }

      if (kIsWeb) {
        try {
          // 웹에서 Web Share API를 사용하여 공유 (지원되는 브라우저에서만)
          final navigatorObj = html.window.navigator;
          final hasShareApi = navigatorObj.share != null;

          if (hasShareApi) {
            try {
              final blob = html.Blob([_originalImageBytes ?? Uint8List(0)]);
              final file = html.File(
                [blob],
                'hanbok_tryon.png',
                {'type': 'image/png'},
              );

              await navigatorObj.share({
                'files': [file],
                'title': '한복 가상 피팅',
                'text': '한복 가상 피팅 이미지를 공유합니다!',
              });
              _showMessage('공유가 완료되었습니다.');
            } catch (e) {
              // 사용자가 공유를 취소하거나 오류 발생 시
              _showMessage('공유가 취소되었거나 오류가 발생했습니다.');
            }
          } else {
            // Share API를 사용할 수 없는 경우 대체 방법으로 다운로드 제공
            if (_originalImageBytes != null) {
              _downloadImageForWeb(_originalImageBytes!);
            }
            _showMessage('이 브라우저에서는 공유가 지원되지 않아 다운로드를 대신 진행합니다.');
          }
        } catch (e) {
          if (_originalImageBytes != null) {
            _downloadImageForWeb(_originalImageBytes!);
          }
          _showMessage('공유 중 오류가 발생하여 다운로드로 대체합니다: $e');
        }
      } else {
        try {
          // 임시 파일로 저장
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/hanbok_share.png');
          await file.writeAsBytes(_originalImageBytes!);

          // 이미지 공유
          await Share.shareXFiles([
            XFile(file.path),
          ], text: '한복 가상 피팅 이미지를 공유합니다!');
        } catch (e) {
          _showMessage('파일 공유 중 오류: $e');
        }
      }
    } catch (e) {
      _showMessage('오류가 발생했습니다: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // Generate 페이지로 이동 (첫 번째 프리셋 선택)
  void _navigateToGenerate() {
    // 첫 번째 모던 한복 프리셋을 선택해서 이동
    Navigator.pushNamed(
      context,
      AppConstants.generateRoute,
      arguments: AppConstants.modernHanbokList[0], // 첫 번째 프리셋 지정
    );
  }

  // 위젯을 이미지로 캡처 (필요시 UI 캡처용으로 유지)
  Future<Uint8List?> _captureImage() async {
    try {
      final RenderRepaintBoundary boundary =
          _resultImageKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;

      // 렌더링된 이미지 캡처
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }
    } catch (e) {
      debugPrint('이미지 캡처 중 오류: $e');
    }
    return null;
  }

  // 메시지 표시
  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
