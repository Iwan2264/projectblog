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
}