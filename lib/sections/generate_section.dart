import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:test02/constants/exports.dart';
import 'package:provider/provider.dart';
import 'package:supabase_services/hanbok_state.dart';
import 'package:image_picker/image_picker.dart';

class GenerateSection extends StatefulWidget {
  final String? selectedHanbok;

  const GenerateSection({Key? key, this.selectedHanbok}) : super(key: key);

  @override
  _GenerateSectionState createState() => _GenerateSectionState();
}

class _GenerateSectionState extends State<GenerateSection> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });

        final hanbokState = context.read<HanbokState>();
        await hanbokState.uploadUserImage(bytes, 'image/jpeg');

        if (hanbokState.taskStatus == 'error') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(hanbokState.errorMessage ?? 'Failed to upload image')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hanbokState = Provider.of<HanbokState>(context);
    final uploadedImageUrl = hanbokState.uploadedImageUrl;
    
    return Column(
      children: [
        // Image preview section
        Container(
          width: double.infinity,
          height: 400,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              // User image section
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundMedium,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border, width: 0.2),
                  ),
                  child: uploadedImageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            uploadedImageUrl,
                            fit: BoxFit.contain,
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
                        )
                      : InkWell(
                          onTap: _pickImage,
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 48,
                                  color: Color(0xFFAAAAAA),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  '사진을 선택해주세요',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFFAAAAAA),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 24),
              // Hanbok image section
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundMedium,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border, width: 0.2),
                  ),
                  child: widget.selectedHanbok != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            widget.selectedHanbok!,
                            fit: BoxFit.contain,
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
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 48,
                                color: Color(0xFFAAAAAA),
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
                        ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildTryOnButton(),
      ],
    );
  }

  Widget _buildTryOnButton() {
    return Container(
      width: double.infinity,
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: ElevatedButton(
        onPressed: () async {
          final hanbokState = context.read<HanbokState>();
          final uploadedImageUrl = hanbokState.uploadedImageUrl;
          final selectedHanbok = widget.selectedHanbok;

          if (uploadedImageUrl == null || selectedHanbok == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('사진과 한복을 모두 선택해주세요.'),
              ),
            );
            return;
          }

          try {
            await hanbokState.generateHanbokFitting(selectedHanbok);
            if (mounted) {
              Navigator.pushNamed(context, AppConstants.resultRoute);
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('가상 피팅에 실패했습니다: ${e.toString()}')),
              );
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Try On',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}