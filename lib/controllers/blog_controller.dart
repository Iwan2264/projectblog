import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../models/blog_post_model.dart';
import '../models/user_model.dart';
import '../services/blog_service.dart';
import '../services/user_service.dart';
import '../controllers/auth_controller.dart';
import '../utils/logger_util.dart';

class BlogController extends GetxController {
  static BlogController get instance => Get.find();
  
  final BlogService _blogService = Get.find<BlogService>();
  final UserService _userService = UserService();
  final AuthController _authController = Get.find<AuthController>();
  
  // Observable variables
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final recentBlogs = <BlogPostModel>[].obs;
  final userBlogs = <BlogPostModel>[].obs;
  final likedBlogs = <BlogPostModel>[].obs;
  final featuredBlogs = <BlogPostModel>[].obs;
  
  // Blog creation form fields
  final titleController = TextEditingController();
  final contentController = TextEditingController();
  final selectedTags = <String>[].obs;
  final selectedCategory = 'Technology'.obs;
  final blogImage = Rx<XFile?>(null);
  
  final availableCategories = [
    'Technology',
    'Health & Wellness',
    'Finance & Investing',
    'Travel',
    'Food & Recipes',
    'Lifestyle & Fashion',
    'Business & Marketing',
    'Education',
    'Arts & Culture',
    'Science',
    'Personal Growth',
    'Sports & Gaming'
  ].obs;

  // Flag to track if initial data has been loaded
  final hasLoadedInitialData = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    // Load data immediately
    loadInitialData();
    
