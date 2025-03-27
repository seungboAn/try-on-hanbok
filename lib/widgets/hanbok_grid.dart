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
    this.crossAxisCount = 2,
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
        childAspectRatio: 0.7,
        crossAxisSpacing: AppConstants.defaultPadding,
        mainAxisSpacing: AppConstants.defaultPadding,
      ),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: hanbokImages.length,
      itemBuilder: (context, index) {
        final hanbok = hanbokImages[index];
        final isSelected = selectedHanbok?.id == hanbok.id;
        
        return GestureDetector(
          onTap: () => onHanbokSelected(hanbok),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? AppConstants.primaryColor : AppConstants.borderColor,
                width: isSelected ? 2.0 : 1.0,
              ),
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius - 1),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: hanbok.imagePath,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.error),
                      ),
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppConstants.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
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
} 