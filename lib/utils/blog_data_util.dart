import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/blog_post_model.dart';
import '../utils/logger_util.dart';

class BlogDataUtil {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Validates and ensures consistent blog data structure
  static Map<String, dynamic> validateBlogData(Map<String, dynamic> data, String docId) {
    // Ensure required fields are present
    data['id'] = docId; // Always sync document ID
    data['createdAt'] ??= FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    data['likesCount'] ??= 0;
    data['commentsCount'] ??= 0;
    data['viewsCount'] ??= 0;
    data['featured'] ??= false;
    data['likedBy'] ??= <String>[];
    data['tags'] ??= <String>[];
    
    // Validate required string fields
    if (data['title'] == null || data['title'].toString().isEmpty) {
      throw Exception('Blog title is required');
    }
    if (data['content'] == null || data['content'].toString().isEmpty) {
      throw Exception('Blog content is required');
    }
    if (data['authorId'] == null || data['authorId'].toString().isEmpty) {
      throw Exception('Blog authorId is required');
    }
    if (data['category'] == null || data['category'].toString().isEmpty) {
      throw Exception('Blog category is required');
    }
    
    // Calculate read time if not provided
    if (data['readTime'] == null) {
      data['readTime'] = BlogPostModel.calculateReadTime(data['content'].toString());
    }
    
    return data;
  }

  /// Creates intermediate collection documents if they don't exist
  static Future<void> ensureCollectionStructure(String userId) async {
    try {
      final collectionsRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('blogs')
          .doc('collections');
      
      final collectionsDoc = await collectionsRef.get();
      if (!collectionsDoc.exists) {
        await collectionsRef.set({
          'createdAt': FieldValue.serverTimestamp(),
          'type': 'blog_collections',
          'description': 'Container for user blog collections (drafts and published)',
        });
        AppLogger.info('Created collections structure for user: $userId');
      }
    } catch (e) {
      AppLogger.error('Error ensuring collection structure', e);
      rethrow;
    }
  }

  /// Moves a blog post from drafts to published with transaction safety
  static Future<bool> moveDraftToPublished({
    required String userId,
    required String blogId,
    required Map<String, dynamic> blogData,
  }) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        // Validate and prepare data
        final validatedData = validateBlogData(blogData, blogId);
        validatedData['isDraft'] = false;
        validatedData['publishedAt'] = FieldValue.serverTimestamp();
        
        // Ensure collection structure exists
        final collectionsRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('blogs')
            .doc('collections');
        
        final collectionsDoc = await transaction.get(collectionsRef);
        if (!collectionsDoc.exists) {
          transaction.set(collectionsRef, {
            'createdAt': FieldValue.serverTimestamp(),
            'type': 'blog_collections',
          });
        }
        
        // References
        final draftRef = collectionsRef.collection('drafts').doc(blogId);
        final publishedRef = collectionsRef.collection('published').doc(blogId);
        final globalRef = _firestore.collection('blogs').doc(blogId);
        
        // Check if draft exists
        final draftDoc = await transaction.get(draftRef);
        if (draftDoc.exists) {
          // Delete from drafts
          transaction.delete(draftRef);
        }
        
        // Create in published collection
        transaction.set(publishedRef, validatedData);
        
        // Create in global collection
        transaction.set(globalRef, validatedData);
        
