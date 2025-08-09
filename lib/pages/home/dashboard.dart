import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/blog_controller.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final BlogController blogController = Get.find<BlogController>();
    
    return Obx(() {
      // Calculate real data
      final totalBlogs = blogController.userPublishedPosts.length;
      final totalViews = blogController.userPublishedPosts.fold<int>(
        0, (sum, blog) => sum + blog.viewsCount
      );
      final totalLikes = blogController.userPublishedPosts.fold<int>(
        0, (sum, blog) => sum + blog.likesCount
      );
      const profileViews = 0; // Placeholder as no profile is created
      
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 3,
        children: [
          DashboardCard(title: "Total Blogs", value: totalBlogs.toString(), icon: Icons.article),
          DashboardCard(title: "Total Views", value: totalViews.toString(), icon: Icons.visibility),
          DashboardCard(title: "My Likes", value: totalLikes.toString(), icon: Icons.favorite),
          DashboardCard(title: "Profile Views", value: profileViews.toString(), icon: Icons.person),
        ],
      );
    });
  }
}
class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // Vertically center
        mainAxisAlignment: MainAxisAlignment.start, // Left align horizontally
        children: [
          Icon(icon, size: 32, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center, // Vertically center
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}