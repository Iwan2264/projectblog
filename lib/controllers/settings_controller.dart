import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get_storage/get_storage.dart';
import '../utils/navigation_helper.dart';

import 'package:projectblog/pages/settings/appearance_page.dart';
import 'package:projectblog/pages/settings/language_page.dart';
import 'package:projectblog/pages/settings/account_page.dart';
import 'package:projectblog/pages/settings/help_support_page.dart';
import 'package:projectblog/pages/settings/about_page.dart';
import 'package:projectblog/models/user_model.dart';
import 'auth_controller.dart';

class SettingsController extends GetxController {
  // Predefined list of possible interests
  final List<String> allInterests = [
    'Art', 'Business', 'Education', 'Fashion', 'Finance', 'Food', 'Growth',
    'Health', 'Science', 'Sports', 'Tech', 'Travel'
  ];
  final RxList<String> selectedInterests = <String>[].obs;
  final box = GetStorage();
  final AuthController _authController = Get.find<AuthController>();

  // User profile info
  final RxString name = ''.obs;
  final RxString username = ''.obs;
  final RxString email = ''.obs;
  final RxString phone = ''.obs;
  final RxnString profileImagePath = RxnString();
  final Rxn<File> profileImage = Rxn<File>();

  // UI state
  var isEditing = false.obs;
  var isSaving = false.obs;
  var isUploading = false.obs;

  // Input controllers
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final bioController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  // Settings list (updated)
  var settings = <String>[
    'Account',
    'Language',
    'Appearance',
    'Help & Support',
    'About',
    'Logout',
  ].obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
    
