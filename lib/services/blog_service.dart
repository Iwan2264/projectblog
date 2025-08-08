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

  // Get user's drafts
  Future<List<BlogPostModel>> getUserDrafts(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('blogs')
          .where('authorId', isEqualTo: userId)
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

  // Get user's published posts
  Future<List<BlogPostModel>> getUserPublishedPosts(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('blogs')
          .where('authorId', isEqualTo: userId)
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
      DocumentSnapshot doc = await _firestore.collection('blogs').doc(postId).get();
      
      if (doc.exists) {
        return BlogPostModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      AppLogger.error('Error getting post by ID', e);
      return null;
    }
  }

  // Like/Unlike a post
  Future<bool> togglePostLike(String postId, String userId) async {
    try {
      DocumentReference postRef = _firestore.collection('blogs').doc(postId);
      
      return await _firestore.runTransaction((transaction) async {
        DocumentSnapshot postDoc = await transaction.get(postRef);
        
        if (!postDoc.exists) {
          throw Exception('Post not found');
        }
        
        Map<String, dynamic> data = postDoc.data() as Map<String, dynamic>;
        List<String> likedBy = List<String>.from(data['likedBy'] ?? []);
        int likesCount = data['likesCount'] ?? 0;
        
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
        
        transaction.update(postRef, {
          'likedBy': likedBy,
          'likesCount': likesCount,
        });
        
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
      await _firestore.collection('blogs').doc(postId).update({
        'viewsCount': FieldValue.increment(1),
      });
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
        // Add comment
        transaction.set(
          _firestore.collection('comments').doc(commentId),
          comment.toMap(),
        );
        
        // Increment comment count in post
        transaction.update(
          _firestore.collection('blogs').doc(postId),
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
      QuerySnapshot querySnapshot = await _firestore
          .collection('comments')
          .where('postId', isEqualTo: postId)
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
      QuerySnapshot querySnapshot = await _firestore
          .collection('blogs')
          .where('isDraft', isEqualTo: false)
          .orderBy('likesCount', descending: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs
          .map((doc) => BlogPostModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting popular posts', e);
      return [];
    }
  }
}