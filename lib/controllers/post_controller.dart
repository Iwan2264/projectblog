import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:uuid/uuid.dart';

import 'package:projectblog/controllers/auth_controller.dart';
import 'package:projectblog/models/blog_post_model.dart';

class BlogPostController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AuthController _authController = Get.find<AuthController>();
  
  final titleController = TextEditingController();
  final editorController = HtmlEditorController();
  
  // Observables
  final Rx<File?> mainImage = Rx<File?>(null);
  final RxString imageUrl = ''.obs;
  final RxString htmlContent = ''.obs;
  final RxString selectedCategory = ''.obs;
  final RxString draftId = ''.obs;
  
  final RxBool isLoading = false.obs;
  final RxBool isSavingDraft = false.obs;
  final RxBool isPublishing = false.obs;
  
  @override
  void onClose() {
    titleController.dispose();
    super.onClose();
  }
  
  void setMainImage(File? image) {
    mainImage.value = image;
  }
  
  void setCategory(String category) {
    selectedCategory.value = category;
  }

  Future<void> loadDraft(String id) async {
    try {
      isLoading.value = true;
      draftId.value = id;
      
      DocumentSnapshot doc = await _firestore.collection('blogs').doc(id).get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        
        titleController.text = data['title'] ?? '';
        htmlContent.value = data['content'] ?? '';
        imageUrl.value = data['imageUrl'] ?? '';
        selectedCategory.value = data['category'] ?? '';
        
        // Wait a bit for the editor to initialize before setting content
        await Future.delayed(const Duration(milliseconds: 500));
        editorController.setText(htmlContent.value);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load draft: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> saveDraft() async {
    if (titleController.text.isEmpty && htmlContent.isEmpty) {
      Get.snackbar(
        'Error',
        'Post title and content cannot be empty',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }
    
    // Ensure authentication is fresh and valid
    bool isAuthenticated = await _authController.ensureAuthenticated();
    if (!isAuthenticated) {
      Get.snackbar(
        'Authentication Error',
        'You need to be logged in to save a draft. Please log in again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }
    
    // Make sure user data is loaded
    if (_authController.userModel.value == null) {
      await _authController.getUserData();
    }
    
    final currentUser = _authController.userModel.value;
    if (currentUser == null) {
      Get.snackbar(
        'Error',
        'Unable to load user data. Please try logging in again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }
    
    isSavingDraft.value = true;
    
    try {
      await editorController.getText().then((content) async {
        htmlContent.value = content;
        
        String? imageURL = imageUrl.value;
        
        // If we have a new image, upload it
        if (mainImage.value != null) {
          final String blogId = draftId.value.isNotEmpty ? draftId.value : const Uuid().v4();
          final ref = _storage.ref().child('blog_images').child('$blogId.jpg');
          final uploadTask = ref.putFile(mainImage.value!);
          final snapshot = await uploadTask;
          imageURL = await snapshot.ref.getDownloadURL();
        }
        
        // If no draft ID yet, create one
        final String docId = draftId.value.isNotEmpty ? draftId.value : const Uuid().v4();
        draftId.value = docId;
        
        await _firestore.collection('blogs').doc(docId).set({
          'authorId': currentUser.uid,
          'authorUsername': currentUser.username,
          'authorPhotoURL': currentUser.photoURL,
          'authorName': currentUser.name,
          'title': titleController.text,
          'content': htmlContent.value,
          'imageURL': imageURL,
          'category': selectedCategory.value,
          'tags': <String>[],
          'isDraft': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'readTime': BlogPostModel.calculateReadTime(htmlContent.value),
        }, SetOptions(merge: true));
        
        // Update the image URL
        imageUrl.value = imageURL;
        
        Get.snackbar(
          'Success',
          'Draft saved successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
        );
      });
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save draft: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isSavingDraft.value = false;
    }
  }
  
  Future<void> publishPost() async {
    if (titleController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Post title cannot be empty',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    if (selectedCategory.isEmpty) {
      Get.snackbar(
        'Error',
        'Please select a category for the post',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }
    
    // Ensure authentication is fresh and valid
    bool isAuthenticated = await _authController.ensureAuthenticated();
    if (!isAuthenticated) {
      Get.snackbar(
        'Authentication Error',
        'You need to be logged in to publish a post. Please log in again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }
    
    // Make sure user data is loaded
    if (_authController.userModel.value == null) {
      await _authController.getUserData();
    }
    
    final currentUser = _authController.userModel.value;
    if (currentUser == null) {
      Get.snackbar(
        'Error',
        'Unable to load user data. Please try logging in again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }
    
    isPublishing.value = true;
    
    try {
      await editorController.getText().then((content) async {
        htmlContent.value = content;
        
        if (htmlContent.isEmpty) {
          throw Exception('Post content cannot be empty');
        }
        
        String? imageURL = imageUrl.value;
        
        // If we have a new image, upload it
        if (mainImage.value != null) {
          final String blogId = draftId.value.isNotEmpty ? draftId.value : const Uuid().v4();
          final ref = _storage.ref().child('blog_images').child('$blogId.jpg');
          final uploadTask = ref.putFile(mainImage.value!);
          final snapshot = await uploadTask;
          imageURL = await snapshot.ref.getDownloadURL();
        }
        
        final postData = {
          'authorId': currentUser.uid,
          'authorUsername': currentUser.username,
          'authorPhotoURL': currentUser.photoURL,
          'authorName': currentUser.name,
          'title': titleController.text,
          'content': htmlContent.value,
          'imageURL': imageURL,
          'category': selectedCategory.value,
          'tags': <String>[],
          'isDraft': false,
          'createdAt': draftId.isEmpty ? FieldValue.serverTimestamp() : null,
          'updatedAt': FieldValue.serverTimestamp(),
          'publishedAt': FieldValue.serverTimestamp(),
          'likesCount': 0,
          'commentsCount': 0,
          'viewsCount': 0,
          'featured': false,
          'likedBy': <String>[],
          'readTime': BlogPostModel.calculateReadTime(htmlContent.value),
        };
        
        // If draft exists, update it, otherwise create a new document
        final String docId = draftId.value.isNotEmpty ? draftId.value : const Uuid().v4();
        await _firestore.collection('blogs').doc(docId).set(
          postData,
          SetOptions(merge: true),
        );
        
        Get.snackbar(
          'Success',
          'Post published successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
        );
        
        Get.back(); // Go back to previous screen after publishing
      });
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to publish post: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isPublishing.value = false;
    }
  }
  
  Future<void> deleteDraft() async {
    // If no draft ID yet, just clear the form
    if (draftId.isEmpty) {
      clearForm();
      return;
    }
    
    // Ensure authentication is fresh and valid
    bool isAuthenticated = await _authController.ensureAuthenticated();
    if (!isAuthenticated) {
      Get.snackbar(
        'Authentication Error',
        'You need to be logged in to delete a draft. Please log in again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }
    
    // Show confirmation dialog
    final bool confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Draft'),
        content: const Text('Are you sure you want to delete this draft? This action cannot be undone.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    ) ?? false;
    
    if (!confirm) return;
    
    try {
      isSavingDraft.value = true;
      
      // Delete from Firestore
      await _firestore.collection('blogs').doc(draftId.value).delete();
      
      // Delete associated image if exists
      if (imageUrl.value.isNotEmpty) {
        try {
          await _storage.refFromURL(imageUrl.value).delete();
        } catch (e) {
          print('Error deleting image: $e');
        }
      }
      
      Get.snackbar(
        'Success',
        'Draft deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
      );
      
      // Clear form and navigate back
      clearForm();
      Get.back();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete draft: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isSavingDraft.value = false;
    }
  }
  
  void clearForm() {
    titleController.clear();
    editorController.clear();
    htmlContent.value = '';
    mainImage.value = null;
    imageUrl.value = '';
    selectedCategory.value = '';
    draftId.value = '';
  }
}
