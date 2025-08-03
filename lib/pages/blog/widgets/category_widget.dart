import 'package:flutter/material.dart';
import 'package:projectblog/pages/blog/category_blogpage.dart';

class CategoriesSection extends StatelessWidget {
  const CategoriesSection({super.key});

  final List<Map<String, String>> categories = const [
    {'title': 'Technology', 'image': 'assets/thumbnail/tech.png'},
    {'title': 'Health & Wellness', 'image': 'assets/thumbnail/health.png'},
    {'title': 'Finance & Investing', 'image': 'assets/thumbnail/finance.png'},
    {'title': 'Travel', 'image': 'assets/thumbnail/travel.png'},
    {'title': 'Food & Recipes', 'image': 'assets/thumbnail/food.png'},
    {'title': 'Lifestyle & Fashion', 'image': 'assets/thumbnail/fashion.png'},
    {'title': 'Business & Marketing', 'image': 'assets/thumbnail/business.png'},
    {'title': 'Education', 'image': 'assets/thumbnail/education.png'},
    {'title': 'Arts & Culture', 'image': 'assets/thumbnail/art.png'},
    {'title': 'Science', 'image': 'assets/thumbnail/science.png'},
    {'title': 'Personal Growth', 'image': 'assets/thumbnail/growth.png'},
    {'title': 'Sports & Gaming', 'image': 'assets/thumbnail/sports.png'},
  ];

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme;

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
                  itemCount: categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 0,
                    childAspectRatio: 0.685,
                  ),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CategoryBlogsPage(categoryName: category['title']!),
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
                                category['title']!,
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