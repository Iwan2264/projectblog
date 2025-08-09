import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_html/flutter_html.dart';

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
      final blogPost = await _blogController.getBlogPost(widget.blogId);
      if (blogPost == null) {
        throw Exception('Blog post not found');
      }

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
    if (isLoading) {
      return _buildLoadingState();
    }

    if (hasError) {
      return _buildErrorState();
    }

    if (blog == null) {
      return _buildNotFoundState();
    }

    return _buildBlogDetailPage(context);
  }

  Widget _buildLoadingState() {
    return Scaffold(
      appBar: AppBar(),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState() {
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
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: Theme.of(context).textTheme.bodyMedium,
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

  Widget _buildNotFoundState() {
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
              style: Theme.of(context).textTheme.titleLarge,
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

  Widget _buildBlogDetailPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        actions: _buildAppBarActions(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroSection(Theme.of(context)),
            const Divider(height: 32),
            if (blog!.imageURL != null && blog!.imageURL!.isNotEmpty)
              _buildFeaturedImage(),
            _buildContentSection(context),
            if (blog!.tags.isNotEmpty) _buildTagsSection(Theme.of(context)),
            _buildStatsSection(Theme.of(context)),
            _buildReadTimeAndViews(Theme.of(context)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    return [
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
      if (_blogController.isCurrentUserAuthor(blog!))
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: _deleteBlog,
          tooltip: "Delete blog",
        ),
    ];
  }

  Widget _buildHeroSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          blog!.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
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
                color: theme.primaryColor.withAlpha(25),
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
      ],
    );
  }

  Widget _buildFeaturedImage() {
    return Container(
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
    );
  }

  Widget _buildContentSection(BuildContext context) {
    return Html(
      data: blog!.content,
      style: {
        "body": Style(
          fontSize: FontSize(16.0),
          lineHeight: LineHeight(1.6),
          fontFamily: 'Roboto',
          padding: HtmlPaddings.zero,
          margin: Margins.zero,
        ),
        "p": Style(
          margin: Margins.only(bottom: 16, top: 0),
          fontSize: FontSize(16.0),
        ),
        "h1": Style(
          fontSize: FontSize(24.0),
          fontWeight: FontWeight.bold,
          margin: Margins.only(bottom: 16, top: 24),
        ),
        "h2": Style(
          fontSize: FontSize(22.0),
          fontWeight: FontWeight.bold,
          margin: Margins.only(bottom: 14, top: 22),
        ),
        "h3": Style(
          fontSize: FontSize(20.0),
          fontWeight: FontWeight.bold,
          margin: Margins.only(bottom: 12, top: 20),
        ),
        "img": Style(
          width: Width(MediaQuery.of(context).size.width * 0.9),
          alignment: Alignment.center,
          margin: Margins.only(top: 16, bottom: 16),
        ),
        "ul": Style(
          margin: Margins.only(bottom: 16, top: 16, left: 16),
        ),
        "ol": Style(
          margin: Margins.only(bottom: 16, top: 16, left: 16),
        ),
      },
      onLinkTap: (url, _, __) {
        print('Tapped on URL: $url');
      },
    );
  }

  Widget _buildTagsSection(ThemeData theme) {
    return Container(
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
          backgroundColor: theme.primaryColor.withAlpha(25),
        )).toList(),
      ),
    );
  }

  Widget _buildStatsSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 16, bottom: 24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.favorite,
            label: '${blog!.likesCount} Likes',
            color: Colors.red,
          ),
          _buildStatItem(
            icon: Icons.comment_outlined,
            label: '${blog!.commentsCount} Comments',
            color: Colors.grey[700] ?? Colors.grey,
          ),
          _buildStatItem(
            icon: Icons.share_outlined,
            label: 'Share',
            color: Colors.grey[700] ?? Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({required IconData icon, required String label, required Color color}) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildReadTimeAndViews(ThemeData theme) {
    return Padding(
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
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _deleteBlog() async {
    if (blog == null) return;

    final success = await _blogController.deleteBlogPost(blog!.id);

    if (success) {
      Get.back();
      Get.snackbar(
        'Success',
        'Blog post deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withAlpha(200),
        colorText: Colors.white,
      );
    }
  }
}
