import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get_storage/get_storage.dart';

import 'package:projectblog/pages/settings/subpages/appearance_page.dart';
import 'package:projectblog/pages/settings/subpages/language_page.dart';
import 'package:projectblog/pages/settings/subpages/account_page.dart';
import 'package:projectblog/pages/settings/subpages/help_support_page.dart';
import 'package:projectblog/pages/settings/subpages/about_page.dart';

class SettingsController extends GetxController {
  final box = GetStorage();

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
    name.value = box.read('name') ?? 'Safwan';
    username.value = box.read('username') ?? '@safwan';
    email.value = box.read('email') ?? 'safwan@example.com';
    phone.value = box.read('phone') ?? '+91 9876543210';

    nameController.text = name.value;
    usernameController.text = username.value;
    emailController.text = email.value;
    phoneController.text = phone.value;

    final path = box.read('profileImagePath');
    if (path != null && File(path).existsSync()) {
      profileImage.value = File(path);
      profileImagePath.value = path;
    }

    super.onInit();
  }

  void toggleEdit() {
    if (isEditing.value) {
      if (formKey.currentState!.validate()) {
        name.value = nameController.text;
        username.value = usernameController.text;
        email.value = emailController.text;
        phone.value = phoneController.text;

        box.write('name', name.value);
        box.write('username', username.value);
        box.write('email', email.value);
        box.write('phone', phone.value);

        isEditing.value = false;

        Get.snackbar('Saved', 'Profile updated successfully',
            snackPosition: SnackPosition.BOTTOM, duration: Duration(seconds: 2));
      } else {
        Get.snackbar('Error', 'Please correct the errors before saving.',
            snackPosition: SnackPosition.BOTTOM, duration: Duration(seconds: 2));
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

      box.write('profileImagePath', picked.path);
    }
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
        //logout logic
        Get.snackbar('Logout', 'You have been logged out.',
            snackPosition: SnackPosition.BOTTOM, duration: Duration(seconds: 2));
        break;
      default:
        Get.snackbar('Coming Soon', 'No page defined for "$setting"',
            snackPosition: SnackPosition.BOTTOM);
    }
  }
}