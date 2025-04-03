import 'package:flutter/material.dart';
import 'package:test02/constants/exports.dart';
import 'package:provider/provider.dart';
import 'package:supabase_services/hanbok_state.dart';
import 'package:supabase_services/models/hanbok_image.dart';

class SelectSection extends StatefulWidget {
  final Function(String)? onImageClick;
  final String? selectedImage;

  const SelectSection({
    Key? key,
    this.onImageClick,
    this.selectedImage,
  }) : super(key: key);

  @override
  State<SelectSection> createState() => _SelectSectionState();
}

class _SelectSectionState extends State<SelectSection> {
  String? _selectedFilter;

  @override
  void initState() {
    super.initState();
    // Ensure the HanbokState is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final hanbokState = context.read<HanbokState>();
      if (hanbokState.modernPresets.isEmpty && hanbokState.traditionalPresets.isEmpty) {
        hanbokState.initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HanbokState>(
      builder: (context, hanbokState, child) {
        if (hanbokState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final modernPresets = hanbokState.modernPresets;
        final traditionalPresets = hanbokState.traditionalPresets;
        final allPresets = [...modernPresets, ...traditionalPresets];

        final filteredPresets = _selectedFilter == AppConstants.filterModern
            ? modernPresets
            : _selectedFilter == AppConstants.filterTraditional
                ? traditionalPresets
                : allPresets;

        return Column(
          children: [
            // Filter buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildFilterButton(AppConstants.filterModern),
                  const SizedBox(width: 12),
                  _buildFilterButton(AppConstants.filterTraditional),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Grid of hanbok images
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: filteredPresets.length,
                itemBuilder: (context, index) {
                  final preset = filteredPresets[index];
                  return _buildHanbokCard(preset);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterButton(String filter) {
    final isSelected = _selectedFilter == filter;
    
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedFilter = isSelected ? null : filter;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.primary : AppColors.background,
        foregroundColor: isSelected ? Colors.white : AppColors.textPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(filter),
    );
  }

  Widget _buildHanbokCard(HanbokImage preset) {
    final isSelected = widget.selectedImage == preset.imagePath;

    return InkWell(
      onTap: () {
        if (widget.onImageClick != null) {
          widget.onImageClick!(preset.imagePath);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Image.network(
            preset.imagePath,
            fit: BoxFit.cover,
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
    );
  }
} 