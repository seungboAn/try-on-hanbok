import 'package:flutter/material.dart';
import 'package:try_on_hanbok/constants/exports.dart';
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
  const ResultSection({super.key});

  @override
  State<ResultSection> createState() => _ResultSectionState();
}

class _ResultSectionState extends State<ResultSection> {
  // Result image capturing GlobalKey
  final GlobalKey _resultImageKey = GlobalKey();

  // 각 버튼에 대한 개별적인 상태 변수 추가
  bool _isSavingDownload = false;
  bool _isSavingShare = false;

  // Original image data variable
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

    // Device-specific image container height
    double containerHeight = isMobile ? 320 : (isTablet ? 530 : 740);

    return Column(
      children: [
        // Result image area
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
                  color: AppColors.backgroundLight,
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

        // Spacing between image and buttons - using AppSizes for device-specific spacing
        Builder(
          builder: (context) {
            // Device-specific spacing: 80px for desktop, 60px for tablet, 20px for mobile
            double spacing = 0;
            if (AppSizes.isDesktop(context)) {
              spacing = 80;
            } else if (AppSizes.isTablet(context)) {
              spacing = 60;
            } else {
              spacing = 20; // Mobile
            }
            return SizedBox(height: spacing);
          },
        ),

        // Action button area - show only when result is completed
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
                          _isSavingDownload,
                        ),
                        const SizedBox(height: 20),
                        _buildActionButton(
                          context,
                          'Share',
                          Icons.share,
                          _shareImage,
                          _isSavingShare,
                        ),
                        const SizedBox(height: 20),
                        _buildActionButton(
                          context,
                          'Try On',
                          Icons.refresh,
                          _navigateToGenerate,
                          false,
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
                          _isSavingDownload,
                        ),
                        const SizedBox(width: 50),
                        _buildActionButton(
                          context,
                          'Share',
                          Icons.share,
                          _shareImage,
                          _isSavingShare,
                        ),
                        const SizedBox(width: 50),
                        _buildActionButton(
                          context,
                          'Try On',
                          Icons.refresh,
                          _navigateToGenerate,
                          false,
                        ),
                      ],
                    ),
          ),
      ],
    );
  }

  Widget _buildResultContent(HanbokState hanbokState) {
    if (hanbokState.taskStatus == 'pending' ||
        hanbokState.taskStatus == 'processing') {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 20),
          // 프로그레스 상태 표시를 위한 선형 프로그레스 바 추가
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 40),
          //   child: LinearProgressIndicator(
          //     value: hanbokState.progress,
          //     backgroundColor: AppColors.backgroundLight,
          //     valueColor: const AlwaysStoppedAnimation<Color>(
          //       AppColors.primary,
          //     ),
          //   ),
          // ),
          // const SizedBox(height: 10),
          // 프로그레스 퍼센트 숫자로 표시
          // Text(
          //   '${(hanbokState.progress * 100).toInt()}%',
          //   style: const TextStyle(
          //     color: AppColors.textSecondary,
          //     fontSize: 14,
          //     fontWeight: FontWeight.bold,
          //   ),
          // ),
          const SizedBox(height: 20),
          const Text(
            "Processing hanbok fitting...\nThis may take 10 seconds.",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    if (hanbokState.taskStatus == 'error') {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: 20),
          const Text(
            'Error',
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
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      );
    }

    if (hanbokState.taskStatus == 'completed' &&
        hanbokState.resultImageUrl != null) {
      return Image.network(
        hanbokState.resultImageUrl!,
        fit: BoxFit.fitHeight,
        width: double.infinity,
        height: double.infinity,
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
          return const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, color: AppColors.error, size: 48),
              SizedBox(height: 20),
              Text(
                '이미지 로드 실패',
                style: TextStyle(color: AppColors.error, fontSize: 16),
              ),
            ],
          );
        },
      );
    }

    return const Center(
      child: Text(
        '결과를 기다리는 중...',
        style: TextStyle(color: Colors.grey, fontSize: 16),
      ),
    );
  }

  // Action button widget - 각 버튼별 로딩 상태를 받도록 수정
  Widget _buildActionButton(
    BuildContext context,
    String text,
    IconData icon,
    VoidCallback onPressed,
    bool isLoading,
  ) {
    // Button width uniform to Download button
    final double buttonWidth = 150.0; // Fixed button width setting
    final bool isMobile = AppSizes.isMobile(context);

    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;

        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: AnimatedContainer(
            duration: AppConstants.defaultAnimationDuration,
            width: buttonWidth, // Apply fixed width
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
                onTap: isLoading ? null : onPressed,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child:
                      isLoading
                          ? const Center(
                            // Center loading indicator
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                              ),
                            ),
                          )
                          : Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center, // Center content
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
                                      isMobile
                                          ? 14
                                          : null, // Adjust text size for mobile
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

  // Function to save result image
  Future<void> _saveImage() async {
    if (_isSavingDownload) return;

    setState(() {
      _isSavingDownload = true;
    });

    try {
      // Try to reload original image if not loaded
      if (_originalImageBytes == null) {
        await _loadOriginalImage();
        if (_originalImageBytes == null) {
          _showMessage('Failed to load image.');
          return;
        }
      }

      if (kIsWeb) {
        // Show download popup on web
        _downloadImageForWeb(_originalImageBytes!);
        _showSuccessMessage('Image download has started.');
      } else {
        // Mobile: save to gallery
        try {
          final result = await ImageGallerySaver.saveImage(
            _originalImageBytes!,
            quality: 100,
            name: 'hanbok_tryon_${DateTime.now().millisecondsSinceEpoch}.png',
          );

          // Result confirmation
          if (result['isSuccess'] == true) {
            _showSuccessMessage('Image saved to gallery.');
          } else {
            _showMessage('Failed to save image.');
          }
        } catch (e) {
          _showMessage('Error while saving to gallery: $e');
        }
      }
    } catch (e) {
      _showMessage('An error occurred: $e');
    } finally {
      setState(() {
        _isSavingDownload = false;
      });
    }
  }

  // Web image download processing
  void _downloadImageForWeb(Uint8List bytes) {
    // Convert image to data URL
    final base64 = base64Encode(bytes);
    final url = 'data:image/png;base64,$base64';

    // Create download link
    final anchor =
        html.AnchorElement(href: url)
          ..setAttribute(
            'download',
            'hanbok_tryon_${DateTime.now().millisecondsSinceEpoch}.png',
          )
          ..style.display = 'none';

    // Add link to document and click
    html.document.body?.append(anchor);
    anchor.click();

    // Remove link
    anchor.remove();
  }

  // Image sharing function
  Future<void> _shareImage() async {
    if (_isSavingShare) return;

    setState(() {
      _isSavingShare = true;
    });

    try {
      // Try to reload original image if not loaded
      if (_originalImageBytes == null) {
        await _loadOriginalImage();
        if (_originalImageBytes == null) {
          _showMessage('Failed to load image.');
          return;
        }
      }

      if (kIsWeb) {
        try {
          // Use Web Share API to share (supported browsers only)
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
                'title': 'Hanbok Virtual Fitting',
                'text': 'Sharing my Hanbok virtual fitting image!',
              });
              _showSuccessMessage('Share completed.');
            } catch (e) {
              // When user cancels sharing or error occurs
              _showMessage('Share was canceled or an error occurred.');
            }
          } else {
            // When Share API is not available, provide download as alternative
            if (_originalImageBytes != null) {
              _downloadImageForWeb(_originalImageBytes!);
            }
            _showMessage(
              'Sharing is not supported in this browser. Downloading instead.',
            );
          }
        } catch (e) {
          if (_originalImageBytes != null) {
            _downloadImageForWeb(_originalImageBytes!);
          }
          _showMessage('Error during sharing, downloading instead: $e');
        }
      } else {
        try {
          // Save as temporary file
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/hanbok_share.png');
          await file.writeAsBytes(_originalImageBytes!);

          // Share image
          await Share.shareXFiles([
            XFile(file.path),
          ], text: 'Sharing my Hanbok virtual fitting image!');
          _showSuccessMessage('Share completed.');
        } catch (e) {
          _showMessage('Error while sharing file: $e');
        }
      }
    } catch (e) {
      _showMessage('An error occurred: $e');
    } finally {
      setState(() {
        _isSavingShare = false;
      });
    }
  }

  // Navigate to Generate page (select first preset)
  void _navigateToGenerate() {
    // HanbokState 인스턴스 가져오기
    final hanbokState = context.read<HanbokState>();

    // 현재 사용 가능한 프리셋이 있는지 확인
    if (hanbokState.modernPresets.isNotEmpty) {
      // 모던 프리셋 목록에서 첫 번째 프리셋 사용
      Navigator.pushNamed(
        context,
        AppConstants.generateRoute,
        arguments: hanbokState.modernPresets.first.imagePath, // 첫 번째 프리셋
      );
    } else {
      // 프리셋이 없는 경우 (로딩 실패 등), 기본 하드코딩된 프리셋으로 대체
      Navigator.pushNamed(
        context,
        AppConstants.generateRoute,
        arguments: AppConstants.modernHanbokList[0], // 첫 번째 기본 프리셋
      );
    }
  }

  // Capture widget as image (keep for UI capture if needed)
  Future<Uint8List?> _captureImage() async {
    try {
      final RenderRepaintBoundary boundary =
          _resultImageKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;

      // Render image capture
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }
    } catch (e) {
      debugPrint('Error capturing image: $e');
    }
    return null;
  }

  // 일반 메시지 표시
  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.primary),
    );
  }

  // 성공 메시지 표시 (초록색 배경)
  void _showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }
}
