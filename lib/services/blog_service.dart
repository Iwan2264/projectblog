import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../models/blog_post_model.dart';
import '../models/comment_model.dart';
import '../models/user_model.dart';
import '../utils/logger_util.dart';

class BlogService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get published posts with pagination
  Future<List<BlogPostModel>> getPublishedPosts({
    int limit = 10,
    DocumentSnapshot? lastDocument,
    String? category,
  }) async {
    try {
      // We still use the global blogs collection for efficient querying of all published posts
      Query query = _firestore
          .collection('blogs')
          .where('isDraft', isEqualTo: false)
          .orderBy('publishedAt', descending: true);

      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      query = query.limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      QuerySnapshot querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => BlogPostModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting published posts', e);
      return [];
    }
  }

  // Get user's drafts - directly from user's blogs subcollection
  Future<List<BlogPostModel>> getUserDrafts(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('blogs')
          .where('isDraft', isEqualTo: true)
          .orderBy('updatedAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => BlogPostModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting user drafts', e);
      return [];
    }
  }

  // Get user's published posts - directly from user's blogs subcollection
  Future<List<BlogPostModel>> getUserPublishedPosts(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('blogs')
          .where('isDraft', isEqualTo: false)
          .orderBy('publishedAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => BlogPostModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting user published posts', e);
      return [];
    }
  }

  // Get single post by ID
  Future<BlogPostModel?> getPostById(String postId) async {
    try {
      // First try the global blogs collection (for performance)
      DocumentSnapshot doc = await _firestore.collection('blogs').doc(postId).get();
      
      if (doc.exists) {
        return BlogPostModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }
      
      // If not found, try to find in user's blogs collections
      // (this is a more expensive operation, but ensures we find drafts too)
      String? authorId = await _findPostAuthorId(postId);
      
      if (authorId != null) {
        DocumentSnapshot userBlogDoc = await _firestore
            .collection('users')
            .doc(authorId)
            .collection('blogs')
            .doc(postId)
            .get();
            
        if (userBlogDoc.exists) {
          return BlogPostModel.fromMap(userBlogDoc.id, userBlogDoc.data() as Map<String, dynamic>);
        }
      }
      
      return null;
    } catch (e) {
      AppLogger.error('Error getting post by ID', e);
      return null;
    }
  }
  
  // Helper method to find a post's author ID
  Future<String?> _findPostAuthorId(String postId) async {
    try {
      // Query to find the post in any user's blogs collection
      QuerySnapshot usersSnapshot = await _firestore.collection('users').get();
      
      for (var userDoc in usersSnapshot.docs) {
        String userId = userDoc.id;
        DocumentSnapshot blogDoc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('blogs')
            .doc(postId)
            .get();
            
        if (blogDoc.exists) {
          return userId;
        }
      }
      
      return null;
    } catch (e) {
      AppLogger.error('Error finding post author ID', e);
      return null;
    }
  }

  // Like/Unlike a post
  Future<bool> togglePostLike(String postId, String userId) async {
    try {
      // Get the post from global blogs collection
      DocumentReference globalPostRef = _firestore.collection('blogs').doc(postId);
      DocumentSnapshot globalPostDoc = await globalPostRef.get();
      
      if (!globalPostDoc.exists) {
        throw Exception('Post not found in global collection');
      }
      
      // Get the author ID from the post
      Map<String, dynamic> data = globalPostDoc.data() as Map<String, dynamic>;
      String authorId = data['authorId'];
      
      // Get reference to post in user's blogs collection
      DocumentReference userPostRef = _firestore
          .collection('users')
          .doc(authorId)
          .collection('blogs')
          .doc(postId);
      
      return await _firestore.runTransaction((transaction) async {
        // Get fresh copies of both documents in the transaction
        DocumentSnapshot globalPostDocInTx = await transaction.get(globalPostRef);
        DocumentSnapshot userPostDocInTx = await transaction.get(userPostRef);
        
        if (!globalPostDocInTx.exists || !userPostDocInTx.exists) {
          throw Exception('Post not found');
        }
        
        Map<String, dynamic> globalData = globalPostDocInTx.data() as Map<String, dynamic>;
        List<String> likedBy = List<String>.from(globalData['likedBy'] ?? []);
        int likesCount = globalData['likesCount'] ?? 0;
        
        bool isLiked = likedBy.contains(userId);
        
        if (isLiked) {
          // Unlike
          likedBy.remove(userId);
          likesCount = (likesCount - 1).clamp(0, double.infinity).toInt();
        } else {
          // Like
          likedBy.add(userId);
          likesCount++;
        }
        
        // Update both copies of the post
        Map<String, dynamic> updates = {
          'likedBy': likedBy,
          'likesCount': likesCount,
        };
        
        transaction.update(globalPostRef, updates);
        transaction.update(userPostRef, updates);
        
        return !isLiked; // Return the new like status
      });
    } catch (e) {
      AppLogger.error('Error toggling post like', e);
      return false;
    }
  }

  // Increment post view count
  Future<void> incrementViewCount(String postId) async {
    try {
      // First update the global blogs collection
      await _firestore.collection('blogs').doc(postId).update({
        'viewsCount': FieldValue.increment(1),
      });
      
      // Then find and update the user's copy
      DocumentSnapshot globalPostDoc = await _firestore.collection('blogs').doc(postId).get();
      if (globalPostDoc.exists) {
        String authorId = (globalPostDoc.data() as Map<String, dynamic>)['authorId'];
        
        await _firestore
            .collection('users')
            .doc(authorId)
            .collection('blogs')
            .doc(postId)
            .update({
              'viewsCount': FieldValue.increment(1),
            });
      }
    } catch (e) {
      AppLogger.error('Error incrementing view count', e);
    }
  }

  // Search posts
  Future<List<BlogPostModel>> searchPosts(String searchTerm) async {
    try {
      // Note: This is a basic search. For better search functionality,
      // consider using Algolia or Elasticsearch
      QuerySnapshot querySnapshot = await _firestore
          .collection('blogs')
          .where('isDraft', isEqualTo: false)
          .orderBy('publishedAt', descending: true)
          .get();
      
      List<BlogPostModel> allPosts = querySnapshot.docs
          .map((doc) => BlogPostModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
      
      // Filter posts that contain the search term in title or content
      String lowercaseSearchTerm = searchTerm.toLowerCase();
      return allPosts.where((post) {
        return post.title.toLowerCase().contains(lowercaseSearchTerm) ||
               post.content.toLowerCase().contains(lowercaseSearchTerm) ||
               post.tags.any((tag) => tag.toLowerCase().contains(lowercaseSearchTerm));
      }).toList();
    } catch (e) {
      AppLogger.error('Error searching posts', e);
      return [];
    }
  }

  // Get featured posts
  Future<List<BlogPostModel>> getFeaturedPosts({int limit = 5}) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('blogs')
          .where('isDraft', isEqualTo: false)
          .where('featured', isEqualTo: true)
          .orderBy('publishedAt', descending: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs
          .map((doc) => BlogPostModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting featured posts', e);
      return [];
    }
  }

  // Get posts by category
  Future<List<BlogPostModel>> getPostsByCategory(String category, {int limit = 10}) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('blogs')
          .where('isDraft', isEqualTo: false)
          .where('category', isEqualTo: category)
          .orderBy('publishedAt', descending: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs
          .map((doc) => BlogPostModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting posts by category', e);
      return [];
    }
  }

  // Add comment to post
  Future<String?> addComment(String postId, String content, String userId, UserModel user) async {
    try {
      // First get the blog post to find its author
      DocumentSnapshot globalPostDoc = await _firestore.collection('blogs').doc(postId).get();
      if (!globalPostDoc.exists) {
        throw Exception('Blog post not found');
      }
      
      String authorId = (globalPostDoc.data() as Map<String, dynamic>)['authorId'];
      String commentId = _firestore.collection('comments').doc().id;
      
      CommentModel comment = CommentModel(
        id: commentId,
        postId: postId,
        authorId: userId,
        authorUsername: user.username,
        authorPhotoURL: user.photoURL,
        authorName: user.name,
        content: content,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.runTransaction((transaction) async {
        // Add comment to global comments collection
        transaction.set(
          _firestore.collection('comments').doc(commentId),
          comment.toMap(),
        );
        
        // Add comment to blog's comments subcollection
        transaction.set(
          _firestore
              .collection('users')
              .doc(authorId)
              .collection('blogs')
              .doc(postId)
              .collection('comments')
              .doc(commentId),
          comment.toMap(),
        );
        
        // Increment comment count in global blogs collection
        transaction.update(
          _firestore.collection('blogs').doc(postId),
          {'commentsCount': FieldValue.increment(1)},
        );
        
        // Increment comment count in user's blogs collection
        transaction.update(
          _firestore
              .collection('users')
              .doc(authorId)
              .collection('blogs')
              .doc(postId),
          {'commentsCount': FieldValue.increment(1)},
        );
      });

      return commentId;
    } catch (e) {
      AppLogger.error('Error adding comment', e);
      return null;
    }
  }

  // Get comments for a post
  Future<List<CommentModel>> getPostComments(String postId) async {
    try {
      // First get the post to find the author
      DocumentSnapshot globalPostDoc = await _firestore.collection('blogs').doc(postId).get();
      if (!globalPostDoc.exists) {
        throw Exception('Blog post not found');
      }
      
      String authorId = (globalPostDoc.data() as Map<String, dynamic>)['authorId'];
      
      // Get comments from the blog's comments subcollection
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(authorId)
          .collection('blogs')
          .doc(postId)
          .collection('comments')
          .where('parentCommentId', isNull: true) // Only top-level comments
          .orderBy('createdAt', descending: false)
          .get();
      
      return querySnapshot.docs
          .map((doc) => CommentModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting post comments', e);
      return [];
    }
  }

  // Get popular posts (by likes and views)
  Future<List<BlogPostModel>> getPopularPosts({int limit = 10}) async {
    try {
      // Use a simpler query that doesn't require a composite index
      // First, get all non-draft posts
      QuerySnapshot querySnapshot = await _firestore
          .collection('blogs')
          .where('isDraft', isEqualTo: false)
          .get();
      
      // Convert to BlogPostModel objects
      List<BlogPostModel> allPosts = querySnapshot.docs
          .map((doc) => BlogPostModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
      
      // Sort by likes count on the client side
      allPosts.sort((a, b) => b.likesCount.compareTo(a.likesCount));
      
      // Return only the requested number
      return allPosts.take(limit).toList();
    } catch (e) {
      AppLogger.error('Error getting popular posts', e);
      return [];
    }
  }
}