    // Set up automatic refresh every 60 seconds for when app is running
    ever(_authController.firebaseUser, (_) {
      if (_authController.firebaseUser.value != null) {
        loadUserData(_authController.firebaseUser.value!.uid);
      }
    });
  }
  
  // Load all initial data
  Future<void> loadInitialData() async {
    if (hasLoadedInitialData.value) return;
    
    try {
      isLoading.value = true;
      
      // Get current user
      final user = _authController.firebaseUser.value;
      
      // Load all data in parallel
      await Future.wait([
        loadRecentBlogs(),
        loadFeaturedBlogs(),
        if (user != null) loadUserData(user.uid),
      ]);
      
      hasLoadedInitialData.value = true;
    } catch (e) {
      AppLogger.error('Error loading initial data', e);
    } finally {
      isLoading.value = false;
    }
  }
  
  // Load all user-specific data
  Future<void> loadUserData(String userId) async {
    try {
      // Load user's blogs in parallel
      await Future.wait([
        loadUserBlogs(userId),
        // Pre-fetch drafts and published posts and store them
        _preloadUserDrafts(userId),
        _preloadUserPublishedPosts(userId),
      ]);
    } catch (e) {
      AppLogger.error('Error loading user data', e);
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    contentController.dispose();
    super.onClose();
  }

  // ==================== BLOG LOADING ====================

  /// Load recent blogs for feed
  Future<void> loadRecentBlogs() async {
    try {
      isLoading.value = true;
      List<BlogPostModel> blogs = await _blogService.getPublishedPosts(limit: 20);
      recentBlogs.assignAll(blogs);
    } catch (e) {
      AppLogger.error('Error loading recent blogs', e);
      errorMessage.value = 'Failed to load blogs';
    } finally {
      isLoading.value = false;
    }
  }

  /// Load featured blogs
  Future<void> loadFeaturedBlogs() async {
    try {
      List<BlogPostModel> blogs = await _blogService.getFeaturedPosts(limit: 5);
      featuredBlogs.assignAll(blogs);
    } catch (e) {
      AppLogger.error('Error loading featured blogs', e);
    }
  }

  /// Load blogs by specific user
  Future<void> loadUserBlogs(String userId) async {
    try {
      isLoading.value = true;
      List<BlogPostModel> blogs = await _blogService.getUserPublishedPosts(userId);
      userBlogs.assignAll(blogs);
    } catch (e) {
      AppLogger.error('Error loading user blogs', e);
      errorMessage.value = 'Failed to load user blogs';
    } finally {
      isLoading.value = false;
    }
  }

  // Cached user drafts
  final RxList<BlogPostModel> userDrafts = <BlogPostModel>[].obs;
  
  // Helper method to sort blogs by date
  List<BlogPostModel> _sortBlogsByDate(List<BlogPostModel> blogs, {bool usePublishedDate = false}) {
    blogs.sort((a, b) =>
        (usePublishedDate ? b.publishedAt ?? b.updatedAt : b.updatedAt).compareTo(
            usePublishedDate ? a.publishedAt ?? a.updatedAt : a.updatedAt));
    return blogs;
  }

  // Preload and cache user drafts
  Future<void> _preloadUserDrafts(String userId) async {
    try {
      final drafts = await _blogService.getUserDrafts(userId);
      userDrafts.value = _sortBlogsByDate(drafts);
    } catch (e) {
      AppLogger.error('Error preloading user drafts', e);
    }
  }

  /// Load user's drafts - uses cache if available
  Future<List<BlogPostModel>> loadUserDrafts(String userId) async {
    try {
      // If cache is empty, load from service
      if (userDrafts.isEmpty) {
        print('📝 DEBUG: Cache miss for drafts, loading from service');
        final drafts = await _blogService.getUserDrafts(userId);
        
        // Sort drafts by date (newest first)
        drafts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        
        // Store in cache
        userDrafts.value = drafts;
        return drafts;
      } else {
        print('📝 DEBUG: Using cached drafts (${userDrafts.length})');
        return userDrafts;
      }
    } catch (e) {
      AppLogger.error('Error loading user drafts', e);
      return [];
    }
  }
  
  /// Refresh drafts cache
  Future<void> refreshDrafts(String userId) async {
    try {
      final drafts = await _blogService.getUserDrafts(userId);
      userDrafts.value = _sortBlogsByDate(drafts);
    } catch (e) {
      AppLogger.error('Error refreshing drafts', e);
    }
  }

  // Cached user published posts
  final RxList<BlogPostModel> userPublishedPosts = <BlogPostModel>[].obs;
  
  // Preload and cache user published posts
  Future<void> _preloadUserPublishedPosts(String userId) async {
    try {
      final posts = await _blogService.getUserPublishedPosts(userId);
      userPublishedPosts.value = _sortBlogsByDate(posts, usePublishedDate: true);
    } catch (e) {
      AppLogger.error('Error preloading user published posts', e);
    }
  }

  /// Load user's published blogs - uses cache if available
  Future<List<BlogPostModel>> loadUserPublishedBlogs(String userId) async {
    try {
      // If cache is empty, load from service
      if (userPublishedPosts.isEmpty) {
        print('📝 DEBUG: Cache miss for published posts, loading from service');
        final posts = await _blogService.getUserPublishedPosts(userId);
        
        // Sort posts by date (newest first)
        posts.sort((a, b) => (b.publishedAt ?? b.updatedAt).compareTo(a.publishedAt ?? a.updatedAt));
        
        // Store in cache
        userPublishedPosts.value = posts;
        return posts;
      } else {
        print('📝 DEBUG: Using cached published posts (${userPublishedPosts.length})');
        return userPublishedPosts;
      }
    } catch (e) {
      AppLogger.error('Error loading user published blogs', e);
      return [];
    }
  }
  
  /// Refresh published posts cache
  Future<void> refreshPublishedPosts(String userId) async {
    try {
      final posts = await _blogService.getUserPublishedPosts(userId);
      userPublishedPosts.value = _sortBlogsByDate(posts, usePublishedDate: true);
    } catch (e) {
      AppLogger.error('Error refreshing published posts', e);
    }
  }

  /// Search blogs
  Future<List<BlogPostModel>> searchBlogs(String searchTerm) async {
    try {
      return await _blogService.searchPosts(searchTerm);
    } catch (e) {
      AppLogger.error('Error searching blogs', e);
      return [];
    }
  }

  /// Get blogs by category
  Future<List<BlogPostModel>> getBlogsByCategory(String category) async {
    try {
      return await _blogService.getPostsByCategory(category);
    } catch (e) {
      AppLogger.error('Error getting blogs by category', e);
      return [];
    }
  }

  /// Get popular blogs
  Future<List<BlogPostModel>> getPopularBlogs() async {
    try {
      return await _blogService.getPopularPosts();
    } catch (e) {
      AppLogger.error('Error getting popular blogs', e);
      return [];
    }
  }

  // ==================== BLOG INTERACTIONS ====================

  /// Like or unlike a blog
  Future<void> toggleLike(BlogPostModel blog) async {
    try {
      UserModel? currentUser = _authController.userModel.value;
      if (currentUser == null) {
        Get.snackbar(
          'Error',
          'Please log in to like posts',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
        return;
      }

      bool newLikeStatus = await _blogService.togglePostLike(blog.id, currentUser.uid);

      // Update local blog in lists
      _updateBlogInLists(blog.id, newLikeStatus, currentUser.uid);

      Get.snackbar(
        'Success',
        newLikeStatus ? 'Post liked!' : 'Post unliked',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        duration: Duration(seconds: 1),
      );

    } catch (e) {
      AppLogger.error('Error toggling like', e);
      Get.snackbar(
        'Error',
        'Failed to like/unlike post',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  /// Increment blog views
  Future<void> viewBlog(String blogId) async {
    try {
      // Don't wait for the result since this is a non-critical operation
      // This will avoid blocking the UI while analytics are being processed
      _blogService.incrementViewCount(blogId).catchError((error) {
        // Log but don't show to user as it's non-critical
        print('📝 DEBUG: Non-critical view count error: $error');
      });
    } catch (e) {
      // This catch block will rarely be hit since we're using catchError above
      AppLogger.warning('Error incrementing blog views (non-critical)', e);
    }
  }

  /// Get single blog post
  Future<BlogPostModel?> getBlogPost(String blogId) async {
    try {
      BlogPostModel? blog = await _blogService.getPostById(blogId);
      if (blog != null) {
        // Increment view count when blog is accessed
        viewBlog(blogId);
      }
      return blog;
    } catch (e) {
      AppLogger.error('Error getting blog post', e);
      return null;
    }
  }

  // ==================== HELPER METHODS ====================

  /// Update blog in all local lists after like/unlike
  void _updateBlogInLists(String blogId, bool isLiked, String userId) {
    // Update in recent blogs
    int recentIndex = recentBlogs.indexWhere((blog) => blog.id == blogId);
    if (recentIndex != -1) {
      BlogPostModel blog = recentBlogs[recentIndex];
      List<String> likedBy = List<String>.from(blog.likedBy);
      int likesCount = blog.likesCount;
      
      if (isLiked && !likedBy.contains(userId)) {
        likedBy.add(userId);
        likesCount++;
      } else if (!isLiked && likedBy.contains(userId)) {
        likedBy.remove(userId);
        likesCount = (likesCount - 1).clamp(0, double.infinity).toInt();
      }
      
      recentBlogs[recentIndex] = blog.copyWith(
        likedBy: likedBy,
        likesCount: likesCount,
      );
    }

    // Update in user blogs
    int userIndex = userBlogs.indexWhere((blog) => blog.id == blogId);
    if (userIndex != -1) {
      BlogPostModel blog = userBlogs[userIndex];
      List<String> likedBy = List<String>.from(blog.likedBy);
      int likesCount = blog.likesCount;
      
      if (isLiked && !likedBy.contains(userId)) {
        likedBy.add(userId);
        likesCount++;
      } else if (!isLiked && likedBy.contains(userId)) {
        likedBy.remove(userId);
        likesCount = (likesCount - 1).clamp(0, double.infinity).toInt();
      }
      
      userBlogs[userIndex] = blog.copyWith(
        likedBy: likedBy,
        likesCount: likesCount,
      );
    }
  }

  /// Get formatted blog content preview
  String getBlogPreview(String content, {int maxLength = 150}) {
    // Remove HTML tags for preview
    String plainText = content.replaceAll(RegExp(r'<[^>]*>'), '');
    if (plainText.length <= maxLength) return plainText;
    return '${plainText.substring(0, maxLength)}...';
  }

  /// Check if current user is the author of a blog
  bool isCurrentUserAuthor(BlogPostModel blog) {
    UserModel? currentUser = _authController.userModel.value;
    return currentUser != null && currentUser.uid == blog.authorId;
  }

  /// Check if current user has liked a blog
  bool hasCurrentUserLiked(BlogPostModel blog) {
    UserModel? currentUser = _authController.userModel.value;
    return currentUser != null && blog.likedBy.contains(currentUser.uid);
  }
  
  /// Delete a blog post
  Future<bool> deleteBlogPost(String blogId) async {
    try {
      // Ensure authentication is valid
      bool isAuthenticated = await _authController.ensureAuthenticated();
      if (!isAuthenticated) {
        Get.snackbar(
          'Authentication Error',
          'You need to be logged in to delete posts',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
        return false;
      }
      
      final currentUser = _authController.userModel.value;
      if (currentUser == null) {
        Get.snackbar(
          'Error',
          'Unable to verify your identity',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
        return false;
      }
      
      // First get the blog post to verify ownership
      final blog = await getBlogPost(blogId);
      if (blog == null) {
        Get.snackbar(
          'Error',
          'Blog post not found',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
        return false;
      }
      
      // Verify that the current user is the author
      if (blog.authorId != currentUser.uid) {
        Get.snackbar(
          'Permission Denied',
          'You can only delete your own posts',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
        return false;
      }
      
      // Show confirmation dialog
      final bool confirm = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Delete Post'),
          content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('DELETE'),
            ),
          ],
        ),
      ) ?? false;
      
      if (!confirm) return false;
      
      // Delete the blog post
      final success = await _blogService.deleteBlogPost(blogId, currentUser.uid);
      
      if (success) {
        // Refresh the caches
        refreshDrafts(currentUser.uid);
        refreshPublishedPosts(currentUser.uid);
        
        Get.snackbar(
          'Success',
          'Post deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
        );
        return true;
      } else {
        Get.snackbar(
          'Error',
          'Failed to delete post',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      AppLogger.error('Error deleting blog post', e);
      Get.snackbar(
        'Error',
        'An error occurred while deleting the post',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return false;
    }
  }

  /// Get user by ID
  Future<UserModel?> getUser(String userId) async {
    try {
      return await _userService.getUser(userId);
    } catch (e) {
      AppLogger.error('Error getting user', e);
      return null;
    }
  }

  /// Get user by username
  Future<UserModel?> getUserByUsername(String username) async {
    try {
      return await _userService.getUserByUsername(username);
    } catch (e) {
      AppLogger.error('Error getting user by username', e);
      return null;
    }
  }

  /// Search users
  Future<List<UserModel>> searchUsers(String searchTerm) async {
    try {
      return await _userService.searchUsers(searchTerm);
    } catch (e) {
      AppLogger.error('Error searching users', e);
      return [];
    }
  }

  /// Get complete user profile with their blogs
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      UserModel? user = await _userService.getUser(userId);
      if (user == null) {
        return {'error': 'User not found'};
      }
      
      List<BlogPostModel> userPosts = await _blogService.getUserPublishedPosts(userId);
      
      return {
        'user': user,
        'posts': userPosts,
        'totalPosts': userPosts.length,
        'totalLikes': userPosts.fold<int>(0, (sum, post) => sum + post.likesCount),
        'totalViews': userPosts.fold<int>(0, (sum, post) => sum + post.viewsCount),
      };
    } catch (e) {
      AppLogger.error('Error fetching user profile', e);
      return {'error': 'Failed to load profile data'};
    }
  }

  /// Refresh all data
  Future<void> refreshData() async {
    await Future.wait([
      loadRecentBlogs(),
      loadFeaturedBlogs(),
    ]);
  }

  /// Get time ago string for blog post
  String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    }
  }
}
