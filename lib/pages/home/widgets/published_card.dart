import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math';

import '../../../models/blog_post_model.dart';
import '../../../controllers/blog_controller.dart';
import '../../../controllers/auth_controller.dart';

class PublishedBlogsGrid extends StatefulWidget {
  const PublishedBlogsGrid({super.key});

  @override
  State<PublishedBlogsGrid> createState() => _PublishedBlogsGridState();
}

class _PublishedBlogsGridState extends State<PublishedBlogsGrid> {
  final BlogController _blogController = Get.find<BlogController>();
  final AuthController _authController = Get.find<AuthController>();
  
  List<BlogPostModel> _publishedBlogs = [];
  bool _isLoading = true;
  int _displayCount = 6;

  @override
  void initState() {
    super.initState();
    _loadPublishedBlogs();
  }

  Future<void> _loadPublishedBlogs() async {
    setState(() => _isLoading = true);
    
    final currentUser = _authController.userModel.value;
    if (currentUser != null) {
      final blogs = await _blogController.loadUserPublishedBlogs(currentUser.uid);
      setState(() {
        _publishedBlogs = blogs;
        _displayCount = min(_publishedBlogs.length, 6);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _loadMore() {
    setState(() {
      _displayCount = min(_publishedBlogs.length, _displayCount + 6);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_publishedBlogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.publish_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              "You haven't published any blogs yet.",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Write your first blog and share it with the world!",
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPublishedBlogs,
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _displayCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemBuilder: (context, index) {
              final blog = _publishedBlogs[index];
              return _buildBlogCard(blog);
            },
          ),
          
          if (_displayCount < _publishedBlogs.length)
            Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: OutlinedButton(
                onPressed: _loadMore,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  side: BorderSide(color: theme.colorScheme.primary),
                ),
                child: Text('Load More (${_publishedBlogs.length - _displayCount} remaining)'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBlogCard(BlogPostModel blog) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _viewBlog(blog),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  color: Colors.grey[200],
                ),
                child: blog.imageURL != null && blog.imageURL!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: blog.imageURL!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          color: Colors.grey[200],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 32,
                            color: Colors.grey,
                          ),
                        ),
                      ),
              ),
            ),
            
            // Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      blog.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Content preview
                    Expanded(
                      child: Text(
                        _getContentPreview(blog.content),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    // Stats and category
                    Row(
                      children: [
                        Icon(
                          Icons.favorite,
                          size: 12,
                          color: Colors.red[400],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${blog.likesCount}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.visibility,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${blog.viewsCount}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 10,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            blog.category,
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(blog.publishedAt ?? blog.createdAt),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getContentPreview(String content) {
    // Remove HTML tags and get preview
    String plainText = content.replaceAll(RegExp(r'<[^>]*>'), '');
    if (plainText.length > 60) {
      return '${plainText.substring(0, 60)}...';
    }
    return plainText;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _viewBlog(BlogPostModel blog) {
    // For now, just show a snackbar. You can implement blog detail navigation later
    Get.snackbar(
      'Blog Selected',
      'Viewing: ${blog.title}',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }
}