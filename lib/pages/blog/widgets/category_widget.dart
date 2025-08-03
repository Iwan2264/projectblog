import 'package:flutter/material.dart';
import 'package:projectblog/pages/blog/category_blogpage.dart';

class CategoriesSection extends StatelessWidget {
  const CategoriesSection({super.key});

  final List<Map<String, String>> categories = const [
    {'title': 'Technology', 'image': 'assets/images/tech.png'},
    {'title': 'Health & Wellness', 'image': 'assets/images/health.png'},
    {'title': 'Finance & Investing', 'image': 'assets/images/finance.png'},
    {'title': 'Travel', 'image': 'assets/images/travel.png'},
    {'title': 'Food & Recipes', 'image': 'assets/images/food.png'},
    {'title': 'Lifestyle & Fashion', 'image': 'assets/images/fashion.png'},
    {'title': 'Business & Marketing', 'image': 'assets/images/business.png'},
    {'title': 'Education', 'image': 'assets/images/education.png'},
    {'title': 'Arts & Culture', 'image': 'assets/images/art.png'},
    {'title': 'Science', 'image': 'assets/images/science.png'},
    {'title': 'Personal Growth', 'image': 'assets/images/growth.png'},
    {'title': 'Sports & Gaming', 'image': 'assets/images/sports.png'},
  ];

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.all(6),
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
            const SizedBox(height: 4),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 0,
                childAspectRatio: 0.7,
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
                        width: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                        height: 80,
                        width: 120,
                        color: color.surfaceContainerHighest,
                        child: Icon(Icons.broken_image, color: color.onSurfaceVariant),
                        ),
                      ),
                      ),
                      const SizedBox(height: 1),
                      SizedBox(
                      width: 100,
                      height: 34,
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
    );
  }
}
