import 'package:flutter/material.dart';
import 'package:projectblog/models/blog_model.dart';
import 'package:projectblog/pages/blog/blog_page.dart';
import 'package:projectblog/pages/blog/widgets/blogcard_widget.dart';

class CategoryBlogsPage extends StatelessWidget {
  final String categoryName;
  const CategoryBlogsPage({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    final List<BlogModel> filteredBlogs = dummyBlogs
        .where((blog) => blog.category == categoryName)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
      ),
      body: filteredBlogs.isEmpty
          ? Center(
              child: Text(
                'No blogs found in this category yet.',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredBlogs.length,
              itemBuilder: (context, index) {
                return BlogCard(blog: filteredBlogs[index]);
              },
            ),
    );
  }
}