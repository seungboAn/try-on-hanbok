import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class CategoryFilter extends StatelessWidget {
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const CategoryFilter({
    Key? key,
    required this.selectedCategory,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _buildCategoryButton('all', 'All'),
        const SizedBox(width: AppConstants.smallPadding),
        _buildCategoryButton('traditional', 'Traditional'),
        const SizedBox(width: AppConstants.smallPadding),
        _buildCategoryButton('modern', 'Modern'),
      ],
    );
  }

  Widget _buildCategoryButton(String category, String label) {
    final isSelected = selectedCategory == category;
    
    return ElevatedButton(
      onPressed: () => onCategorySelected(category),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? AppConstants.primaryColor
            : AppConstants.secondaryColor,
        foregroundColor: isSelected ? Colors.white : AppConstants.textColor,
        elevation: isSelected ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.defaultPadding,
          vertical: AppConstants.smallPadding,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : AppConstants.textColor,
        ),
      ),
    );
  }
} 