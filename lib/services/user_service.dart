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
      // Create main user document with profile data
      await _firestore.collection('users').doc(user.uid).set({
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      // Create profile document in subcollection
      await _firestore.collection('users').doc(user.uid).collection('profile').doc('data').set(user.toMap());
      
      // Create username lookup for uniqueness checks
      if (user.username.isNotEmpty) {
        await _firestore.collection('usernames').doc(user.username.toLowerCase()).set({
          'userId': user.uid,
          'createdAt': FieldValue.serverTimestamp()
        });
      }
      
      AppLogger.info('User created successfully: ${user.uid}');
    } catch (e) {
      AppLogger.error('Error creating user', e);
      throw Exception('Failed to create user: $e');
    }
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).collection('profile').doc('data').get();
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
      // Update profile document in subcollection
      await _firestore.collection('users').doc(uid).collection('profile').doc('data').update(data);
      
      // Update main document timestamp
      await _firestore.collection('users').doc(uid).update({
        'lastUpdated': FieldValue.serverTimestamp()
      });
      
      // If username is being updated, update the lookup collection
      if (data.containsKey('username')) {
        // Get the old username first
        UserModel? user = await getUser(uid);
        if (user != null && user.username != data['username']) {
          // Delete old username document
          if (user.username.isNotEmpty) {
            await _firestore.collection('usernames').doc(user.username.toLowerCase()).delete();
          }
          
          // Create new username document
          await _firestore.collection('usernames').doc(data['username'].toLowerCase()).set({
            'userId': uid,
            'createdAt': FieldValue.serverTimestamp()
          });
        }
      }
      
      AppLogger.info('User updated successfully: $uid');
    } catch (e) {
      AppLogger.error('Error updating user', e);
      throw Exception('Failed to update user: $e');
    }
  }

  Future<String> uploadProfilePicture(String uid, XFile imageFile) async {
    try {
      File file = File(imageFile.path);
      // Use structured path for profile pictures
      Reference ref = _storage.ref().child('users').child(uid).child('profile').child('profile.jpg');
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
      // First lookup the username to get the user ID
      DocumentSnapshot usernameDoc = await _firestore
          .collection('usernames')
          .doc(username.toLowerCase())
          .get();
      
      if (usernameDoc.exists) {
        // Get the user ID from the username document
        String userId = (usernameDoc.data() as Map<String, dynamic>)['userId'];
        
        // Then get the user profile data
        return await getUser(userId);
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
      // Search usernames collection for matching usernames
      QuerySnapshot query = await _firestore
          .collection('usernames')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: searchTerm.toLowerCase())
          .where(FieldPath.documentId, isLessThanOrEqualTo: '${searchTerm.toLowerCase()}\uf8ff')
          .limit(limit)
          .get();
      
      // Get user data for each username match
      List<UserModel> users = [];
      for (var doc in query.docs) {
        String userId = (doc.data() as Map<String, dynamic>)['userId'];
        UserModel? user = await getUser(userId);
        if (user != null) {
          users.add(user);
        }
      }
      
      return users;
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
      Reference ref = _storage.ref().child('users').child(userId).child('profile').child('profile.jpg');
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
      // Get the user to find their username
      UserModel? user = await getUser(userId);
      WriteBatch batch = _firestore.batch();
      
      // Delete username lookup document if exists
      if (user != null && user.username.isNotEmpty) {
        batch.delete(_firestore.collection('usernames').doc(user.username.toLowerCase()));
      }
      
      // Delete all user's blogs
      QuerySnapshot userBlogsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('blogs')
          .get();
      
      for (DocumentSnapshot doc in userBlogsSnapshot.docs) {
        // Delete blog document from user's subcollection
        batch.delete(doc.reference);
        
        // Also delete from global blogs collection
        batch.delete(_firestore.collection('blogs').doc(doc.id));
        
        // Delete comments for this blog
        QuerySnapshot blogCommentsSnapshot = await _firestore
            .collection('comments')
            .where('postId', isEqualTo: doc.id)
            .get();
        
        for (DocumentSnapshot commentDoc in blogCommentsSnapshot.docs) {
          batch.delete(commentDoc.reference);
        }
      }
      
      // Delete user profile document
      batch.delete(_firestore.collection('users').doc(userId).collection('profile').doc('data'));
      
      // Delete user main document
      batch.delete(_firestore.collection('users').doc(userId));
      
      // Commit all Firestore deletions
      await batch.commit();
      
      // Delete all user storage files
      try {
        await _deleteFolder('users/$userId');
      } catch (e) {
        // Folder might not exist or other deletion issues, log but continue
        AppLogger.warning('Error deleting user storage folder', e);
      }
      
      AppLogger.info('User account deleted successfully');
      return true;
    } catch (e) {
      AppLogger.error('Error deleting user account', e);
      return false;
    }
  }
  
  // Helper method to recursively delete a folder in Firebase Storage
  Future<void> _deleteFolder(String path) async {
    try {
      ListResult result = await _storage.ref(path).listAll();
      
      // Delete all files in this directory
      for (Reference ref in result.items) {
        await ref.delete();
      }
      
      // Recursively delete subdirectories
      for (Reference prefix in result.prefixes) {
        await _deleteFolder(prefix.fullPath);
      }
      
      AppLogger.info('Deleted storage folder: $path');
    } catch (e) {
      AppLogger.error('Error deleting storage folder', e);
      rethrow;
    }
  }
}