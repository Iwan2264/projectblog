import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/like_model.dart';
import '../models/blog_post_model.dart';
import '../utils/logger_util.dart';

class LikeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> likeBlog(String userId, String blogId, String blogAuthorId) async {
    try {
      QuerySnapshot existingLike = await _firestore
          .collection('likes')
          .where('userId', isEqualTo: userId)
          .where('blogId', isEqualTo: blogId)
          .get();

      if (existingLike.docs.isNotEmpty) {
        await _firestore.collection('likes').doc(existingLike.docs.first.id).delete();
        await _firestore.collection('blogs').doc(blogId).update({
          'likesCount': FieldValue.increment(-1),
        });
        AppLogger.info('Blog unliked: $blogId by $userId');
      } else {
        LikeModel like = LikeModel(
          id: '',
          userId: userId,
          blogId: blogId,
          blogAuthorId: blogAuthorId,
          createdAt: DateTime.now(),
        );
        await _firestore.collection('likes').add(like.toMap());
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

  Future<List<BlogPostModel>> getLikedBlogsByUser(String userId, {int limit = 20}) async {
    try {
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

      List<BlogPostModel> blogs = [];
      for (String blogId in blogIds) {
        DocumentSnapshot doc = await _firestore.collection('blogs').doc(blogId).get();
        if (doc.exists) {
          blogs.add(BlogPostModel.fromMap(doc.id, doc.data() as Map<String, dynamic>));
        }
      }

      return blogs;
    } catch (e) {
      AppLogger.error('Error getting liked blogs by user', e);
      throw Exception('Failed to get liked blogs: $e');
    }
  }
}