        return true;
      });
    } catch (e) {
      AppLogger.error('Error moving draft to published', e);
      return false;
    }
  }

  /// Saves a blog draft with transaction safety
  static Future<bool> saveDraft({
    required String userId,
    required String blogId,
    required Map<String, dynamic> blogData,
  }) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        // Validate and prepare data
        final validatedData = validateBlogData(blogData, blogId);
        validatedData['isDraft'] = true;
        validatedData['publishedAt'] = null;
        
        // Ensure collection structure exists
        final collectionsRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('blogs')
            .doc('collections');
        
        final collectionsDoc = await transaction.get(collectionsRef);
        if (!collectionsDoc.exists) {
          transaction.set(collectionsRef, {
            'createdAt': FieldValue.serverTimestamp(),
            'type': 'blog_collections',
          });
        }
        
        // Save draft
        final draftRef = collectionsRef.collection('drafts').doc(blogId);
        transaction.set(draftRef, validatedData, SetOptions(merge: true));
        
        return true;
      });
    } catch (e) {
      AppLogger.error('Error saving draft', e);
      return false;
    }
  }

  /// Deletes a blog post with transaction safety
  static Future<bool> deleteBlogPost({
    required String userId,
    required String blogId,
  }) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        final collectionsRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('blogs')
            .doc('collections');
        
        final draftRef = collectionsRef.collection('drafts').doc(blogId);
        final publishedRef = collectionsRef.collection('published').doc(blogId);
        final globalRef = _firestore.collection('blogs').doc(blogId);
        
        // Check which collection contains the blog
        final draftDoc = await transaction.get(draftRef);
        final publishedDoc = await transaction.get(publishedRef);
        
        if (draftDoc.exists) {
          // Delete from drafts
          transaction.delete(draftRef);
          AppLogger.info('Deleted draft: $blogId');
        } else if (publishedDoc.exists) {
          // Delete from published and global collections
          transaction.delete(publishedRef);
          transaction.delete(globalRef);
          AppLogger.info('Deleted published post: $blogId');
        } else {
          throw Exception('Blog post not found in any collection');
        }
        
        return true;
      });
    } catch (e) {
      AppLogger.error('Error deleting blog post', e);
      return false;
    }
  }

  /// Updates blog post likes with transaction safety
  static Future<bool> updateLikes({
    required String blogId,
    required String userId,
    required bool isLiked,
  }) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        // Get the global post to find the author
        final globalRef = _firestore.collection('blogs').doc(blogId);
        final globalDoc = await transaction.get(globalRef);
        
        if (!globalDoc.exists) {
          throw Exception('Blog post not found in global collection');
        }
        
        final data = globalDoc.data() as Map<String, dynamic>;
        final authorId = data['authorId'] as String;
        
        // Get user's published post reference
        final userPostRef = _firestore
            .collection('users')
            .doc(authorId)
            .collection('blogs')
            .doc('collections')
            .collection('published')
            .doc(blogId);
        
        final userDoc = await transaction.get(userPostRef);
        if (!userDoc.exists) {
          throw Exception('Blog post not found in user collection');
        }
        
        // Update likes
        List<String> likedBy = List<String>.from(data['likedBy'] ?? []);
        int likesCount = data['likesCount'] ?? 0;
        
        if (isLiked && !likedBy.contains(userId)) {
          likedBy.add(userId);
          likesCount++;
        } else if (!isLiked && likedBy.contains(userId)) {
          likedBy.remove(userId);
          likesCount = (likesCount - 1).clamp(0, double.infinity).toInt();
        }
        
        final updates = {
          'likedBy': likedBy,
          'likesCount': likesCount,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        
        // Update both copies
        transaction.update(globalRef, updates);
        transaction.update(userPostRef, updates);
        
        return true;
      });
    } catch (e) {
      AppLogger.error('Error updating likes', e);
      return false;
    }
  }

  /// Synchronizes data between global and user collections
  static Future<bool> synchronizeCollections() async {
    try {
      // Get all users
      final usersSnapshot = await _firestore.collection('users').get();
      
      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        
        // Ensure collection structure exists
        await ensureCollectionStructure(userId);
        
        // Get user's published posts
        final publishedSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('blogs')
            .doc('collections')
            .collection('published')
            .get();
        
        for (var publishedDoc in publishedSnapshot.docs) {
          final blogId = publishedDoc.id;
          final data = publishedDoc.data();
          
          // Ensure global collection has this post
          final globalRef = _firestore.collection('blogs').doc(blogId);
          final globalDoc = await globalRef.get();
          
          if (!globalDoc.exists) {
            await globalRef.set(validateBlogData(data, blogId));
            AppLogger.info('Synchronized post to global collection: $blogId');
          } else {
            // Ensure document has correct ID field
            if (!data.containsKey('id') || data['id'] != blogId) {
              await publishedDoc.reference.update({'id': blogId});
              await globalRef.update({'id': blogId});
              AppLogger.info('Updated ID field for post: $blogId');
            }
          }
        }
      }
      
      return true;
    } catch (e) {
      AppLogger.error('Error synchronizing collections', e);
      return false;
    }
  }
}
