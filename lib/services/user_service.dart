import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../utils/logger_util.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toMap());
      AppLogger.info('User created successfully: ${user.uid}');
    } catch (e) {
      AppLogger.error('Error creating user', e);
      throw Exception('Failed to create user: $e');
    }
  }

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

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
      AppLogger.info('User updated successfully: $uid');
    } catch (e) {
      AppLogger.error('Error updating user', e);
      throw Exception('Failed to update user: $e');
    }
  }

  Future<String> uploadProfilePicture(String uid, XFile imageFile) async {
    try {
      File file = File(imageFile.path);
      Reference ref = _storage.ref().child('profile_pictures').child('$uid.jpg');
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadURL = await snapshot.ref.getDownloadURL();
      await updateUser(uid, {'photoURL': downloadURL});
      AppLogger.info('Profile picture uploaded successfully: $uid');
      return downloadURL;
    } catch (e) {
      AppLogger.error('Error uploading profile picture', e);
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  Future<void> incrementProfileViews(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'profileViews': FieldValue.increment(1),
      });
    } catch (e) {
      AppLogger.warning('Error incrementing profile views (non-critical)', e);
    }
  }

  // Get user by username
  Future<UserModel?> getUserByUsername(String username) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        return UserModel.fromMap(query.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      AppLogger.error('Error getting user by username', e);
      return null;
    }
  }

  // Search users by username
  Future<List<UserModel>> searchUsers(String searchTerm, {int limit = 20}) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: searchTerm.toLowerCase())
          .where('username', isLessThanOrEqualTo: searchTerm.toLowerCase() + '\uf8ff')
          .limit(limit)
          .get();
      
      return query.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.error('Error searching users', e);
      return [];
    }
  }

  // Update user profile with enhanced fields
  Future<bool> updateUserProfile({
    required String userId,
    String? name,
    String? bio,
    List<String>? interests,
    File? profileImage,
  }) async {
    try {
      Map<String, dynamic> updateData = {};

      if (name != null) updateData['name'] = name;
      if (bio != null) updateData['bio'] = bio;
      if (interests != null) updateData['interests'] = interests;

      // Upload profile image if provided
      if (profileImage != null) {
        String imageUrl = await _uploadProfileImage(userId, profileImage);
        updateData['photoURL'] = imageUrl;
      }

      updateData['lastLoginAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('users').doc(userId).update(updateData);
      
      AppLogger.info('User profile updated successfully');
      return true;
    } catch (e) {
      AppLogger.error('Error updating user profile', e);
      return false;
    }
  }

  // Upload profile image
  Future<String> _uploadProfileImage(String userId, File imageFile) async {
    try {
      Reference ref = _storage.ref().child('profile_images').child('$userId.jpg');
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadURL = await snapshot.ref.getDownloadURL();
      
      AppLogger.info('Profile image uploaded successfully');
      return downloadURL;
    } catch (e) {
      AppLogger.error('Error uploading profile image', e);
      throw Exception('Failed to upload profile image');
    }
  }

  // Delete user account and all associated data
  Future<bool> deleteUserAccount(String userId) async {
    try {
      WriteBatch batch = _firestore.batch();
      
      // Delete user document
      batch.delete(_firestore.collection('users').doc(userId));
      
      // Delete user's posts
      QuerySnapshot userPosts = await _firestore
          .collection('blogs')
          .where('authorId', isEqualTo: userId)
          .get();
      
      for (DocumentSnapshot doc in userPosts.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete user's comments
      QuerySnapshot userComments = await _firestore
          .collection('comments')
          .where('authorId', isEqualTo: userId)
          .get();
      
      for (DocumentSnapshot doc in userComments.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      // Delete profile image from storage
      try {
        await _storage.ref().child('profile_images').child('$userId.jpg').delete();
      } catch (e) {
        // Image might not exist, ignore error
        AppLogger.warning('Profile image not found for deletion', e);
      }
      
      AppLogger.info('User account deleted successfully');
      return true;
    } catch (e) {
      AppLogger.error('Error deleting user account', e);
      return false;
    }
  }
}