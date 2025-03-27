import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../constants/app_constants.dart';
import '../models/hanbok_image.dart';
import '../services/hanbok_service.dart';
import '../widgets/category_filter.dart';
import '../widgets/hanbok_grid.dart';

class HanbokSelectionScreen extends StatefulWidget {
  const HanbokSelectionScreen({Key? key}) : super(key: key);

  @override
  State<HanbokSelectionScreen> createState() => _HanbokSelectionScreenState();
}

class _HanbokSelectionScreenState extends State<HanbokSelectionScreen> {
  final HanbokService _hanbokService = HanbokService();
  List<HanbokImage> _displayedImages = [];
  bool _hasMore = false;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadInitialImages();
  }

  void _loadInitialImages() {
    final appState = Provider.of<AppState>(context, listen: false);
    final category = appState.selectedCategory;
    final page = appState.currentPage;
    final pageSize = appState.pageSize;
    
    final allImages = category == 'traditional' 
        ? _hanbokService.traditionalHanbokImages 
        : _hanbokService.modernHanbokImages;
    
    // Calculate current page's images
    final startIndex = 0;
    final endIndex = page * pageSize;
    
    setState(() {
      _displayedImages = allImages.sublist(
        startIndex, 
        endIndex > allImages.length ? allImages.length : endIndex
      );
      _hasMore = allImages.length > endIndex;
    });
  }

  void _loadMoreImages() {
    setState(() {
      _loadingMore = true;
    });
    
    final appState = Provider.of<AppState>(context, listen: false);
    appState.nextPage();
    
    // Simulate network delay
    Future.delayed(const Duration(milliseconds: 800), () {
      final category = appState.selectedCategory;
      final page = appState.currentPage;
      final pageSize = appState.pageSize;
      
      final allImages = category == 'traditional' 
          ? _hanbokService.traditionalHanbokImages 
          : _hanbokService.modernHanbokImages;
      
      final endIndex = page * pageSize;
      
      setState(() {
        _displayedImages = allImages.sublist(
          0, 
          endIndex > allImages.length ? allImages.length : endIndex
        );
        _hasMore = allImages.length > endIndex;
        _loadingMore = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Hanbok'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose your favorite hanbok style',
                    style: AppConstants.bodyStyle,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  
                  // Category filter buttons
                  CategoryFilter(
                    selectedCategory: appState.selectedCategory,
                    onCategorySelected: (category) {
                      appState.selectCategory(category);
                      _loadInitialImages();
                    },
                  ),
                ],
              ),
            ),
            
            // Hanbok grid with scrolling
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: Column(
                    children: [
                      // Grid of hanbok images
                      HanbokGrid(
                        hanbokImages: _displayedImages,
                        selectedHanbok: appState.selectedHanbok,
                        onHanbokSelected: (hanbok) {
                          appState.selectHanbok(hanbok);
                        },
                        crossAxisCount: 2, // 2 items per row for mobile
                      ),
                      
                      // Load more button
                      if (_hasMore)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppConstants.defaultPadding),
                          child: _loadingMore
                              ? const CircularProgressIndicator()
                              : TextButton.icon(
                                  onPressed: _loadMoreImages,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Load More'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppConstants.primaryColor,
                                  ),
                                ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Bottom action button
            Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: ElevatedButton(
                onPressed: appState.selectedHanbok != null
                    ? () => Navigator.pushNamed(context, '/photo-upload')
                    : null,
                child: const Text('Continue to Upload Photo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}