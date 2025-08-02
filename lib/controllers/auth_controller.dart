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
    // Set persistence to LOCAL (keep user logged in until explicit sign out)
    _setPersistence();
    firebaseUser.bindStream(_auth.authStateChanges());
    ever(firebaseUser, _setInitialScreen);
  }
  
  // Set Firebase Auth persistence to LOCAL
  Future<void> _setPersistence() async {
    try {
      // This is important to prevent automatic logout
      await _auth.setPersistence(Persistence.LOCAL);
    } catch (e) {
      AppLogger.warning('Error setting auth persistence (non-critical): $e');
      // Don't throw error as this is non-critical for authentication flow
    }
  }
  
  _setInitialScreen(User? user) async {
    if (user == null) {
      // User is not logged in
      Get.offAllNamed('/auth');
    } else {
      try {
        // Force token refresh if it's getting close to expiration
        // This helps prevent automatic logouts due to token expiration
        await user.getIdToken(true);
        
        // Check if email is verified when required
        if (user.providerData.any((element) => element.providerId == 'password') && 
            !user.emailVerified) {
          // Only require email verification for email/password sign-in
          Get.offAllNamed('/verify-email');
        } else {
          // User is logged in and verified
          // Load cached data first for faster UI, then update if needed
          await loadCachedUserData();
          Get.offAllNamed('/home');
          // Update user data in background (non-blocking)
          getUserData();
        }
      } catch (e) {
        AppLogger.error('Error refreshing auth token', e);
        // If token refresh fails, try to continue with the flow
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
  
  // Reload the current user
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      AppLogger.error('Error reloading user', e);
    }
  }
  
  // Get current user's email
  String getCurrentUserEmail() {
    return _auth.currentUser?.email ?? 'your email address';
  }
  
  // Get user data from Firestore or create if it doesn't exist
  Future<void> getUserData() async {
    try {
      isLoading.value = true;
      User? user = _auth.currentUser;
      
      if (user != null) {
        // Add timeout to prevent hanging
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 10));
        
        if (userDoc.exists) {
          userModel.value = UserModel.fromMap(
              userDoc.data() as Map<String, dynamic>);
          
          // Cache user data and update last login in parallel (non-blocking)
          Future.wait([
            _cacheUserData(userModel.value!),
            _updateLastLoginAsync(user.uid), // Non-blocking background update
          ]);
        } else {
          // If user document doesn't exist, create it
          String username = '';
          
          // Try to get username from display name or email
          if (user.displayName != null && user.displayName!.isNotEmpty) {
            username = user.displayName!;
          } else if (user.email != null) {
            username = user.email!.split('@')[0]; // Use part before @ as username
          }
          
          UserModel newUser = UserModel(
            uid: user.uid,
            email: user.email ?? '',
            username: username,
            photoURL: user.photoURL,
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
          );
          
          // Save user to Firestore with timeout
          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(newUser.toMap())
              .timeout(const Duration(seconds: 10));
          
          userModel.value = newUser;
          // Cache in background
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

  // Update last login time asynchronously (non-blocking)
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
  
  // Sign in with email and password
  Future<void> signIn(String email, String password) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Add timeout to prevent hanging on sign in
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(const Duration(seconds: 15));

      // Check if email is verified
      if (!(_auth.currentUser?.emailVerified ?? false)) {
        // Navigate to email verification page
        Get.offAllNamed('/verify-email');
        return;
      }

      // Fetch user data and cache in parallel
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
  
  // Sign up with email and password
  Future<void> signUp(String email, String password, String username) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Create user with email and password - add timeout
      UserCredential userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(const Duration(seconds: 15));

      // Create user model
      UserModel newUser = UserModel(
        uid: userCred.user!.uid,
        email: email,
        username: username,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      // Perform parallel operations to speed up the process
      await Future.wait([
        // Send email verification
        userCred.user!.sendEmailVerification().timeout(const Duration(seconds: 10)),
        // Save user to Firestore
        _firestore
            .collection('users')
            .doc(userCred.user!.uid)
            .set(newUser.toMap())
            .timeout(const Duration(seconds: 10)),
      ]);

      userModel.value = newUser;

      // Cache user data in background (non-blocking)
      _cacheUserData(newUser);

      // Show verification message
      Get.snackbar(
        'Account Created',
        'Please check your email to verify your account',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.5),
        colorText: Colors.white,
      );

      // Navigate to email verification page
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
  
  // Sign out
  Future<void> signOut() async {
    try {
      // Sign out from Firebase
      await _auth.signOut();
      
      userModel.value = null;
      
      // Clear cached data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      
      // Navigate back to auth page
      Get.offAllNamed('/auth');
    } catch (e) {
      AppLogger.error('Error during sign out', e);
    }
  }
  
  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      await _auth.sendPasswordResetEmail(email: email);
      Get.snackbar(
        'Password Reset', 
        'Password reset email sent to $email',
        snackPosition: SnackPosition.BOTTOM,
        // ignore: deprecated_member_use
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
  
  // Check if user's email is verified
  bool isEmailVerified() {
    return _auth.currentUser?.emailVerified ?? false;
  }
  
  // Resend verification email
  Future<void> resendVerificationEmail() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        Get.snackbar(
          'Verification Email Sent', 
          'Please check your inbox',
          snackPosition: SnackPosition.BOTTOM,
          // ignore: deprecated_member_use
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
        // ignore: deprecated_member_use
        backgroundColor: Colors.red.withOpacity(0.5),
        colorText: Colors.white,
      );
    }
  }
  
  // Cache user data using SharedPreferences (optimized with timeout)
  Future<void> _cacheUserData(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 5));
      await prefs.setString('user_data', jsonEncode(user.toMap()));
    } catch (e) {
      AppLogger.warning('Error caching user data (non-critical)', e);
      // Don't throw error as this is non-critical for authentication flow
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
      AppLogger.warning('Error loading cached user data (non-critical)', e);
    }
  }
  
  // Get authentication method (email/password)
  String getAuthProvider() {
    User? user = _auth.currentUser;
    if (user == null) return 'none';
    
    List<String> providers = user.providerData.map((e) => e.providerId).toList();
    if (providers.contains('password')) return 'email';
    
    return 'unknown';
  }
}