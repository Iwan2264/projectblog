import 'package:flutter/material.dart';
import 'package:projectblog/models/blog_model.dart';
import 'package:projectblog/pages/blog/widgets/blogcard_widget.dart';

class TrendingBlogsSection extends StatelessWidget {
  final List<BlogModel> blogs;
  const TrendingBlogsSection({super.key, required this.blogs});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme;
      
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(left: 6, right: 6, top: 2, bottom: 3),
        child: Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(6),
          color: color.surface,
          child: Container(
            //margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: color.surface,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: color.shadow.withAlpha((0.08 * 255).toInt()),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.only(left: 6, right: 6, top: 2, bottom: 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trending Blogs',
                  style: textStyle.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color.onSurface,
                  ),
                ),
                const SizedBox(height:2),
                ListView.builder(
                  itemCount: blogs.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return BlogCard(blog: blogs[index]);
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