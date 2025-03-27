import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_constants.dart';
import '../models/hanbok_image.dart';

class HanbokGrid extends StatelessWidget {
  final List<HanbokImage> hanbokImages;
  final HanbokImage? selectedHanbok;
  final Function(HanbokImage) onHanbokSelected;
  final int crossAxisCount;

  const HanbokGrid({
    Key? key,
    required this.hanbokImages,
    required this.selectedHanbok,
    required this.onHanbokSelected,
    this.crossAxisCount = 2, // Default to 2 columns, but now customizable
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (hanbokImages.isEmpty) {
      return const Center(
        child: Text(
          'No hanbok images available',
          style: AppConstants.bodyStyle,
        ),
      );
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.7, // Portrait orientation for hanbok images
        crossAxisSpacing: AppConstants.defaultPadding,
        mainAxisSpacing: AppConstants.defaultPadding,
      ),
      physics: const NeverScrollableScrollPhysics(), // Disable GridView scrolling for fixed height
      itemCount: hanbokImages.length,
      itemBuilder: (context, index) {
        final hanbok = hanbokImages[index];
        final isSelected = selectedHanbok?.id == hanbok.id;
        
        return GestureDetector(
          onTap: () => onHanbokSelected(hanbok),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected
                    ? AppConstants.primaryColor
                    : AppConstants.borderColor,
                width: isSelected ? 3.0 : 1.0,
              ),
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppConstants.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                isSelected
                    ? AppConstants.borderRadius - 2
                    : AppConstants.borderRadius - 1,
              ),
              child: Stack(
                children: [
                  // Image
                  Positioned.fill(
                    child: _buildHanbokImage(hanbok),
                  ),
                  
                  // Selection overlay indicator
                  if (isSelected)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildHanbokImage(HanbokImage hanbok) {
    try {
      return Image.asset(
        hanbok.imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image: ${hanbok.imagePath}, error: $error');
          // Fallback to a placeholder
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: Icon(
                Icons.image_not_supported,
                size: 40,
                color: Colors.grey,
              ),
            ),
          );
        },
      );
    } catch (e) {
      print('Exception loading image: ${hanbok.imagePath}, error: $e');
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(
            Icons.broken_image,
            size: 40,
            color: Colors.grey,
          ),
        ),
      );
    }
  }
}