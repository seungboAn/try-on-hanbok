import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import '../constants/app_constants.dart';
import '../services/app_state.dart';
import '../widgets/hanbok_grid.dart';

class HanbokSelectionScreen extends StatelessWidget {
  const HanbokSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = provider.Provider.of<AppState>(context);
    final hanbokImages = appState.getHanboksByCategory(appState.selectedCategory);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppConstants.primaryColor.withOpacity(0.2),
              radius: 18,
              child: Icon(
                Icons.accessibility_new,
                color: AppConstants.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Try On\nHanbok',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                height: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: Colors.grey[200],
              radius: 16,
              child: const Text('EN', style: TextStyle(fontSize: 12, color: Colors.black87)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Step 2: Choose your hanbok',
                style: AppConstants.headingStyle,
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              
              // Category selection
              Row(
                children: [
                  _buildCategoryButton(
                    context: context,
                    category: 'traditional',
                    label: 'Traditional',
                    isSelected: appState.selectedCategory == 'traditional',
                  ),
                  const SizedBox(width: AppConstants.defaultPadding),
                  _buildCategoryButton(
                    context: context,
                    category: 'modern',
                    label: 'Modern',
                    isSelected: appState.selectedCategory == 'modern',
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              
              // Hanbok grid
              Expanded(
                child: appState.isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
                        ),
                      )
                    : hanbokImages.isEmpty
                        ? const Center(
                            child: Text(
                              'No hanbok images available for this category',
                              style: AppConstants.bodyStyle,
                              textAlign: TextAlign.center,
                            ),
                          )
                        : HanbokGrid(
                            hanbokImages: hanbokImages,
                            onHanbokSelected: (hanbok) {
                              appState.selectHanbok(hanbok);
                              Navigator.pushNamed(context, '/result');
                            },
                          ),
              ),
              
              const SizedBox(height: AppConstants.defaultPadding),
              
              // Back button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppConstants.primaryColor,
                    elevation: 0,
                    side: BorderSide(color: AppConstants.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    ),
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryButton({
    required BuildContext context,
    required String category,
    required String label,
    required bool isSelected,
  }) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          provider.Provider.of<AppState>(context, listen: false).setCategory(category);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? AppConstants.primaryColor : Colors.white,
          foregroundColor: isSelected ? Colors.white : AppConstants.primaryColor,
          elevation: 0,
          side: BorderSide(
            color: isSelected ? Colors.transparent : AppConstants.primaryColor,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
} 