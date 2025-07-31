import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_model.dart';
import '../models/blog_model.dart';
import '../utils/logger_util.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ==================== USER OPERATIONS ====================

  /// Create or update user document
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toMap());
      AppLogger.info('User created successfully: ${user.uid}');
    } catch (e) {
      AppLogger.error('Error creating user', e);
      throw Exception('Failed to create user: $e');
    }
  }

  /// Get user by ID
  Future<UserModel?> getUser(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      AppLogger.error('Error getting user', e);
      throw Exception('Failed to get user: $e');
    }
  }

  /// Update user profile
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
      AppLogger.info('User updated successfully: $uid');
    } catch (e) {
      AppLogger.error('Error updating user', e);
      throw Exception('Failed to update user: $e');
    }
  }

  /// Upload profile picture
  Future<String> uploadProfilePicture(String uid, XFile imageFile) async {
    try {
      File file = File(imageFile.path);
      
      // Create reference to storage location
      Reference ref = _storage.ref().child('profile_pictures').child('$uid.jpg');
      
      // Upload file
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      
      // Get download URL
      String downloadURL = await snapshot.ref.getDownloadURL();
      
      // Update user document with new photo URL
      await updateUser(uid, {'photoURL': downloadURL});
      
      AppLogger.info('Profile picture uploaded successfully: $uid');
      return downloadURL;
    } catch (e) {
      AppLogger.error('Error uploading profile picture', e);
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  // ==================== BLOG OPERATIONS ====================

  /// Create a new blog post
  Future<String> createBlog(BlogModel blog) async {
    try {
      DocumentReference doc = await _firestore.collection('blogs').add(blog.toMap());
      
      // Update user's post count
      await _firestore.collection('users').doc(blog.authorId).update({
        'postsCount': FieldValue.increment(1),
      });
      
      AppLogger.info('Blog created successfully: ${doc.id}');
      return doc.id;
    } catch (e) {
      AppLogger.error('Error creating blog', e);
      throw Exception('Failed to create blog: $e');
    }
  }

  /// Get blog by ID
  Future<BlogModel?> getBlog(String blogId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('blogs').doc(blogId).get();
      if (doc.exists) {
        return BlogModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      AppLogger.error('Error getting blog', e);
      throw Exception('Failed to get blog: $e');
    }
  }

  /// Get blogs by author
  Future<List<BlogModel>> getBlogsByAuthor(String authorId, {int limit = 10}) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('blogs')
          .where('authorId', isEqualTo: authorId)
          .where('isPublished', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) => 
          BlogModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)
      ).toList();
    } catch (e) {
      AppLogger.error('Error getting blogs by author', e);
      throw Exception('Failed to get blogs by author: $e');
    }
  }

  /// Get recent blogs (for feed)
  Future<List<BlogModel>> getRecentBlogs({int limit = 20}) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('blogs')
          .where('isPublished', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) => 
          BlogModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)
      ).toList();
    } catch (e) {
      AppLogger.error('Error getting recent blogs', e);
      throw Exception('Failed to get recent blogs: $e');
    }
  }

  /// Search blogs by title or content
  Future<List<BlogModel>> searchBlogs(String searchTerm, {int limit = 20}) async {
    try {
      // Note: This is a basic search. For advanced search, consider using Algolia or similar
      QuerySnapshot titleQuery = await _firestore
          .collection('blogs')
          .where('isPublished', isEqualTo: true)
          .where('title', isGreaterThanOrEqualTo: searchTerm)
          .where('title', isLessThanOrEqualTo: searchTerm + '\uf8ff')
          .limit(limit)
          .get();

      return titleQuery.docs.map((doc) => 
          BlogModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)
      ).toList();
    } catch (e) {
      AppLogger.error('Error searching blogs', e);
      throw Exception('Failed to search blogs: $e');
    }
  }

  /// Update blog
  Future<void> updateBlog(String blogId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = DateTime.now();
      await _firestore.collection('blogs').doc(blogId).update(data);
      AppLogger.info('Blog updated successfully: $blogId');
    } catch (e) {
      AppLogger.error('Error updating blog', e);
      throw Exception('Failed to update blog: $e');
    }
  }

  /// Delete blog
  Future<void> deleteBlog(String blogId, String authorId) async {
    try {
      // Delete the blog document
      await _firestore.collection('blogs').doc(blogId).delete();
      
      // Delete all likes for this blog
      QuerySnapshot likes = await _firestore
          .collection('likes')
          .where('blogId', isEqualTo: blogId)
          .get();
      
      WriteBatch batch = _firestore.batch();
      for (var doc in likes.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      // Update user's post count
      await _firestore.collection('users').doc(authorId).update({
        'postsCount': FieldValue.increment(-1),
      });
      
      AppLogger.info('Blog deleted successfully: $blogId');
    } catch (e) {
      AppLogger.error('Error deleting blog', e);
      throw Exception('Failed to delete blog: $e');
    }
  }

  /// Upload blog image
  Future<String> uploadBlogImage(String blogId, XFile imageFile) async {
    try {
      File file = File(imageFile.path);
      
      // Create reference to storage location
      Reference ref = _storage.ref().child('blog_images').child('$blogId.jpg');
      
      // Upload file
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      
      // Get download URL
      String downloadURL = await snapshot.ref.getDownloadURL();
      
      AppLogger.info('Blog image uploaded successfully: $blogId');
      return downloadURL;
    } catch (e) {
      AppLogger.error('Error uploading blog image', e);
      throw Exception('Failed to upload blog image: $e');
    }
  }

  // ==================== LIKE OPERATIONS ====================

  /// Like a blog post
  Future<void> likeBlog(String userId, String blogId, String blogAuthorId) async {
    try {
      // Check if already liked
      QuerySnapshot existingLike = await _firestore
          .collection('likes')
          .where('userId', isEqualTo: userId)
          .where('blogId', isEqualTo: blogId)
          .get();

      if (existingLike.docs.isNotEmpty) {
        // Unlike the blog
        await _firestore.collection('likes').doc(existingLike.docs.first.id).delete();
        
        // Decrease like count
        await _firestore.collection('blogs').doc(blogId).update({
          'likesCount': FieldValue.increment(-1),
        });
        
        AppLogger.info('Blog unliked: $blogId by $userId');
      } else {
        
        await _firestore.collection('likes').add(like.toMap());
        
        // Increase like count
        await _firestore.collection('blogs').doc(blogId).update({
          'likesCount': FieldValue.increment(1),
        });
        
        AppLogger.info('Blog liked: $blogId by $userId');
      }
    } catch (e) {
      AppLogger.error('Error liking/unliking blog', e);
      throw Exception('Failed to like/unlike blog: $e');
    }
  }

  /// Check if user has liked a blog
  Future<bool> hasUserLikedBlog(String userId, String blogId) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('likes')
          .where('userId', isEqualTo: userId)
          .where('blogId', isEqualTo: blogId)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      AppLogger.error('Error checking if user liked blog', e);
      return false;
    }
  }

  /// Get blogs liked by user
  Future<List<BlogModel>> getLikedBlogsByUser(String userId, {int limit = 20}) async {
    try {
      // Get liked blog IDs
      QuerySnapshot likesQuery = await _firestore
          .collection('likes')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      if (likesQuery.docs.isEmpty) return [];

      List<String> blogIds = likesQuery.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['blogId'] as String)
          .toList();

      // Get blogs
      List<BlogModel> blogs = [];
      for (String blogId in blogIds) {
        BlogModel? blog = await getBlog(blogId);
        if (blog != null) blogs.add(blog);
      }

      return blogs;
    } catch (e) {
      AppLogger.error('Error getting liked blogs by user', e);
      throw Exception('Failed to get liked blogs: $e');
    }
  }

  // ==================== ANALYTICS ====================

  /// Increment blog view count
  Future<void> incrementBlogViews(String blogId) async {
    try {
      await _firestore.collection('blogs').doc(blogId).update({
        'viewsCount': FieldValue.increment(1),
      });
    } catch (e) {
      AppLogger.warning('Error incrementing blog views (non-critical)', e);
    }
  }

  /// Get user statistics
  Future<Map<String, int>> getUserStats(String userId) async {
    try {
      // Get user document
      UserModel? user = await getUser(userId);
      if (user == null) return {};

      // Get total likes received on user's blogs
      QuerySnapshot userBlogs = await _firestore
          .collection('blogs')
          .where('authorId', isEqualTo: userId)
          .get();

      int totalLikesReceived = 0;
      int totalViews = 0;
      
      for (var doc in userBlogs.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        totalLikesReceived += (data['likesCount'] ?? 0) as int;
        totalViews += (data['viewsCount'] ?? 0) as int;
      }

      return {
        'postsCount': user.postsCount,
        'followersCount': user.followersCount,
        'followingCount': user.followingCount,
        'totalLikesReceived': totalLikesReceived,
        'totalViews': totalViews,
      };
    } catch (e) {
      AppLogger.error('Error getting user stats', e);
      return {};
    }
  }
}
