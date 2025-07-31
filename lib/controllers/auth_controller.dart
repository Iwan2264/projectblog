import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/user_model.dart';

class AuthController extends GetxController {
  static AuthController instance = Get.find();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final GoogleSignIn _googleSignIn;
  
  Rx<User?> firebaseUser = Rx<User?>(null);
  Rx<UserModel?> userModel = Rx<UserModel?>(null);
  
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    _googleSignIn = GoogleSignIn.instance;
    _initializeGoogleSignIn();
    firebaseUser.bindStream(_auth.authStateChanges());
    ever(firebaseUser, _setInitialScreen);
  }
  
  Future<void> _initializeGoogleSignIn() async {
    try {
      await _googleSignIn.initialize();
      _googleSignIn.authenticationEvents.listen(
        _handleAuthenticationEvent,
        onError: _handleAuthenticationError,
      );
    } catch (e) {
      print('Error initializing Google Sign In: $e');
    }
  }
  
  void _handleAuthenticationEvent(GoogleSignInAuthenticationEvent event) {
    // Handle Google Sign-In authentication events if needed
    print('Google Sign-In authentication event: $event');
  }
  
  void _handleAuthenticationError(Object error) {
    print('Google Sign-In authentication error: $error');
  }
  
  _setInitialScreen(User? user) async {
    if (user == null) {
      // User is not logged in
      Get.offAllNamed('/auth');
    } else {
      // Check if email is verified when required
      if (user.providerData.any((element) => element.providerId == 'password') && 
          !user.emailVerified) {
        // Only require email verification for email/password sign-in
        Get.offAllNamed('/verify-email');
      } else {
        // User is logged in and verified (or using Google sign-in)
        await getUserData();
        Get.offAllNamed('/home');
      }
    }
  }
  
  // Reload the current user
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      print('Error reloading user: $e');
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
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          userModel.value = UserModel.fromMap(
              userDoc.data() as Map<String, dynamic>);
          
          // Update last login time
          await _firestore.collection('users').doc(user.uid).update({
            'lastLoginAt': DateTime.now(),
          });
          
          // Cache user data
          await _cacheUserData(userModel.value!);
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
          
          // Save user to Firestore
          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(newUser.toMap());
          
          userModel.value = newUser;
          await _cacheUserData(newUser);
        }
      }
    } catch (e) {
      print('Error getting user data: $e');
      errorMessage.value = 'Failed to retrieve user data';
    } finally {
      isLoading.value = false;
    }
  }
  
  // Sign in with email and password
  Future<void> signIn(String email, String password) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Check if email is verified
      if (!(_auth.currentUser?.emailVerified ?? false)) {
        // Navigate to email verification page
        Get.offAllNamed('/verify-email');
        return;
      }
      
      await getUserData();
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
  
  // Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      // Check if the platform supports authenticate method
      if (_googleSignIn.supportsAuthenticate()) {
        // Use authenticate method for supported platforms
        await _googleSignIn.authenticate();
        
        // Listen for authentication events to get the user
        await for (final event in _googleSignIn.authenticationEvents) {
          if (event is GoogleSignInAuthenticationEventSignIn) {
            final GoogleSignInAccount googleUser = event.user;
            await _signInToFirebaseWithGoogleUser(googleUser);
            break;
          } else if (event is GoogleSignInAuthenticationEventSignOut) {
            // User cancelled or signed out
            break;
          }
        }
      } else {
        errorMessage.value = 'Google Sign-In not supported on this platform';
      }
    } catch (e) {
      if (e.toString().contains('canceled')) {
        // User cancelled the sign-in flow
        errorMessage.value = '';
      } else {
        errorMessage.value = 'An error occurred during Google sign in.';
        print('Error during Google sign in: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> _signInToFirebaseWithGoogleUser(GoogleSignInAccount googleUser) async {
    try {
      // Get authentication token (this should work without await in newer versions)
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      
      // Create Firebase credential using idToken (which should be available)
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      
      // Sign in to Firebase with the Google credential
      await _auth.signInWithCredential(credential);
      
      // Get user data (or create if first time)
      await getUserData();
    } catch (e) {
      print('Error signing in to Firebase with Google user: $e');
      throw e;
    }
  }
  
  // Sign up with email and password
  Future<void> signUp(String email, String password, String username) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      // Create user with email and password
      UserCredential userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Send email verification
      await userCred.user!.sendEmailVerification();
      
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
  
  // Sign out
  Future<void> signOut() async {
    try {
      // Sign out from Firebase
      await _auth.signOut();
      
      // Disconnect from Google (if used) - this also signs out
      await _googleSignIn.disconnect();
      
      userModel.value = null;
      
      // Clear cached data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      
      // Navigate back to auth page
      Get.offAllNamed('/auth');
    } catch (e) {
      print('Error during sign out: $e');
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
          backgroundColor: Colors.green.withOpacity(0.5),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('Error sending verification email: $e');
      Get.snackbar(
        'Error', 
        'Failed to send verification email',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.5),
        colorText: Colors.white,
      );
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
  
  // Get authentication method (email/password or Google)
  String getAuthProvider() {
    User? user = _auth.currentUser;
    if (user == null) return 'none';
    
    List<String> providers = user.providerData.map((e) => e.providerId).toList();
    if (providers.contains('google.com')) return 'google';
    if (providers.contains('password')) return 'email';
    
    return 'unknown';
  }
}