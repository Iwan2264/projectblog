import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math';

import '../../../models/blog_post_model.dart';
import '../../../controllers/blog_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../blog/blog_detail_page.dart';

class PublishedBlogsGrid extends StatefulWidget {
  const PublishedBlogsGrid({super.key});

  @override
  State<PublishedBlogsGrid> createState() => _PublishedBlogsGridState();
}

class _PublishedBlogsGridState extends State<PublishedBlogsGrid> {
  final BlogController _blogController = Get.find<BlogController>();
  final AuthController _authController = Get.find<AuthController>();

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
      await _blogController.loadUserPublishedBlogs(currentUser.uid);
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_isLoading) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
      final currentUser = _authController.userModel.value;
      final publishedBlogs = currentUser != null
          ? _blogController.userPublishedPosts
              .where((blog) => blog.authorId == currentUser.uid)
              .toList()
          : [];
      if (publishedBlogs.isEmpty) {
        return _buildEmptyState();
      }
      return RefreshIndicator(
        onRefresh: _loadPublishedBlogs,
        child: Column(
          children: [
            _buildGridView(publishedBlogs.cast<BlogPostModel>()),
            if (_displayCount < publishedBlogs.length) _buildLoadMoreButton(publishedBlogs.length),
          ],
        ),
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.publish_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            "You haven't published any blogs yet.",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Write your first blog and share it with the world!",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(List<BlogPostModel> blogs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: min(_displayCount, blogs.length),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 1,
          mainAxisSpacing: 1,
          childAspectRatio: 1.0,
        ),
        itemBuilder: (context, index) {
          final blog = blogs[index];
          return _buildBlogCard(blog);
        },
      ),
    );
  }

  Widget _buildLoadMoreButton(int totalBlogs) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            _displayCount = min(_displayCount + 6, totalBlogs);
          });
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        ),
        child: Text('Load More (${totalBlogs - _displayCount} remaining)'),
      ),
    );
  }

  Widget _buildBlogCard(BlogPostModel blog) {
    return GestureDetector(
      onTap: () => _viewBlog(blog),
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.all(3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
                child: blog.imageURL != null && blog.imageURL!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: blog.imageURL!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 32,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    blog.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
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
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            Icons.visibility,
                            size: 12,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${blog.viewsCount}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _formatDate(blog.publishedAt ?? blog.createdAt),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(50),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      blog.category,
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
    Get.to(() => BlogDetailPage(blogId: blog.id));
  }
}