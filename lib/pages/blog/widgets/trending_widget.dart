import 'package:flutter/material.dart';
import 'package:projectblog/models/blog_model.dart';
import 'package:projectblog/pages/blog/widgets/blogcard_widget.dart';

class TrendingBlogsSection extends StatelessWidget {
  final List<BlogModel> blogs;
  const TrendingBlogsSection({super.key, required this.blogs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trending Blogs',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            itemCount: blogs.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return BlogCard(blog: blogs[index]);
            },
          )
        ],
      ),
    );
  }
}
