import 'package:flutter/material.dart';
import 'package:projectblog/models/blog_model.dart';
import 'package:projectblog/pages/blog/widgets/category_widget.dart';
import 'package:projectblog/pages/blog/widgets/trending_widget.dart';

// Example dummy data
final List<BlogModel> dummyBlogs = [
  BlogModel(
    id: '1',
    authorId: 'user1',
    authorUsername: 'Jane Doe',
    authorPhotoURL: 'https://i.pravatar.cc/150?img=5',
    title: 'The Ultimate Guide to Flutter Performance',
    content: 'Flutter is a powerful cross-platform toolkit...',
    imageURL: 'https://placehold.co/600x400/7E57C2/FFFFFF/png?text=Flutter',
    tags: ['Flutter', 'Performance'],
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    likesCount: 102,
    commentsCount: 10,
    viewsCount: 900,
    isPublished: true,
    category: 'Technology',
  ),
];

class BlogHomePage extends StatelessWidget {
  const BlogHomePage({super.key});

  @override
  Widget build(BuildContext context) {
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
            onPressed: () {},
            icon: Icon(Icons.search, color: theme.colorScheme.primary),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CategoriesSection(),
              SizedBox(height: 10),
              TrendingBlogsSection(blogs: dummyBlogs),
            ],
          ),
        ),
      ),
      backgroundColor: theme.colorScheme.surface,
    );
  }
}