    // Listen to auth state changes
    ever(_authController.userModel, (userModel) {
      if (userModel != null) {
        _updateUserDataFromAuth(userModel);
      }
    });
  }

  void _loadUserData() {
    // Try to get data from auth controller first
    if (_authController.userModel.value != null) {
      _updateUserDataFromAuth(_authController.userModel.value!);
    } else {
      // Fallback to stored data if auth data not available
      _loadStoredData();
    }
  }

  void _updateUserDataFromAuth(userModel) {
    // Update from authenticated user data
    name.value = userModel.name ?? '';
    username.value = userModel.username.isNotEmpty ? '@${userModel.username}' : '';
    email.value = userModel.email ?? '';
    // Load phone from storage (not available in auth)
    phone.value = box.read('phone') ?? '';
    // Load bio from userModel
    bioController.text = userModel.bio ?? '';
  // Load interests
  selectedInterests.assignAll(userModel.interests ?? []);
  // Load profile image from auth or storage
    if (userModel.photoURL != null && userModel.photoURL!.isNotEmpty) {
      profileImagePath.value = userModel.photoURL;
      // For network images, we don't set profileImage (File)
    } else {
      // Try to load from local storage
      final localPath = box.read('profileImagePath');
      if (localPath != null && File(localPath).existsSync()) {
        profileImage.value = File(localPath);
        profileImagePath.value = localPath;
      }
    }
    // Update text controllers
    nameController.text = name.value;
    usernameController.text = username.value;
    emailController.text = email.value;
    phoneController.text = phone.value;
    // Save to storage for offline access
    _saveToStorage();
  }

  void _loadStoredData() {
  selectedInterests.assignAll(box.read('interests') != null ? List<String>.from(box.read('interests')) : []);
    // Fallback to stored data
    name.value = box.read('name') ?? 'User';
    username.value = box.read('username') ?? '@user';
    email.value = box.read('email') ?? '';
    phone.value = box.read('phone') ?? '';
    bioController.text = box.read('bio') ?? '';
    nameController.text = name.value;
    usernameController.text = username.value;
    emailController.text = email.value;
    phoneController.text = phone.value;
    final path = box.read('profileImagePath');
    if (path != null && File(path).existsSync()) {
      profileImage.value = File(path);
      profileImagePath.value = path;
    }
  }

  void _saveToStorage() {
  box.write('interests', selectedInterests);
    box.write('name', name.value);
    box.write('username', username.value);
    box.write('email', email.value);
    box.write('phone', phone.value);
    box.write('bio', bioController.text);
    if (profileImagePath.value != null) {
      box.write('profileImagePath', profileImagePath.value);
    }
  }

  void toggleEdit() {
    // No longer used; editing handled in AccountPage directly
  }

  Future<void> saveProfile() async {
    if (isSaving.value) return; // Prevent multiple submissions
    
    try {
      isSaving.value = true;
      
      // Update local values
      String newName = nameController.text.trim();
      String newUsername = usernameController.text.replaceAll('@', '').trim();
      String newEmail = emailController.text.trim();
      String newPhone = phoneController.text.trim();
      String newBio = bioController.text.trim();

      // Update user profile in Firestore through AuthController
      bool success = await _authController.updateUserProfile(
        name: newName,
        bio: newBio,
        interests: selectedInterests.toList(),
      );

      if (success) {
        // Update local values
        name.value = newName;
        username.value = '@$newUsername';
        email.value = newEmail;
        phone.value = newPhone;
        // Save to local storage
        _saveToStorage();
        
        Get.snackbar(
          'Profile Updated', 
          'Your profile has been updated successfully',
          snackPosition: SnackPosition.BOTTOM, 
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green.withAlpha(25),
          colorText: Colors.green,
          margin: const EdgeInsets.all(10),
        );
        
        // Go back to settings page (safer navigation)
        Get.back(result: {'updated': true});
      } else {
        Get.snackbar(
          'Update Failed', 
          'Could not update your profile. Please check your network connection and try again.',
          snackPosition: SnackPosition.BOTTOM, 
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red.withAlpha(25),
          colorText: Colors.red,
          margin: const EdgeInsets.all(10),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error', 
        'An unexpected error occurred: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM, 
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red.withAlpha(25),
        colorText: Colors.red,
        margin: const EdgeInsets.all(10),
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> pickImage() async {
    if (isUploading.value) return; // Prevent multiple uploads
    
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        // No image compression for profile pictures to maintain quality
        // No width/height limits to preserve original resolution
      );
      
      if (picked != null) {
        final file = File(picked.path);
        isUploading.value = true;
        
        // Upload image to Firebase Storage through AuthController
        String? downloadURL = await _authController.uploadProfileImage(file);
        
        if (downloadURL != null) {
          // Update local values
          profileImage.value = file;
          profileImagePath.value = downloadURL;

          // Save to local storage
          box.write('profileImagePath', downloadURL);
          
          Get.snackbar(
            'Image Updated', 
            'Your profile picture has been updated',
            snackPosition: SnackPosition.BOTTOM, 
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green.withAlpha(25),
            colorText: Colors.green,
            margin: const EdgeInsets.all(10),
          );
        } else {
          Get.snackbar(
            'Upload Failed', 
            'Could not upload image. Please check your network connection and try again.',
            snackPosition: SnackPosition.BOTTOM, 
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red.withAlpha(25),
            colorText: Colors.red,
            margin: const EdgeInsets.all(10),
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error', 
        'Failed to select or upload image: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM, 
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red.withAlpha(25),
        colorText: Colors.red,
        margin: const EdgeInsets.all(10),
      );
    } finally {
      isUploading.value = false;
    }
  }

  // Helper method to get profile image (File or network URL)
  dynamic getProfileImageSource() {
    if (profileImage.value != null) {
      return profileImage.value; // Local file
    } else if (profileImagePath.value != null && 
               profileImagePath.value!.startsWith('http')) {
      return profileImagePath.value; // Network URL
    }
    return null;
  }

  // Helper method to check if profile image is from network
  bool isNetworkImage() {
    return profileImagePath.value != null && 
           profileImagePath.value!.startsWith('http');
  }

  // Method to refresh user data from auth controller
  void refreshUserData() {
    if (_authController.userModel.value != null) {
      _updateUserDataFromAuth(_authController.userModel.value!);
    }
  }

  // Method to sync user data with backend
  Future<void> syncUserProfile() async {
    try {
      UserModel? updatedUser = await _authController.getCurrentUserProfile();
      if (updatedUser != null) {
        _updateUserDataFromAuth(updatedUser);
        Get.snackbar('Synced', 'Profile data synchronized',
            snackPosition: SnackPosition.BOTTOM, 
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.blue.withValues(alpha: 0.1),
            colorText: Colors.blue);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to sync profile data',
          snackPosition: SnackPosition.BOTTOM, 
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          colorText: Colors.red);
    }
  }

  void navigateToSetting(String setting) {
    try {
      switch (setting) {
        case 'Account':
          NavigationHelper.toPage(const AccountPage());
          break;
        case 'Language':
          NavigationHelper.toPage(LanguagePage());
          break;
        case 'Appearance':
          NavigationHelper.toPage(AppearancePage());
          break;
        case 'Help & Support':
          NavigationHelper.toPage(HelpSupportPage());
          break;
        case 'About':
          NavigationHelper.toPage(AboutPage());
          break;
        case 'Logout':
          _handleLogout();
          break;
        default:
          Get.snackbar('Coming Soon', 'No page defined for "$setting"',
              snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      print('Navigation error: $e');
      Get.snackbar('Error', 'Could not navigate to the requested page',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _handleLogout() {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Get.back(); // Close dialog
              
              // Show loading
              Get.dialog(
                const Center(
                  child: CircularProgressIndicator(),
                ),
                barrierDismissible: false,
              );
              
              try {
                await _authController.signOut();
                // Clear local settings data
                await box.erase();
                Get.back(); // Close loading
              } catch (e) {
                Get.back(); // Close loading
                Get.snackbar(
                  'Error', 
                  'Failed to logout. Please try again.',
                  snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red.withAlpha(25),
                  colorText: Colors.red,
                );
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}