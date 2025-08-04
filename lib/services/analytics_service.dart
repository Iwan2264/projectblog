import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/logger_util.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, int>> getUserStats(String userId) async {
    try {
      UserModel? user;
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        user = UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      if (user == null) return {};

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
        'profileViews': user.profileViews,
      };
    } catch (e) {
      AppLogger.error('Error getting user stats', e);
      return {};
    }
  }
}