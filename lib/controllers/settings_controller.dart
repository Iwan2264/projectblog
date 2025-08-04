import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get_storage/get_storage.dart';

import 'package:projectblog/pages/settings/appearance_page.dart';
import 'package:projectblog/pages/settings/language_page.dart';
import 'package:projectblog/pages/settings/account_page.dart';
import 'package:projectblog/pages/settings/help_support_page.dart';
import 'package:projectblog/pages/settings/about_page.dart';
import 'auth_controller.dart';

class SettingsController extends GetxController {
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

  // Input controllers
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
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
    name.value = userModel.username ?? '';
    username.value = userModel.username.isNotEmpty ? '@${userModel.username}' : '';
    email.value = userModel.email ?? '';
    
    // Load phone from storage (not available in auth)
    phone.value = box.read('phone') ?? '';
    
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
    // Fallback to stored data
    name.value = box.read('name') ?? 'User';
    username.value = box.read('username') ?? '@user';
    email.value = box.read('email') ?? '';
    phone.value = box.read('phone') ?? '';

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
    box.write('name', name.value);
    box.write('username', username.value);
    box.write('email', email.value);
    box.write('phone', phone.value);
    if (profileImagePath.value != null) {
      box.write('profileImagePath', profileImagePath.value);
    }
  }

  void toggleEdit() {
    if (isEditing.value) {
      if (formKey.currentState!.validate()) {
        // Update local values
        name.value = nameController.text;
        username.value = usernameController.text;
        email.value = emailController.text;
        phone.value = phoneController.text;

        // Save to local storage
        _saveToStorage();

        // TODO: Update user profile in Firestore through auth controller
        // This would require adding an updateUserProfile method to AuthController
        
        isEditing.value = false;

        Get.snackbar('Saved', 'Profile updated successfully',
            snackPosition: SnackPosition.BOTTOM, 
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green.withOpacity(0.1),
            colorText: Colors.green);
      } else {
        Get.snackbar('Error', 'Please correct the errors before saving.',
            snackPosition: SnackPosition.BOTTOM, 
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red.withOpacity(0.1),
            colorText: Colors.red);
      }
    } else {
      isEditing.value = true;
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final file = File(picked.path);
      profileImage.value = file;
      profileImagePath.value = picked.path;

      // Save to local storage
      box.write('profileImagePath', picked.path);
      
      // TODO: Upload image to Firebase Storage and update user profile
      // This would require adding an updateProfileImage method to AuthController
      
      Get.snackbar('Image Updated', 'Profile image updated successfully',
          snackPosition: SnackPosition.BOTTOM, 
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green.withOpacity(0.1),
          colorText: Colors.green);
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

  // Method to sync user data with backend (placeholder for future implementation)
  Future<void> syncUserProfile() async {
    // TODO: Implement sync with Firestore through AuthController
    // This would involve updating the user document in Firestore
    // with the current profile data
  }

  void navigateToSetting(String setting) {
    switch (setting) {
      case 'Account':
        Get.to(() => AccountPage());
        break;
      case 'Language':
        Get.to(() => LanguagePage());
        break;
      case 'Appearance':
        Get.to(() => AppearancePage());
        break;
      case 'Help & Support':
        Get.to(() => HelpSupportPage());
        break;
      case 'About':
        Get.to(() => AboutPage());
        break;
      case 'Logout':
        _handleLogout();
        break;
      default:
        Get.snackbar('Coming Soon', 'No page defined for "$setting"',
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
                  backgroundColor: Colors.red.withOpacity(0.1),
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