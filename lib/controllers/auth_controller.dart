import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../utils/logger_util.dart';

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
    _setPersistence();
    firebaseUser.bindStream(_auth.authStateChanges());
    ever(firebaseUser, _setInitialScreen);
  }
  
  Future<void> _setPersistence() async {
    try {
      await _auth.setPersistence(Persistence.LOCAL);
    } catch (e) {
      AppLogger.warning('Error setting auth persistence (non-critical): $e');
    }
  }
  
  _setInitialScreen(User? user) async {
    if (user == null) {
      Get.offAllNamed('/auth');
    } else {
      try {
        await user.getIdToken(true);
        if (user.providerData.any((element) => element.providerId == 'password') && 
            !user.emailVerified) {
          Get.offAllNamed('/verify-email');
        } else {
          await loadCachedUserData();
          Get.offAllNamed('/home');
          getUserData();
        }
      } catch (e) {
        AppLogger.error('Error refreshing auth token', e);
        if (user.providerData.any((element) => element.providerId == 'password') && 
            !user.emailVerified) {
          Get.offAllNamed('/verify-email');
        } else {
          await loadCachedUserData();
          Get.offAllNamed('/home');
          getUserData();
        }
      }
    }
  }
  
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      AppLogger.error('Error reloading user', e);
    }
  }
  
  String getCurrentUserEmail() {
    return _auth.currentUser?.email ?? 'your email address';
  }
  
  Future<void> getUserData() async {
    try {
      isLoading.value = true;
      User? user = _auth.currentUser;
      
      if (user != null) {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 10));
        
        if (userDoc.exists) {
          userModel.value = UserModel.fromMap(
              userDoc.data() as Map<String, dynamic>);
          Future.wait([
            _cacheUserData(userModel.value!),
            _updateLastLoginAsync(user.uid),
          ]);
        } else {
          String username = '';
          if (user.displayName != null && user.displayName!.isNotEmpty) {
            username = user.displayName!;
          } else if (user.email != null) {
            username = user.email!.split('@')[0];
          }
          UserModel newUser = UserModel(
            uid: user.uid,
            email: user.email ?? '',
            username: username,
            name: '', // empty by default
            photoURL: user.photoURL,
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
          );
          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(newUser.toMap())
              .timeout(const Duration(seconds: 10));
          userModel.value = newUser;
          _cacheUserData(newUser);
        }
      }
    } catch (e) {
      AppLogger.error('Error getting user data', e);
      errorMessage.value = 'Failed to retrieve user data';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _updateLastLoginAsync(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastLoginAt': DateTime.now(),
      }).timeout(const Duration(seconds: 15));
    } on TimeoutException catch (e) {
      AppLogger.warning('Timeout updating last login (non-critical): $e');
    } catch (e) {
      AppLogger.warning('Error updating last login (non-critical): $e');
    }
  }
  
  Future<void> signIn(String email, String password) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(const Duration(seconds: 15));
      if (!(_auth.currentUser?.emailVerified ?? false)) {
        Get.offAllNamed('/verify-email');
        return;
      }
      await Future.wait([
        getUserData(),
        loadCachedUserData(),
      ]);
    } on TimeoutException {
      errorMessage.value = 'Connection timeout. Please try again.';
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          errorMessage.value = 'No user found with this email.';
          break;
        case 'wrong-password':
          errorMessage.value = 'Wrong password provided.';
          break;
        case 'invalid-email':
          errorMessage.value = 'The email address is not valid.';
          break;
        case 'user-disabled':
          errorMessage.value = 'This user has been disabled.';
          break;
        case 'network-request-failed':
          errorMessage.value = 'Network error. Please check your connection.';
          break;
        case 'too-many-requests':
          errorMessage.value = 'Too many attempts. Please try again later.';
          break;
        default:
          errorMessage.value = 'Error during sign in: ${e.message}';
      }
    } catch (e) {
      errorMessage.value = 'An error occurred during sign in.';
      AppLogger.error('Error during sign in', e);
    } finally {
      isLoading.value = false;
    }
  }
  
  // Check if username is taken (UNIQUE usernames)
  Future<bool> isUsernameTaken(String username) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      AppLogger.warning('Error checking username uniqueness', e);
      return true; // Assume taken if error
    }
  }
  
  // UPDATED: Sign up with name, email, password, and unique username
  Future<void> signUp(String email, String password, String username, String name) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // --- USERNAME VALIDATION LOGIC ---
      final RegExp usernameRegex = RegExp(r'^[a-z][a-z0-9]{0,15}$');
      if (username.isEmpty) {
        errorMessage.value = 'Username cannot be empty.';
        return;
      }
      if (username.length > 16) {
        errorMessage.value = 'Username cannot be longer than 16 characters.';
        return;
      }
      if (!usernameRegex.hasMatch(username)) {
        errorMessage.value = 'Invalid username format. Use only lowercase letters and numbers, starting with a letter.';
        return;
      }
      // --- END OF VALIDATION ---

      // Check if username is taken
      bool usernameExists = await isUsernameTaken(username);
      if (usernameExists) {
        errorMessage.value = 'Username already taken';
        return;
      }

      // Create user with email and password
      UserCredential userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(const Duration(seconds: 15));

      // Create user model
      UserModel newUser = UserModel(
        uid: userCred.user!.uid,
        email: email,
        username: username,
        name: name,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      await Future.wait([
        userCred.user!.sendEmailVerification().timeout(const Duration(seconds: 10)),
        _firestore
            .collection('users')
            .doc(userCred.user!.uid)
            .set(newUser.toMap())
            .timeout(const Duration(seconds: 10)),
      ]);

      userModel.value = newUser;
      _cacheUserData(newUser);

      Get.snackbar(
        'Account Created',
        'Please check your email to verify your account',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.5),
        colorText: Colors.white,
      );

      Get.offAllNamed('/verify-email');

    } on TimeoutException {
      errorMessage.value = 'Connection timeout. Please try again.';
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          errorMessage.value = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          errorMessage.value = 'An account already exists for that email.';
          break;
        case 'invalid-email':
          errorMessage.value = 'The email address is not valid.';
          break;
        case 'operation-not-allowed':
          errorMessage.value = 'Email/password accounts are not enabled.';
          break;
        case 'network-request-failed':
          errorMessage.value = 'Network error. Please check your connection.';
          break;
        case 'too-many-requests':
          errorMessage.value = 'Too many attempts. Please try again later.';
          break;
        default:
          errorMessage.value = 'Error during sign up: ${e.message}';
      }
    } catch (e) {
      errorMessage.value = 'An error occurred during sign up.';
      AppLogger.error('Error during sign up', e);
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      userModel.value = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      Get.offAllNamed('/auth');
    } catch (e) {
      AppLogger.error('Error during sign out', e);
    }
  }
  
  Future<void> resetPassword(String email) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      await _auth.sendPasswordResetEmail(email: email);
      Get.snackbar(
        'Password Reset', 
        'Password reset email sent to $email',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue.withOpacity(0.5),
        colorText: Colors.white,
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          errorMessage.value = 'The email address is not valid.';
          break;
        case 'user-not-found':
          errorMessage.value = 'No user found with this email.';
          break;
        default:
          errorMessage.value = 'Error: ${e.message}';
      }
    } finally {
      isLoading.value = false;
    }
  }
  
  bool isEmailVerified() {
    return _auth.currentUser?.emailVerified ?? false;
  }
  
  Future<void> resendVerificationEmail() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        Get.snackbar(
          'Verification Email Sent', 
          'Please check your inbox',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.5),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      AppLogger.error('Error sending verification email', e);
      Get.snackbar(
        'Error', 
        'Failed to send verification email',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.5),
        colorText: Colors.white,
      );
    }
  }
  
  Future<void> _cacheUserData(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 5));
      await prefs.setString('user_data', jsonEncode(user.toMap()));
    } catch (e) {
      AppLogger.warning('Error caching user data (non-critical)', e);
    }
  }
  
  Future<void> loadCachedUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      if (userData != null) {
        userModel.value = UserModel.fromMap(jsonDecode(userData));
      }
    } catch (e) {
      AppLogger.warning('Error loading cached user data (non-critical)', e);
    }
  }
  
  String getAuthProvider() {
    User? user = _auth.currentUser;
    if (user == null) return 'none';
    List<String> providers = user.providerData.map((e) => e.providerId).toList();
    if (providers.contains('password')) return 'email';
    return 'unknown';
  }
}