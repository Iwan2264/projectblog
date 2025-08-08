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
    // Debug logging
    print('🔍 DEBUG: saveDraft called');
    print('🔍 DEBUG: Title: "${titleController.text}"');
    print('🔍 DEBUG: Content length: ${htmlContent.value.length}');
    print('🔍 DEBUG: Category: "${selectedCategory.value}"');
    print('🔍 DEBUG: Current user: ${_authController.userModel.value?.uid}');
    
    // Prevent multiple clicks by checking if already saving
    if (isSavingDraft.value) {
      print('🔍 DEBUG: Already saving, returning');
      return;
    }

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
    
    // Set saving state immediately to prevent multiple clicks
    isSavingDraft.value = true;
    
    try {
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
      
      await editorController.getText().then((content) async {
        htmlContent.value = content;
        
        // Determine document ID once and stick with it
        final String docId = draftId.value.isNotEmpty ? draftId.value : const Uuid().v4();
        
        String? imageURL = imageUrl.value;
        
        // If we have a new image, upload it
        if (mainImage.value != null) {
          final ref = _storage.ref().child('blog_images').child('$docId.jpg');
          final uploadTask = ref.putFile(mainImage.value!);
          final snapshot = await uploadTask;
          imageURL = await snapshot.ref.getDownloadURL();
        }
        
        final draftData = {
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
          'createdAt': draftId.isEmpty ? FieldValue.serverTimestamp() : null,
          'updatedAt': FieldValue.serverTimestamp(),
          'publishedAt': null,
          'likesCount': 0,
          'commentsCount': 0,
          'viewsCount': 0,
          'featured': false,
          'likedBy': <String>[],
          'readTime': BlogPostModel.calculateReadTime(htmlContent.value),
        };
        
        // Save the draft
        await _firestore.collection('blogs').doc(docId).set(
          draftData,
          SetOptions(merge: true),
        );
        
        print('✅ DEBUG: Draft saved to Firestore with ID: $docId');
        
        // Update the draft ID if it was a new draft
        if (draftId.isEmpty) {
          draftId.value = docId;
          print('✅ DEBUG: Draft ID updated to: $docId');
        }
        
        // Update the image URL
        imageUrl.value = imageURL;
        
        Get.snackbar(
          'Success',
          'Draft saved successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 1),
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
    // Debug logging
    print('🚀 DEBUG: publishPost called');
    print('🚀 DEBUG: Title: "${titleController.text}"');
    print('🚀 DEBUG: Content length: ${htmlContent.value.length}');
    print('🚀 DEBUG: Category: "${selectedCategory.value}"');
    print('🚀 DEBUG: Current user: ${_authController.userModel.value?.uid}');
    
    // Prevent multiple clicks by checking if already publishing
    if (isPublishing.value) {
      print('🚀 DEBUG: Already publishing, returning');
      return;
    }

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
    
    // Set publishing state immediately to prevent multiple clicks
    isPublishing.value = true;
    
    try {
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
      
      await editorController.getText().then((content) async {
        htmlContent.value = content;
        
        if (htmlContent.isEmpty) {
          throw Exception('Post content cannot be empty');
        }
        
        // Determine document ID once and stick with it
        final String docId = draftId.value.isNotEmpty ? draftId.value : const Uuid().v4();
        
        // Check if this is already published to prevent duplicates
        if (draftId.value.isEmpty) {
          // For new posts, check if we already have a similar recent post by this user
          final recentPosts = await _firestore
              .collection('blogs')
              .where('authorId', isEqualTo: currentUser.uid)
              .where('title', isEqualTo: titleController.text)
              .where('isDraft', isEqualTo: false)
              .orderBy('publishedAt', descending: true)
              .limit(1)
              .get();
              
          if (recentPosts.docs.isNotEmpty) {
            final lastPost = recentPosts.docs.first;
            final lastPublished = (lastPost.data()['publishedAt'] as Timestamp?)?.toDate();
            if (lastPublished != null && DateTime.now().difference(lastPublished).inMinutes < 5) {
              Get.snackbar(
                'Duplicate Post Detected',
                'You already published a post with this title recently. Please wait a few minutes before publishing again.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.orange.withOpacity(0.8),
                colorText: Colors.white,
                duration: const Duration(seconds: 4),
              );
              return;
            }
          }
        }
        
        String? imageURL = imageUrl.value;
        
        // If we have a new image, upload it
        if (mainImage.value != null) {
          final ref = _storage.ref().child('blog_images').child('$docId.jpg');
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
        
        // Use set with merge to handle both new posts and draft updates
        await _firestore.collection('blogs').doc(docId).set(
          postData,
          SetOptions(merge: true),
        );
        
        print('🎉 DEBUG: Post published to Firestore with ID: $docId');
        
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
