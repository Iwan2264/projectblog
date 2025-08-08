import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../category_blogpage.dart';
import '../../../controllers/blog_controller.dart';

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
      'image': categoryImages[category] ?? 'assets/thumbnail/tech.png', // Default to tech if not found
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
        padding: const EdgeInsets.only(left: 6, right: 6, top: 6, bottom: 0),
        child: Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(6),
          color: color.surface,
          child: Container(
            decoration: BoxDecoration(
              color: color.surface,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: color.shadow.withAlpha((0.08 * 255).toInt()),
                  blurRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.only(top: 6, left: 6, right: 6, bottom: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Blog Category',
                  style: textStyle.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: availableCategories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 10, // Added some vertical spacing to accommodate all categories
                    childAspectRatio: 0.685,
                  ),
                  itemBuilder: (context, index) {
                    final categoryName = availableCategories[index];
                    final category = getCategoryImage(categoryName);
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CategoryBlogsPage(categoryName: categoryName),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.asset(
                              category['image']!,
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 80,
                                width: 80,
                                color: color.surfaceContainerHighest,
                                child: Icon(Icons.broken_image, color: color.onSurfaceVariant),
                              ),
                            ),
                          ),
                          const SizedBox(height: 1),
                          SizedBox(
                            width: 100,
                            height: 35,
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Text(
                                categoryName,
                                textAlign: TextAlign.center,
                                style: textStyle.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: color.onSurface,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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