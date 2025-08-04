import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../models/blog_model.dart';
import '../models/user_model.dart';
import '../services/analytics_service.dart';
import '../services/blog_service.dart';
import '../services/like_service.dart';
import '../services/user_service.dart';
import '../controllers/auth_controller.dart';
import '../utils/logger_util.dart';

class BlogController extends GetxController {
  static BlogController instance = Get.find();
  
  final BlogService _blogService = BlogService();
  final LikeService _likeService = LikeService();
  final UserService _userService = UserService();
  final AnalyticsService _analyticsService = AnalyticsService();
  final AuthController _authController = Get.find<AuthController>();
  
  // Observable variables
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final recentBlogs = <BlogModel>[].obs;
  final userBlogs = <BlogModel>[].obs;
  final likedBlogs = <BlogModel>[].obs;
  
  // Blog creation form fields
  final titleController = TextEditingController();
  final contentController = TextEditingController();
  final selectedTags = <String>[].obs;
  final selectedCategory = 'General'.obs;
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
    'Science'
  ].obs;

  @override
  void onInit() {
    super.onInit();
    loadRecentBlogs();
  }

  @override
  void onClose() {
    titleController.dispose();
    contentController.dispose();
    super.onClose();
  }

  // ==================== BLOG CREATION ====================

  /// Create a new blog post
  Future<void> createBlog() async {
    try {
      if (!_validateBlogForm()) return;

      isLoading.value = true;
      errorMessage.value = '';

      UserModel? currentUser = _authController.userModel.value;
      if (currentUser == null) {
        errorMessage.value = 'User not authenticated';
        return;
      }

      String? imageURL;
      
      // Create blog model
      BlogModel blog = BlogModel(
        id: '', // Will be set by Firestore
        authorId: currentUser.uid,
        authorUsername: currentUser.username,
        authorPhotoURL: currentUser.photoURL,
        title: titleController.text.trim(),
        content: contentController.text.trim(),
        imageURL: imageURL,
        tags: selectedTags.toList(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        category: selectedCategory.value,
      );

      // Create blog in database
      String blogId = await _blogService.createBlog(blog);

      // Upload image if selected
      if (blogImage.value != null) {
        imageURL = await _blogService.uploadBlogImage(blogId, blogImage.value!);
        await _blogService.updateBlog(blogId, {'imageURL': imageURL});
      }

      // Clear form
      _clearBlogForm();

      // Update user profile stats
      try {
        await _userService.updateUser(currentUser.uid, {
          'lastPostAt': DateTime.now(),
        });
      } catch (e) {
        // Non-critical update, just log the error
        AppLogger.warning('Error updating user last post time (non-critical)', e);
      }

      Get.snackbar(
        'Success',
        'Blog post created successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
      );

      // Refresh blogs
      loadUserBlogs(currentUser.uid);
      loadRecentBlogs();

      // Navigate back
      Get.back();

    } catch (e) {
      errorMessage.value = 'Failed to create blog post';
      AppLogger.error('Error creating blog', e);
      
      Get.snackbar(
        'Error',
        'Failed to create blog post: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Pick image for blog
  Future<void> pickBlogImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        blogImage.value = image;
      }
    } catch (e) {
      AppLogger.error('Error picking blog image', e);
      Get.snackbar(
        'Error',
        'Failed to pick image',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  /// Add tag to blog
  void addTag(String tag) {
    if (tag.isNotEmpty && !selectedTags.contains(tag)) {
      selectedTags.add(tag);
    }
  }

  /// Remove tag from blog
  void removeTag(String tag) {
    selectedTags.remove(tag);
  }

  /// Validate blog creation form
  bool _validateBlogForm() {
    if (titleController.text.trim().isEmpty) {
      errorMessage.value = 'Title is required';
      return false;
    }
    
    if (contentController.text.trim().isEmpty) {
      errorMessage.value = 'Content is required';
      return false;
    }

    if (titleController.text.trim().length < 5) {
      errorMessage.value = 'Title must be at least 5 characters';
      return false;
    }

    if (contentController.text.trim().length < 50) {
      errorMessage.value = 'Content must be at least 50 characters';
      return false;
    }

    return true;
  }

  /// Clear blog creation form
  void _clearBlogForm() {
    titleController.clear();
    contentController.clear();
    selectedTags.clear();
    selectedCategory.value = 'General';
    blogImage.value = null;
  }

  // ==================== BLOG LOADING ====================

  /// Load recent blogs for feed
  Future<void> loadRecentBlogs() async {
    try {
      isLoading.value = true;
      List<BlogModel> blogs = await _blogService.getRecentBlogs(limit: 20);
      recentBlogs.assignAll(blogs);
    } catch (e) {
      AppLogger.error('Error loading recent blogs', e);
      errorMessage.value = 'Failed to load blogs';
    } finally {
      isLoading.value = false;
    }
  }

  /// Load blogs by specific user
  Future<void> loadUserBlogs(String userId) async {
    try {
      isLoading.value = true;
      List<BlogModel> blogs = await _blogService.getBlogsByAuthor(userId, limit: 20);
      userBlogs.assignAll(blogs);
    } catch (e) {
      AppLogger.error('Error loading user blogs', e);
      errorMessage.value = 'Failed to load user blogs';
    } finally {
      isLoading.value = false;
    }
  }

  /// Load blogs liked by user
  Future<void> loadLikedBlogs(String userId) async {
    try {
      isLoading.value = true;
      List<BlogModel> blogs = await _likeService.getLikedBlogsByUser(userId, limit: 20);
      likedBlogs.assignAll(blogs);
    } catch (e) {
      AppLogger.error('Error loading liked blogs', e);
      errorMessage.value = 'Failed to load liked blogs';
    } finally {
      isLoading.value = false;
    }
  }

  /// Search blogs
  Future<List<BlogModel>> searchBlogs(String searchTerm) async {
    try {
      return await _blogService.searchBlogs(searchTerm, limit: 20);
    } catch (e) {
      AppLogger.error('Error searching blogs', e);
      return [];
    }
  }

  // ==================== BLOG INTERACTIONS ====================

  /// Like or unlike a blog
  Future<void> toggleLike(BlogModel blog) async {
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

      await _likeService.likeBlog(
        currentUser.uid,
        blog.id,
        blog.authorId,
      );

      // Update local blog in lists
      _updateBlogInLists(blog.id);

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

  /// Check if current user has liked a blog
  Future<bool> hasUserLikedBlog(String blogId) async {
    try {
      UserModel? currentUser = _authController.userModel.value;
      if (currentUser == null) return false;

      return await _likeService.hasUserLikedBlog(currentUser.uid, blogId);
    } catch (e) {
      AppLogger.error('Error checking if user liked blog', e);
      return false;
    }
  }

  /// Increment blog views
  Future<void> viewBlog(String blogId) async {
    try {
      await _blogService.incrementBlogViews(blogId);
    } catch (e) {
      AppLogger.warning('Error incrementing blog views (non-critical)', e);
    }
  }

  /// Delete a blog (only by author)
  Future<void> deleteBlog(BlogModel blog) async {
    try {
      UserModel? currentUser = _authController.userModel.value;
      if (currentUser == null || currentUser.uid != blog.authorId) {
        Get.snackbar(
          'Error',
          'You can only delete your own posts',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
        return;
      }

      // Show confirmation dialog
      bool confirm = await Get.dialog<bool>(
        AlertDialog(
          title: Text('Delete Post'),
          content: Text('Are you sure you want to delete this post? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('Delete'),
            ),
          ],
        ),
      ) ?? false;

      if (!confirm) return;

      isLoading.value = true;
      await _blogService.deleteBlog(blog.id, blog.authorId);

      // Remove from local lists
      recentBlogs.removeWhere((b) => b.id == blog.id);
      userBlogs.removeWhere((b) => b.id == blog.id);

      Get.snackbar(
        'Success',
        'Post deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
      );

    } catch (e) {
      AppLogger.error('Error deleting blog', e);
      Get.snackbar(
        'Error',
        'Failed to delete post',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== HELPER METHODS ====================

  /// Update blog in all local lists after like/unlike
  void _updateBlogInLists(String blogId) {
    // This would typically refetch the specific blog or update counts locally
    // For simplicity, we'll just refresh the lists
    loadRecentBlogs();
  }

  /// Get formatted blog content preview
  String getBlogPreview(String content, {int maxLength = 150}) {
    if (content.length <= maxLength) return content;
    return '${content.substring(0, maxLength)}...';
  }

  /// Check if current user is the author of a blog
  bool isCurrentUserAuthor(BlogModel blog) {
    UserModel? currentUser = _authController.userModel.value;
    return currentUser != null && currentUser.uid == blog.authorId;
  }

  /// Get user analytics data
  Future<Map<String, int>> getUserAnalytics(String userId) async {
    try {
      return await _analyticsService.getUserStats(userId);
    } catch (e) {
      AppLogger.error('Error fetching user analytics', e);
      return {};
    }
  }
  
  /// Get complete user profile with their blogs
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      // Get user data and blogs in parallel
      final results = await Future.wait([
        _userService.getUser(userId),
        _blogService.getBlogsByAuthor(userId, limit: 5)
      ]);
      
      UserModel? user = results[0] as UserModel?;
      List<BlogModel> recentUserBlogs = results[1] as List<BlogModel>;
      
      if (user == null) {
        return {'error': 'User not found'};
      }
      
      // Get analytics
      Map<String, int> stats = await _analyticsService.getUserStats(userId);
      
      return {
        'user': user,
        'recentBlogs': recentUserBlogs,
        'stats': stats
      };
    } catch (e) {
      AppLogger.error('Error fetching user profile', e);
      return {'error': 'Failed to load profile data'};
    }
  }
  
  /// Fetch author details for a blog
  Future<UserModel?> getBlogAuthor(String authorId) async {
    try {
      return await _userService.getUser(authorId);
    } catch (e) {
      AppLogger.error('Error fetching blog author', e);
      return null;
    }
  }
  
  /// Fetch authors for a list of blogs
  Future<Map<String, UserModel>> fetchBlogAuthors(List<BlogModel> blogs) async {
    try {
      // Extract unique author IDs
      Set<String> authorIds = blogs.map((blog) => blog.authorId).toSet();
      
      // Fetch all authors in parallel
      Map<String, UserModel> authors = {};
      await Future.wait(
        authorIds.map((authorId) async {
          UserModel? author = await _userService.getUser(authorId);
          if (author != null) {
            authors[authorId] = author;
          }
        })
      );
      
      return authors;
    } catch (e) {
      AppLogger.error('Error fetching multiple blog authors', e);
      return {};
    }
  }
}
