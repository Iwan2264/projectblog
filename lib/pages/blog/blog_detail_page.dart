import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/blog_post_model.dart';
import '../../models/user_model.dart';
import '../../controllers/blog_controller.dart';

class BlogDetailPage extends StatefulWidget {
  final String blogId;

  const BlogDetailPage({Key? key, required this.blogId}) : super(key: key);

  @override
  State<BlogDetailPage> createState() => _BlogDetailPageState();
}

class _BlogDetailPageState extends State<BlogDetailPage> {
  final BlogController _blogController = Get.find<BlogController>();
  
  BlogPostModel? blog;
  UserModel? author;
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadBlogDetails();
  }

  Future<void> _loadBlogDetails() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });
    
    try {
      // Load blog post
      final blogPost = await _blogController.getBlogPost(widget.blogId);
      if (blogPost == null) {
        throw Exception('Blog post not found');
      }
      
      // Load author details
      final blogAuthor = await _blogController.getUser(blogPost.authorId);

      setState(() {
        blog = blogPost;
        author = blogAuthor;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = 'Failed to load blog details: $e';
        isLoading = false;
      });
      print('❌ ERROR: $errorMessage');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (hasError) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadBlogDetails,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }
    
    if (blog == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.find_in_page_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Blog not found',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Get.back(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          blog!.title,
          style: theme.textTheme.titleLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () {
              // Implement bookmark functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Implement share functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              blog!.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Author and publish date
            Row(
              children: [
                if (author?.photoURL != null)
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: CachedNetworkImageProvider(author!.photoURL!),
                  )
                else
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.primaryColor,
                    child: Text(
                      (author?.name?.isNotEmpty == true) 
                          ? author!.name![0].toUpperCase() 
                          : blog!.authorUsername[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author?.name ?? blog!.authorUsername,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatDate(blog!.publishedAt ?? blog!.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    blog!.category,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            
            // Featured image
            if (blog!.imageURL != null && blog!.imageURL!.isNotEmpty)
              Container(
                height: 200,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: blog!.imageURL!,
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
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            
            // Content - Simple rendering of blog content
            // In a real app, you'd use a proper HTML renderer like flutter_html
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                _stripHtmlTags(blog!.content),
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
            ),
            
            // Tags
            if (blog!.tags.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 16, bottom: 24),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: blog!.tags.map((tag) => Chip(
                    label: Text(tag),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: theme.primaryColor,
                    ),
                    backgroundColor: theme.primaryColor.withOpacity(0.1),
                  )).toList(),
                ),
              ),
            
            // Stats and actions
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(top: 16, bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Likes
                  Column(
                    children: [
                      IconButton(
                        onPressed: () {
                          // Toggle like
                          _blogController.toggleLike(blog!);
                        },
                        icon: Icon(
                          _blogController.hasCurrentUserLiked(blog!) 
                              ? Icons.favorite 
                              : Icons.favorite_border,
                          color: _blogController.hasCurrentUserLiked(blog!) 
                              ? Colors.red 
                              : Colors.grey[700],
                        ),
                      ),
                      Text(
                        '${blog!.likesCount} Likes',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  
                  // Comments
                  Column(
                    children: [
                      IconButton(
                        onPressed: () {
                          // Show comments
                        },
                        icon: Icon(
                          Icons.comment_outlined,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '${blog!.commentsCount} Comments',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  
                  // Share
                  Column(
                    children: [
                      IconButton(
                        onPressed: () {
                          // Share blog
                        },
                        icon: Icon(
                          Icons.share_outlined,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        'Share',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Read time and views
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${blog!.readTime.toStringAsFixed(1)} min read',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.visibility_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${blog!.viewsCount} views',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
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
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
  
  // Helper method to strip HTML tags from content
  String _stripHtmlTags(String htmlString) {
    // This is a simple approach for display purposes
    // A proper HTML renderer would be better for a production app
    return htmlString.replaceAll(RegExp(r'<[^>]*>'), '')
                    .replaceAll('&nbsp;', ' ')
                    .replaceAll('&amp;', '&')
                    .replaceAll('&lt;', '<')
                    .replaceAll('&gt;', '>');
  }
}
