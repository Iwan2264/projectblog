import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:projectblog/models/blog_post_model.dart';
import 'package:projectblog/controllers/blog_controller.dart';
import 'package:projectblog/pages/blog/widgets/blog_post_card.dart';

class CategoryBlogsPage extends StatefulWidget {
  final String categoryName;
  const CategoryBlogsPage({super.key, required this.categoryName});

  @override
  State<CategoryBlogsPage> createState() => _CategoryBlogsPageState();
}

class _CategoryBlogsPageState extends State<CategoryBlogsPage> {
  final BlogController _blogController = Get.find<BlogController>();
  List<BlogPostModel> categoryBlogs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategoryBlogs();
  }

  Future<void> _loadCategoryBlogs() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      final blogs = await _blogController.getBlogsByCategory(widget.categoryName);
      setState(() {
        categoryBlogs = blogs;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      
      // Show an error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load blogs for this category'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadCategoryBlogs,
              child: categoryBlogs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No blogs found in ${widget.categoryName} category yet.',
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Be the first to publish in this category!',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: categoryBlogs.length,
                      itemBuilder: (context, index) {
                        return BlogPostCard(blog: categoryBlogs[index]);
                      },
                    ),
            ),
    );
  }
}