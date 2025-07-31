import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/user_model.dart';

class AuthController extends GetxController {
  static AuthController instance = Get.find();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Rx<User?> firebaseUser = Rx<User?>(null);
  Rx<UserModel?> userModel = Rx<UserModel?>(null);
  
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(_auth.authStateChanges());
    ever(firebaseUser, _setInitialScreen);
  }
  
  _setInitialScreen(User? user) async {
    if (user == null) {
      // User is not logged in
      Get.offAllNamed('/auth');
    } else {
      // User is logged in, fetch user data
      await getUserData();
      Get.offAllNamed('/home');
    }
  }
  
  Future<void> getUserData() async {
    try {
      isLoading.value = true;
      User? user = _auth.currentUser;
      
      if (user != null) {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          userModel.value = UserModel.fromMap(
              userDoc.data() as Map<String, dynamic>);
          
          // Cache user data
          await _cacheUserData(userModel.value!);
        }
      }
    } catch (e) {
      print('Error getting user data: $e');
      errorMessage.value = 'Failed to retrieve user data';
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> signIn(String email, String password) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update last login time
      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'lastLoginAt': DateTime.now(),
      });
      
      await getUserData();
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          errorMessage.value = 'No user found with this email.';
          break;
        case 'wrong-password':
          errorMessage.value = 'Wrong password provided.';
          break;
        default:
          errorMessage.value = 'Error during sign in: ${e.message}';
      }
    } catch (e) {
      errorMessage.value = 'An error occurred during sign in.';
      print('Error during sign in: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> signUp(String email, String password, String username) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      // Create user with email and password
      UserCredential userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Create user model
      UserModel newUser = UserModel(
        uid: userCred.user!.uid,
        email: email,
        username: username,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
      
      // Save user to Firestore
      await _firestore
          .collection('users')
          .doc(userCred.user!.uid)
          .set(newUser.toMap());
      
      userModel.value = newUser;
      
      // Cache user data
      await _cacheUserData(newUser);
      
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          errorMessage.value = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          errorMessage.value = 'An account already exists for that email.';
          break;
        default:
          errorMessage.value = 'Error during sign up: ${e.message}';
      }
    } catch (e) {
      errorMessage.value = 'An error occurred during sign up.';
      print('Error during sign up: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      userModel.value = null;
      
      // Clear cached data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
    } catch (e) {
      print('Error during sign out: $e');
    }
  }
  
  Future<void> resetPassword(String email) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      await _auth.sendPasswordResetEmail(email: email);
      Get.snackbar('Password Reset', 'Password reset email sent to $email');
    } on FirebaseAuthException catch (e) {
      errorMessage.value = 'Error: ${e.message}';
    } finally {
      isLoading.value = false;
    }
  }
  
  // Cache user data using SharedPreferences
  Future<void> _cacheUserData(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(user.toMap()));
    } catch (e) {
      print('Error caching user data: $e');
    }
  }
  
  // Load cached user data
  Future<void> loadCachedUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      
      if (userData != null) {
        userModel.value = UserModel.fromMap(jsonDecode(userData));
      }
    } catch (e) {
      print('Error loading cached user data: $e');
    }
  }
}
