// lib/pages/blog/published_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/blog_post_model.dart';
import '../../controllers/blog_controller.dart';
import '../../controllers/auth_controller.dart';
import 'blog_detail_page.dart';

class AllPublishedBlogsPage extends StatefulWidget {
  const AllPublishedBlogsPage({super.key});

  @override
  State<AllPublishedBlogsPage> createState() => _AllPublishedBlogsPageState();
}

class _AllPublishedBlogsPageState extends State<AllPublishedBlogsPage> {
  final BlogController _blogController = Get.find<BlogController>();
  final AuthController _authController = Get.find<AuthController>();
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPublishedPosts();
  }

  Future<void> _loadPublishedPosts() async {
    setState(() => _isLoading = true);
    
    final currentUser = _authController.userModel.value;
    if (currentUser != null) {
      // This will use the cache if available
      await _blogController.loadUserPublishedBlogs(currentUser.uid);
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Published Blogs'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Obx(() {
            final posts = _blogController.userPublishedPosts;
            
            if (posts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.article_outlined,
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
                      "Create and publish your first blog!",
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
              onRefresh: _loadPublishedPosts,
              child: GridView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: posts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return _buildPublishedCard(post);
                },
              ),
            );
          }),
    );
  }
  
  Widget _buildPublishedCard(BlogPostModel post) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _viewPost(post),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  // Image
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      color: Colors.grey[200],
                    ),
                    child: post.imageURL != null && post.imageURL!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: post.imageURL!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 32,
                                  color: Colors.grey,
                                ),
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
                  // Delete button - only visible for the owner
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(150),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => _deletePost(post),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding: const EdgeInsets.all(4),
                        tooltip: "Delete post",
                      ),
                    ),
                  ),
                ],
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
                      post.title.isNotEmpty ? post.title : 'Untitled Post',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Date and stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDate(post.publishedAt ?? post.updatedAt),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 10,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.visibility_outlined, size: 12, color: Colors.grey[500]),
                            const SizedBox(width: 2),
                            Text(
                              '${post.viewsCount}',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.favorite_outline, size: 12, color: Colors.grey[500]),
                            const SizedBox(width: 2),
                            Text(
                              '${post.likesCount}',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
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

  void _viewPost(BlogPostModel post) {
    Get.to(() => BlogDetailPage(blogId: post.id));
  }
  
  void _deletePost(BlogPostModel post) async {
    final success = await _blogController.deleteBlogPost(post.id);
    if (success) {
      // If deletion was successful, reload the list
      _loadPublishedPosts();
    }
  }
}