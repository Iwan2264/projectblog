import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/blog_post_model.dart';
import '../../controllers/blog_controller.dart';
import 'widgets/category_widget.dart';
import 'widgets/trending_widget.dart';

class BlogHomePage extends StatefulWidget {
  const BlogHomePage({super.key});

  @override
  State<BlogHomePage> createState() => _BlogHomePageState();
}

class _BlogHomePageState extends State<BlogHomePage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final BlogController _blogController = Get.find<BlogController>();
  List<BlogPostModel> recentBlogs = [];
  List<BlogPostModel> trendingBlogs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlogs();
  }

  Future<void> _loadBlogs() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Load recent blogs
      await _blogController.loadRecentBlogs();
      
      // Load popular blogs for the trending section
      final popularBlogs = await _blogController.getPopularBlogs();
      
      setState(() {
        recentBlogs = _blogController.recentBlogs;
        trendingBlogs = popularBlogs;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      
      // Show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load blogs'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Discover Blogs',
          style: theme.textTheme.titleLarge,
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              // Implement search functionality
            },
            icon: Icon(Icons.search, color: theme.colorScheme.primary),
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : RefreshIndicator(
                onRefresh: _loadBlogs,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CategoriesSection(),
                      const SizedBox(height: 10),
                      TrendingBlogsSection(blogs: trendingBlogs),
                    ],
                  ),
                ),
              ),
      ),
      backgroundColor: theme.colorScheme.surface,
    );
  }
}