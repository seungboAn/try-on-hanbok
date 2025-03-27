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
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCategoryButton('traditional', 'Traditional'),
          _buildCategoryButton('modern', 'Modern'),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(String category, String label) {
    final isSelected = selectedCategory == category;
    
    return GestureDetector(
      onTap: () => onCategorySelected(category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppConstants.textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}