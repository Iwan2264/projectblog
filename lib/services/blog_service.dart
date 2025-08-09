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

  // Get user's drafts - from drafts subcollection
  Future<List<BlogPostModel>> getUserDrafts(String userId) async {
    try {
      print('📝 DEBUG: Fetching drafts from users/$userId/blogs/drafts');
      
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('blogs')
          .doc('collections')
          .collection('drafts')
          .orderBy('updatedAt', descending: true)
          .get();
      
      print('📝 DEBUG: Found ${querySnapshot.docs.length} drafts');
      
      return querySnapshot.docs
          .map((doc) => BlogPostModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting user drafts', e);
      print('❌ DEBUG: Error fetching drafts: $e');
      return [];
    }
  }

  // Get user's published posts - from published subcollection
  Future<List<BlogPostModel>> getUserPublishedPosts(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('blogs')
          .doc('collections')
          .collection('published')
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
      
      // If not found, try to find in user's blogs subcollections
      // (this is a more expensive operation, but ensures we find drafts too)
      String? authorId = await _findPostAuthorId(postId);
      
      if (authorId != null) {
        // Check drafts first
        DocumentSnapshot draftDoc = await _firestore
            .collection('users')
            .doc(authorId)
            .collection('blogs')
            .doc('collections')
            .collection('drafts')
            .doc(postId)
            .get();
            
        if (draftDoc.exists) {
          return BlogPostModel.fromMap(draftDoc.id, draftDoc.data() as Map<String, dynamic>);
        }
        
        // Then check published
        DocumentSnapshot publishedDoc = await _firestore
            .collection('users')
            .doc(authorId)
            .collection('blogs')
            .doc('collections')
            .collection('published')
            .doc(postId)
            .get();
            
        if (publishedDoc.exists) {
          return BlogPostModel.fromMap(publishedDoc.id, publishedDoc.data() as Map<String, dynamic>);
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
      // Query to find the post in any user's blogs subcollections
      QuerySnapshot usersSnapshot = await _firestore.collection('users').get();
      
      for (var userDoc in usersSnapshot.docs) {
        String userId = userDoc.id;
        
        // Check in drafts subcollection
        DocumentSnapshot draftDoc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('blogs')
            .doc('collections')
            .collection('drafts')
            .doc(postId)
            .get();
            
        if (draftDoc.exists) {
          return userId;
        }
        
        // Check in published subcollection
        DocumentSnapshot publishedDoc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('blogs')
            .doc('collections')
            .collection('published')
            .doc(postId)
            .get();
            
        if (publishedDoc.exists) {
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
      
      // Get reference to post in user's published blogs subcollection
      DocumentReference userPostRef = _firestore
          .collection('users')
          .doc(authorId)
          .collection('blogs')
          .doc('collections')
          .collection('published')
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
      // First check if the post exists and get the author ID
      DocumentSnapshot globalPostDoc = await _firestore.collection('blogs').doc(postId).get();
      if (!globalPostDoc.exists) {
        print('📝 DEBUG: Post not found in global collection when trying to increment view count');
        return;
      }
      
      // Create a server timestamp for the update
      final serverTimestamp = FieldValue.serverTimestamp();
      final String authorId = (globalPostDoc.data() as Map<String, dynamic>)['authorId'];
      
      // Try to use a transaction for atomicity
      try {
        await _firestore.runTransaction((transaction) async {
          // Update the global blogs collection
          transaction.update(_firestore.collection('blogs').doc(postId), {
            'viewsCount': FieldValue.increment(1),
            'lastViewed': serverTimestamp,
          });
          
          // Update the user's published copy
          transaction.update(
            _firestore.collection('users').doc(authorId).collection('blogs').doc('collections').collection('published').doc(postId),
            {
              'viewsCount': FieldValue.increment(1),
              'lastViewed': serverTimestamp,
            }
          );
        });
      } catch (transactionError) {
        // If the transaction fails (likely due to permission issues), try an alternative approach
        // This might happen if the viewer is not the author and doesn't have permission to update
        print('📝 DEBUG: Transaction failed when incrementing view count, using alternative approach');
        
        // Create an analytics record instead (which can be processed by a Cloud Function or aggregated later)
        try {
          await _firestore.collection('analytics').add({
            'type': 'view',
            'postId': postId,
            'authorId': authorId,
            'timestamp': serverTimestamp,
            // Don't include user ID to respect privacy
          });
        } catch (analyticsError) {
          print('📝 DEBUG: Failed to create analytics record: $analyticsError');
        }
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
        
        // Add comment to blog's comments subcollection in published posts
        transaction.set(
          _firestore
              .collection('users')
              .doc(authorId)
              .collection('blogs')
              .doc('collections')
              .collection('published')
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
        
        // Increment comment count in user's published blogs collection
        transaction.update(
          _firestore
              .collection('users')
              .doc(authorId)
              .collection('blogs')
              .doc('collections')
              .collection('published')
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
      
      // Get comments from the blog's comments subcollection in published posts
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(authorId)
          .collection('blogs')
          .doc('collections')
          .collection('published')
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

  // Helper method to synchronize document IDs between collections
  Future<bool> synchronizePostDocumentIds() async {
    try {
      // Get all global blog posts
      QuerySnapshot globalPosts = await _firestore.collection('blogs').get();
      
      for (var globalDoc in globalPosts.docs) {
        Map<String, dynamic> data = globalDoc.data() as Map<String, dynamic>;
        String authorId = data['authorId'];
        String postId = globalDoc.id;
        
        // Check if the post exists in the user's published collection
        DocumentReference userPostRef = _firestore
            .collection('users')
            .doc(authorId)
            .collection('blogs')
            .doc('collections')
            .collection('published')
            .doc(postId);
            
        DocumentSnapshot userPostDoc = await userPostRef.get();
        
        if (!userPostDoc.exists) {
          // Post doesn't exist in user's collection, create it
          await userPostRef.set(data, SetOptions(merge: true));
          print('✅ Synchronized post $postId for user $authorId');
        } else {
          // Ensure the document has the correct ID field
          Map<String, dynamic> userData = userPostDoc.data() as Map<String, dynamic>;
          if (userData['id'] != postId) {
            await userPostRef.update({'id': postId});
            print('✅ Updated ID field for post $postId');
          }
        }
      }
      
      return true;
    } catch (e) {
      AppLogger.error('Error synchronizing document IDs', e);
      return false;
    }
  }

  // Delete a blog post (works for both drafts and published posts)
  Future<bool> deleteBlogPost(String blogId, String userId) async {
    try {
      print('🗑️ DEBUG: Attempting to delete blog with ID: $blogId by user: $userId');
      
      // Check if it's a draft first
      DocumentSnapshot draftDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('blogs')
          .doc('collections')
          .collection('drafts')
          .doc(blogId)
          .get();
      
      bool isDraft = draftDoc.exists;
      bool isPublished = false;
      
      if (!isDraft) {
        // Check if it's a published post
        DocumentSnapshot publishedDoc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('blogs')
            .doc('collections')
            .collection('published')
            .doc(blogId)
            .get();
        
        isPublished = publishedDoc.exists;
        
        if (!isPublished) {
          print('❌ DEBUG: Blog post not found in either drafts or published collections');
          return false;
        }
      }
      
      print('🔍 DEBUG: Blog is draft: $isDraft, published: $isPublished');
      
      // Execute deletes
      try {
        if (isDraft) {
          // Delete from drafts subcollection
          await _firestore
            .collection('users')
            .doc(userId)
            .collection('blogs')
            .doc('collections')
            .collection('drafts')
            .doc(blogId)
            .delete();
        } else if (isPublished) {
          // Delete from published subcollection
          await _firestore
            .collection('users')
            .doc(userId)
            .collection('blogs')
            .doc('collections')
            .collection('published')
            .doc(blogId)
            .delete();
          
          // Also delete from global collection for published posts
          await _firestore
            .collection('blogs')
            .doc(blogId)
            .delete();
        }
        
        print('✅ DEBUG: Blog post deleted successfully');
        return true;
      } catch (deleteError) {
        AppLogger.error('Error during delete operations', deleteError);
        print('❌ DEBUG: Error in delete operations: $deleteError');
        return false;
      }
    } catch (e) {
      AppLogger.error('Error deleting blog post', e);
      print('❌ DEBUG: Error deleting blog: $e');
      return false;
    }
  }
}