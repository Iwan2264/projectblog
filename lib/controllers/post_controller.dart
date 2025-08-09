import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:uuid/uuid.dart';

import 'package:projectblog/controllers/auth_controller.dart';
import 'package:projectblog/controllers/blog_controller.dart';
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
  final RxBool isDraftSaved = false.obs;
  
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
      
      // Get the current user
      final currentUser = _authController.userModel.value;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      print('🔍 DEBUG: Loading draft with ID: $id for user: ${currentUser.uid}');
      
      // Try to load from the user's blogs subcollection first
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('blogs')
          .doc(id)
          .get();
      
      // If not found in user collection, try the global blogs collection (for backward compatibility)
      if (!userDoc.exists) {
        print('🔍 DEBUG: Draft not found in user collection, trying global collection');
        userDoc = await _firestore.collection('blogs').doc(id).get();
      }
      
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        
        titleController.text = data['title'] ?? '';
        htmlContent.value = data['content'] ?? '';
        imageUrl.value = data['imageURL'] ?? ''; // Note the capital URL in imageURL
        selectedCategory.value = data['category'] ?? '';
        
        print('🔍 DEBUG: Draft loaded successfully. Title: ${data['title']}, Category: ${data['category']}');
        
        // Wait a bit for the editor to initialize before setting content
        await Future.delayed(const Duration(milliseconds: 500));
        
        try {
          // Add style info in a hidden div at the beginning
          if (!htmlContent.value.contains('class="editor-styles"')) {
            const String styleDiv = '<div style="display:none" class="editor-styles">img {max-width: 100%; height: auto; display: block; margin: 0 auto;}</div>';
            htmlContent.value = styleDiv + htmlContent.value;
          }
          
          // Set the content in the editor
          editorController.setText(htmlContent.value);
        } catch (e) {
          print('⚠️ DEBUG: Error setting HTML content: $e');
          // Try again after a longer delay
          await Future.delayed(const Duration(seconds: 1));
          editorController.setText(htmlContent.value);
        }
      } else {
        print('⚠️ DEBUG: Draft not found in either collection');
        throw Exception('Draft not found');
      }
    } catch (e) {
      print('❌ DEBUG: Error loading draft: $e');
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
  
  Future<bool> saveDraft() async {
    // Debug logging
    print('🔍 DEBUG: saveDraft called');
    print('🔍 DEBUG: Title: "${titleController.text}"');
    print('🔍 DEBUG: Content length: ${htmlContent.value.length}');
    print('🔍 DEBUG: Category: "${selectedCategory.value}"');
    print('🔍 DEBUG: Current user: ${_authController.userModel.value?.uid}');
    
    // Prevent multiple clicks by checking if already saving
    if (isSavingDraft.value) {
      print('🔍 DEBUG: Already saving, returning');
      return false;
    }

    if (titleController.text.isEmpty && htmlContent.isEmpty) {
      Get.snackbar(
        'Error',
        'Post title and content cannot be empty',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return false;
    }
    
    // Check content size to prevent SQLite issues (Firestore has 1MB limit per document)
    const int maxContentSize = 500 * 1024; // 500KB limit for content
    if (htmlContent.value.length > maxContentSize) {
      Get.snackbar(
        'Content Too Large',
        'Blog content is too large (${(htmlContent.value.length / 1024).toStringAsFixed(1)}KB). Please reduce content size to under 500KB.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
      return false;
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
        return false;
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
        return false;
      }
      
      await editorController.getText().then((content) async {
        htmlContent.value = content;
        
        // Determine document ID once and stick with it
        final String docId = draftId.value.isNotEmpty ? draftId.value : const Uuid().v4();
        
        String? imageURL = imageUrl.value;
        
      // If we have a new image, optimize and upload it
      if (mainImage.value != null) {
        try {
          // Create a loading indicator
          Get.snackbar(
            'Uploading Image',
            'Please wait while we upload your image...',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.blue.withOpacity(0.8),
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
          
          // Use structured path for blog images
          final ref = _storage.ref()
            .child('users')
            .child(currentUser.uid)
            .child('blogs')
            .child(docId)
            .child('main.jpg');
            
          // Set metadata for caching
          final SettableMetadata metadata = SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {'timestamp': DateTime.now().millisecondsSinceEpoch.toString()},
            cacheControl: 'public, max-age=86400',
          );
            
          // Upload with metadata and higher quality setting
          final uploadTask = ref.putFile(mainImage.value!, metadata);
          
          // Listen for progress
          uploadTask.snapshotEvents.listen((event) {
            final progress = (event.bytesTransferred / event.totalBytes) * 100;
            print('📤 DEBUG: Upload is $progress% complete');
          });
          
          final snapshot = await uploadTask;
          imageURL = await snapshot.ref.getDownloadURL();
          
          print('📤 DEBUG: Image uploaded successfully');
        } catch (e) {
          print('❌ DEBUG: Error uploading image: $e');
          // Continue anyway with the previous image URL
        }
      }
      
      // Check content size - Firestore has a 10MB document limit
      if (htmlContent.value.length > 8000000) { // ~8MB safety limit
        print('⚠️ DEBUG: Content too large (${htmlContent.value.length} bytes), truncating to avoid Firestore limits');
        Get.snackbar(
          'Warning',
          'Your post is very large. Some content may be truncated when saving.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        
        // Truncate content to avoid Firestore limits
        // Keep first 4MB and last 4MB with message in between
        const int halfMaxSize = 4000000;
        final String truncatedContent = 
            '${htmlContent.value.substring(0, halfMaxSize)}'
            '<div class="content-truncated-warning" style="text-align:center; padding:20px; margin:20px; '
            'background-color:#fff3cd; color:#856404; border:1px solid #ffeeba; border-radius:4px;">'
            '<strong>Warning:</strong> This post exceeds the maximum size limit. Some content in the middle has been automatically truncated when saving.'
            '</div>'
            '${htmlContent.value.substring(htmlContent.value.length - halfMaxSize)}';
            
        htmlContent.value = truncatedContent;
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
        'isDraft': true,  // Explicitly set isDraft to true for drafts
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
      
      // Debug log the data schema
      print('📝 DEBUG: Saving draft with data: ${draftData.toString().substring(0, 500)}...'); // Truncate log
      print('📝 DEBUG: isDraft field explicitly set to: ${draftData['isDraft']}');
      
      try {
        // Save the draft to user's blogs collection
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('blogs')
            .doc(docId)
            .set(draftData, SetOptions(merge: true));
      } catch (e) {
        if (e.toString().contains('INVALID_ARGUMENT') || e.toString().contains('payload size exceeds')) {
          print('⚠️ DEBUG: Firestore error - content likely too large, retrying with reduced content');
          
          // Further reduce content size
          const int smallerMaxSize = 2000000; // ~2MB
          final String furtherTruncatedContent = 
              '${htmlContent.value.substring(0, smallerMaxSize)}'
              '<div class="content-truncated-warning" style="text-align:center; padding:20px; margin:20px; '
              'background-color:#fff3cd; color:#856404; border:1px solid #ffeeba; border-radius:4px;">'
              '<strong>Warning:</strong> This post significantly exceeds the maximum size limit. A large portion has been automatically truncated when saving.'
              '</div>'
              '${htmlContent.value.substring(htmlContent.value.length - smallerMaxSize)}';
              
          // Update draft data with reduced content
          draftData['content'] = furtherTruncatedContent;
          
          // Try saving again with reduced content
          await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .collection('blogs')
              .doc(docId)
              .set(draftData, SetOptions(merge: true));
              
          // Update the htmlContent value so the editor reflects the change
          htmlContent.value = furtherTruncatedContent;
        } else {
          // If it's not a size-related error, rethrow
          throw e;
        }
      }        print('✅ DEBUG: Draft saved to Firestore with ID: $docId');
        
        // Update the draft ID if it was a new draft
        if (draftId.isEmpty) {
          draftId.value = docId;
          print('✅ DEBUG: Draft ID updated to: $docId');
        }
        
        // Update the image URL
        imageUrl.value = imageURL ?? '';
        
        // Refresh drafts cache
        try {
          print('📝 DEBUG: Refreshing drafts cache after saving draft');
          final blogController = Get.find<BlogController>();
          blogController.refreshDrafts(currentUser.uid);
        } catch (e) {
          print('⚠️ DEBUG: Error refreshing drafts cache: $e');
        }
        
        Get.snackbar(
          'Success',
          'Draft saved successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 1),
        );
        
        // Mark draft as saved
        isDraftSaved.value = true;
        
        return true;
      });
      
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save draft: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return false;
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
    
    // Check content size to prevent SQLite issues
    const int maxContentSize = 500 * 1024; // 500KB limit for content
    if (htmlContent.value.length > maxContentSize) {
      Get.snackbar(
        'Content Too Large',
        'Blog content is too large (${(htmlContent.value.length / 1024).toStringAsFixed(1)}KB). Please reduce content size to under 500KB.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
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
        final ref = _storage.ref()
            .child('users')
            .child(currentUser.uid)
            .child('blogs')
            .child(docId)
            .child('main.jpg');
        final uploadTask = ref.putFile(mainImage.value!);
        final snapshot = await uploadTask;
        imageURL = await snapshot.ref.getDownloadURL();
      }
      
      // Check content size - Firestore has a 10MB document limit
      if (htmlContent.value.length > 8000000) { // ~8MB safety limit
        print('⚠️ DEBUG: Content too large (${htmlContent.value.length} bytes), truncating to avoid Firestore limits');
        Get.snackbar(
          'Warning',
          'Your post is very large. Some content may be truncated when publishing.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        
        // Truncate content to avoid Firestore limits
        // Keep first 4MB and last 4MB with message in between
        const int halfMaxSize = 4000000;
        final String truncatedContent = 
            '${htmlContent.value.substring(0, halfMaxSize)}'
            '<div class="content-truncated-warning" style="text-align:center; padding:20px; margin:20px; '
            'background-color:#fff3cd; color:#856404; border:1px solid #ffeeba; border-radius:4px;">'
            '<strong>Warning:</strong> This post exceeds the maximum size limit. Some content in the middle has been automatically truncated when publishing.'
            '</div>'
            '${htmlContent.value.substring(htmlContent.value.length - halfMaxSize)}';
            
        htmlContent.value = truncatedContent;
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
      
      try {
        // Use transaction to save to both user's collection and global blogs collection
        await _firestore.runTransaction((transaction) async {
          // Save to user's blogs collection
          transaction.set(
            _firestore.collection('users').doc(currentUser.uid).collection('blogs').doc(docId),
            postData,
            SetOptions(merge: true)
          );
          
          // Also save to global blogs collection for easier querying
          transaction.set(
            _firestore.collection('blogs').doc(docId),
            postData,
            SetOptions(merge: true)
          );
        });
      } catch (e) {
        if (e.toString().contains('INVALID_ARGUMENT') || e.toString().contains('payload size exceeds')) {
          print('⚠️ DEBUG: Firestore error - content likely too large, retrying with reduced content');
          
          Get.snackbar(
            'Content Size Issue',
            'Your post is too large to publish as-is. Content will be truncated to fit Firestore limits.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.withOpacity(0.8),
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
          
          // Further reduce content size
          const int smallerMaxSize = 2000000; // ~2MB
          final String furtherTruncatedContent = 
              '${htmlContent.value.substring(0, smallerMaxSize)}'
              '<div class="content-truncated-warning" style="text-align:center; padding:20px; margin:20px; '
              'background-color:#fff3cd; color:#856404; border:1px solid #ffeeba; border-radius:4px;">'
              '<strong>Warning:</strong> This post significantly exceeds the maximum size limit. A large portion has been automatically truncated when publishing.'
              '</div>'
              '${htmlContent.value.substring(htmlContent.value.length - smallerMaxSize)}';
              
          // Update post data with reduced content
          postData['content'] = furtherTruncatedContent;
          
          // Try saving again with reduced content
          await _firestore.runTransaction((transaction) async {
            // Save to user's blogs collection
            transaction.set(
              _firestore.collection('users').doc(currentUser.uid).collection('blogs').doc(docId),
              postData,
              SetOptions(merge: true)
            );
            
            // Also save to global blogs collection for easier querying
            transaction.set(
              _firestore.collection('blogs').doc(docId),
              postData,
              SetOptions(merge: true)
            );
          });
          
          // Update the htmlContent value so the editor reflects the change
          htmlContent.value = furtherTruncatedContent;
        } else {
          // If it's not a size-related error, rethrow
          throw e;
        }
      }        print('🎉 DEBUG: Post published to Firestore with ID: $docId');
        
        // Refresh both drafts and published posts caches
        try {
          print('📝 DEBUG: Refreshing caches after publishing');
          final blogController = Get.find<BlogController>();
          blogController.refreshDrafts(currentUser.uid);
          blogController.refreshPublishedPosts(currentUser.uid);
        } catch (e) {
          print('⚠️ DEBUG: Error refreshing caches: $e');
        }
        
        // Show success message
        Get.snackbar(
          'Success',
          'Post published successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        
        // Navigate to home page after a short delay
        Future.delayed(const Duration(milliseconds: 1500), () {
          // First close the create post page
          Get.back(); 
          
          print('🚀 DEBUG: Navigating to home page after publishing');
          
          // Navigate to home page
          Get.offAllNamed('/home');
        });
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
      
      // Get current user ID
      final currentUser = _authController.userModel.value;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Delete from user's blogs collection in Firestore
      await _firestore.collection('users').doc(currentUser.uid).collection('blogs').doc(draftId.value).delete();
      
      // If published, also delete from global blogs collection
      await _firestore.collection('blogs').doc(draftId.value).get().then((doc) {
        if (doc.exists) {
          _firestore.collection('blogs').doc(draftId.value).delete();
        }
      });
      
      // Delete associated images
      try {
        await _storage.ref()
            .child('users')
            .child(currentUser.uid)
            .child('blogs')
            .child(draftId.value)
            .listAll()
            .then((result) {
              result.items.forEach((itemRef) {
                itemRef.delete();
              });
            });
      } catch (e) {
        print('Error deleting blog images: $e');
      }
      
      // Refresh drafts cache after deletion
      try {
        print('📝 DEBUG: Refreshing drafts cache after deletion');
        final blogController = Get.find<BlogController>();
        blogController.refreshDrafts(currentUser.uid);
      } catch (e) {
        print('⚠️ DEBUG: Error refreshing drafts cache: $e');
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
