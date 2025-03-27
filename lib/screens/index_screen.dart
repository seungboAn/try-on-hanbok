import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import '../constants/app_constants.dart';
import '../services/app_state.dart';
import '../models/hanbok_image.dart';
import '../widgets/category_filter.dart';
import '../widgets/hanbok_grid.dart';

class IndexScreen extends StatefulWidget {
  const IndexScreen({Key? key}) : super(key: key);

  @override
  State<IndexScreen> createState() => _IndexScreenState();
}

class _IndexScreenState extends State<IndexScreen> {
  static const int _initialItemCount = 12; // 4x3 grid
  int _currentItemCount = _initialItemCount;
  bool _loadingMore = false;

  @override
  Widget build(BuildContext context) {
    final appState = provider.Provider.of<AppState>(context);
    final hanbokImages = appState.getHanboksByCurrentCategory();
    final displayedImages = hanbokImages.take(_currentItemCount).toList();
    final hasMore = hanbokImages.length > _currentItemCount;
    
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero banner section
              _buildHeroBanner(),
              
              Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category filter buttons
                    CategoryFilter(
                      selectedCategory: appState.selectedCategory,
                      onCategorySelected: (category) {
                        appState.setCategory(category);
                        // Reset to initial count when category changes
                        setState(() {
                          _currentItemCount = _initialItemCount;
                        });
                      },
                    ),
                    
                    const SizedBox(height: AppConstants.defaultPadding),
                    
                    // Hanbok grid with limited items
                    appState.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : Column(
                            children: [
                              SizedBox(
                                height: 680, // Fixed height for 4x3 grid
                                child: HanbokGrid(
                                  hanbokImages: displayedImages,
                                  selectedHanbok: null,
                                  onHanbokSelected: (hanbok) {
                                    appState.selectHanbokPreset(hanbok);
                                    appState.setStep(1);
                                  },
                                  crossAxisCount: 4, // 4 items per row
                                ),
                              ),
                              
                              // Load more button
                              if (hasMore)
                                Padding(
                                  padding: const EdgeInsets.only(top: AppConstants.defaultPadding),
                                  child: ElevatedButton(
                                    onPressed: _loadingMore
                                        ? null
                                        : () {
                                            setState(() {
                                              _loadingMore = true;
                                              _currentItemCount += _initialItemCount;
                                              _loadingMore = false;
                                            });
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppConstants.primaryColor,
                                      elevation: 0,
                                      side: BorderSide(color: AppConstants.primaryColor),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppConstants.defaultPadding,
                                        vertical: AppConstants.smallPadding,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                                      ),
                                    ),
                                    child: _loadingMore
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text('Load More'),
                                  ),
                                ),
                            ],
                          ),
                  ],
                ),
              ),
              
              // Steps guide section at bottom
              _buildStepsGuide(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeroBanner() {
    return Stack(
      children: [
        // Hero background image
        Image.asset(
          'data/traditional/16x9_A_full_body_portrait_of_a_female.png',
          width: double.infinity,
          height: 500,
          fit: BoxFit.cover,
        ),
        
        // Gradient overlay for better text readability
        Container(
          width: double.infinity,
          height: 500,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.1),
                Colors.black.withOpacity(0.5),
              ],
            ),
          ),
        ),
        
        // Hero text content
        Positioned(
          left: 40,
          bottom: 100,
          right: 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'We create your own special moments.',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Experience the beauty of Hanbok.',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () {
                    // 바로 PhotoUploadScreen으로 이동
                    final appState = provider.Provider.of<AppState>(context, listen: false);
                    appState.setStep(1);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppConstants.primaryColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    side: BorderSide(color: AppConstants.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    ),
                  ),
                  child: const Text(
                    'Try On Start',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Top logo
        Positioned(
          top: 20,
          left: 20,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.accessibility_new,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Try On\nHanbok',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 3,
                      color: Colors.black45,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Language selector (mock)
        Positioned(
          top: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.language, size: 18),
                SizedBox(width: 4),
                Text('EN'),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildStepsGuide() {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppConstants.largePadding * 2,
        horizontal: AppConstants.largePadding,
      ),
      color: Colors.grey[100],
      child: Column(
        children: [
          const Text(
            'Try On \'Hanbok\' now!',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppConstants.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Experience the beauty of \'Hanbok\'',
            style: TextStyle(
              fontSize: 18,
              color: AppConstants.textColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 60),
          
          // Three steps guide
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepItem(
                title: 'Step 1 select \'hanbok\' image',
                description: 'Choose your favorite \'Hanbok\' image. You can also filter to view only the desired types of Hanbok',
                icon: Icons.checkroom,
                imagePath: 'data/traditional/1 (1).png',
              ),
              _buildStepConnector(),
              _buildStepItem(
                title: 'Step 2 Upload your faces',
                description: 'Upload your face image, and you can change it to a different photo anytime.',
                icon: Icons.face,
                isCenter: true,
              ),
              _buildStepConnector(),
              _buildStepItem(
                title: 'Step 3 Start the Try On!',
                description: 'Click \'Try On!\' to experience Hanbok, and you can download the results anytime.',
                icon: Icons.auto_awesome,
                imagePath: 'data/modern/16x9_A_full_body_portrait_of_one_fema (10).png',
              ),
            ],
          ),
          
          const SizedBox(height: 60),
          SizedBox(
            width: 200,
            child: ElevatedButton(
              onPressed: () {
                // 바로 PhotoUploadScreen으로 이동
                final appState = provider.Provider.of<AppState>(context, listen: false);
                appState.setStep(1);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
              ),
              child: const Text(
                'Try On Start',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStepItem({
    required String title,
    required String description,
    required IconData icon,
    String? imagePath,
    bool isCenter = false,
  }) {
    return Expanded(
      child: Column(
        children: [
          if (imagePath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              child: SizedBox(
                width: 240,
                height: 320,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                ),
              ),
            )
          else if (isCenter)
            SizedBox(
              width: 240,
              height: 320,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(80),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.add,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const Positioned(
                    top: 190,
                    left: 50,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: AssetImage('assets/images/mock_result.png'),
                    ),
                  ),
                  const Positioned(
                    top: 160,
                    right: 50,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: AssetImage('assets/images/mock_result.png'),
                    ),
                  ),
                  const Positioned(
                    bottom: 50,
                    left: 90,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: AssetImage('assets/images/mock_result.png'),
                    ),
                  ),
                  Positioned(
                    top: 150,
                    left: 100,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        'your\nimage',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: AppConstants.textColor.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildStepConnector() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 160),
        Icon(
          Icons.arrow_forward,
          color: Colors.grey[400],
          size: 32,
        ),
      ],
    );
  }
} 