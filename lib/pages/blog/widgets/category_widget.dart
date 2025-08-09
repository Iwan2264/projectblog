import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math';

import '../category_blogpage.dart';
import '../../../controllers/blog_controller.dart';
import '../../../utils/navigation_helper.dart';

class CategoriesSection extends StatelessWidget {
  const CategoriesSection({super.key});

  // Map category names to their image assets
  Map<String, String> getCategoryImage(String category) {
    final Map<String, String> categoryImages = {
      'Technology': 'assets/thumbnail/tech.png',
      'Health & Wellness': 'assets/thumbnail/health.png',
      'Finance & Investing': 'assets/thumbnail/finance.png',
      'Travel': 'assets/thumbnail/travel.png',
      'Food & Recipes': 'assets/thumbnail/food.png',
      'Lifestyle & Fashion': 'assets/thumbnail/fashion.png',
      'Business & Marketing': 'assets/thumbnail/business.png',
      'Education': 'assets/thumbnail/education.png',
      'Arts & Culture': 'assets/thumbnail/art.png',
      'Science': 'assets/thumbnail/science.png',
      'Personal Growth': 'assets/thumbnail/growth.png',
      'Sports & Gaming': 'assets/thumbnail/sports.png',
    };

    return {
      'title': category,
      'image': categoryImages[category] ?? 'assets/thumbnail/tech.png', // Default image
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme;
    final BlogController blogController = Get.find<BlogController>();
    final List<String> availableCategories = blogController.availableCategories;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(8),
          color: color.surface,
          shadowColor: color.shadow.withAlpha((0.08 * 255).toInt()),
          child: Container(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                  child: Text(
                    'Blog Categories',
                    style: textStyle.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color.onSurface,
                    ),
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = constraints.maxWidth;
                    
                    // Define responsive grid properties, starting with 4 columns as default
                    int crossAxisCount;
                    double spacing;
                    double childAspectRatio;

                    if (screenWidth > 900) {
                      crossAxisCount = 6;
                      spacing = 12;
                      childAspectRatio = 0.9;
                    } else if (screenWidth > 600) {
                      crossAxisCount = 5;
                      spacing = 10;
                      childAspectRatio = 0.85;
                    } else {
                      // Default to 4 columns for mobile and smaller screens
                      crossAxisCount = 4;
                      spacing = 8;
                      childAspectRatio = 0.8;
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      // Limit to 12 items to create a 4x3 grid by default
                      itemCount: min(12, availableCategories.length),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        childAspectRatio: childAspectRatio,
                      ),
                      itemBuilder: (context, index) {
                        final categoryName = availableCategories[index];
                        final category = getCategoryImage(categoryName);
                        return GestureDetector(
                          onTap: () {
                            NavigationHelper.toPage(CategoryBlogsPage(categoryName: categoryName));
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Compact image size
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  category['image']!,
                                  height: 60,
                                  width: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 60,
                                    width: 60,
                                    color: color.surfaceContainerHighest,
                                    child: Icon(Icons.broken_image, color: color.onSurfaceVariant),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Compact text container
                              SizedBox(
                                height: 30, // Reduced height for text
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: Text(
                                    categoryName,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: textStyle.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: color.onSurface,
                                      fontSize: 11, // Smaller font
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
