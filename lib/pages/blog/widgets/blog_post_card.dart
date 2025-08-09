import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../models/blog_post_model.dart';
import '../../../controllers/blog_controller.dart';
import '../blog_detail_page.dart'; // Create this if it doesn't exist

class BlogPostCard extends StatelessWidget {
  final BlogPostModel blog;
  final bool showAuthor;

  const BlogPostCard({
    super.key, 
    required this.blog,
    this.showAuthor = true,
  });

  @override
  Widget build(BuildContext context) {
    final BlogController blogController = Get.find<BlogController>();
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1,
      child: InkWell(
        onTap: () {
          // Navigate to blog detail page - implement this route
          Get.to(() => BlogDetailPage(blogId: blog.id));
          
          // Increment view count
          blogController.viewBlog(blog.id);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured image
            if (blog.imageURL != null && blog.imageURL!.isNotEmpty)
              SizedBox(
                height: 180,
                width: double.infinity,
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
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    blog.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Preview text
                  Text(
                    _getContentPreview(blog.content),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  
                  // Category and date
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          blog.category,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: theme.primaryColor,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(blog.publishedAt ?? blog.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Stats and author info
                  Row(
                    children: [
                      if (showAuthor && blog.authorName != null)
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundImage: blog.authorPhotoURL != null
                                  ? CachedNetworkImageProvider(blog.authorPhotoURL!) as ImageProvider
                                  : const AssetImage('assets/images/default_avatar.png'),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              blog.authorName!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      const Spacer(),
                      // Blog stats
                      Row(
                        children: [
                          Icon(
                            Icons.remove_red_eye_outlined,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${blog.viewsCount}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.favorite_border,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${blog.likesCount}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.comment_outlined,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${blog.commentsCount}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getContentPreview(String content) {
    // Remove HTML tags for preview including style blocks
    String plainText = content
      .replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true), '') // Remove style blocks
      .replaceAll(RegExp(r'<div\s+class="editor-styles".*?</div>', dotAll: true), '') // Remove editor styles div
      .replaceAll(RegExp(r'<[^>]*>'), '') // Remove remaining HTML tags
      .replaceAll('&nbsp;', ' ') // Convert non-breaking spaces to regular spaces
      .replaceAll('&amp;', '&') // Convert HTML entities
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');
      
    // Trim whitespace and check length
    plainText = plainText.trim();
    if (plainText.length > 150) {
      return '${plainText.substring(0, 150)}...';
    }
    return plainText;
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
