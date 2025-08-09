import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:projectblog/controllers/post_controller.dart';
import 'package:projectblog/pages/blog/post/blog_image_picker.dart';
import 'package:projectblog/pages/blog/post/category_selector.dart';
import 'package:projectblog/pages/blog/post/blog_actions_bar.dart';
import 'package:projectblog/pages/blog/post/notepad.dart';

class CreatePostPage extends StatefulWidget {
  final String? draftId;
  
  const CreatePostPage({super.key, this.draftId});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  late final BlogPostController _controller;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  @override
  void initState() {
    super.initState();
    _controller = Get.put(BlogPostController());
    
    if (widget.draftId != null) {
      // Debug logging
      print('📝 DEBUG: Loading draft with ID: ${widget.draftId}');
      _controller.loadDraft(widget.draftId!);
    } else {
      print('📝 DEBUG: Creating new draft');
    }
  }

  @override
  void dispose() {
    Get.delete<BlogPostController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: theme.appBarTheme.backgroundColor ?? theme.primaryColor, 
      statusBarIconBrightness: theme.brightness == Brightness.light
          ? Brightness.light
          : Brightness.dark,
    ));

    return WillPopScope(
      onWillPop: () async {
        return await _showExitConfirmationDialog(context) ?? false;
      },
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              'Create Post',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () async {
                final shouldExit = await _showExitConfirmationDialog(context);
                if (shouldExit ?? false) {
                  Navigator.of(context).pop();
                }
              },
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: IconButton(
                  onPressed: _controller.isSavingDraft.value || _controller.isPublishing.value
                      ? null
                      : _controller.saveDraft,
                  icon: const Icon(Icons.save, size: 28),
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
            elevation: 4,
            backgroundColor: theme.appBarTheme.backgroundColor,
            foregroundColor: theme.appBarTheme.foregroundColor,
            shadowColor: theme.shadowColor,
          ),
          body: Obx(() {
            if (_controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                child: Column(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image Picker
                        Obx(() => BlogImagePicker(
                              mainImage: _controller.mainImage.value,
                              imageUrl: _controller.imageUrl.value,
                              onImageSelected: _controller.setMainImage,
                              isLoading: _controller.isSavingDraft.value || _controller.isPublishing.value,
                            )),

                        // Title Field
                        TextFormField(
                          controller: _controller.titleController,
                          decoration: InputDecoration(
                            labelText: 'Title',
                            hintText: 'Enter post title',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: null,
                          keyboardType: TextInputType.text,
                          textCapitalization: TextCapitalization.sentences,
                          enabled: !_controller.isSavingDraft.value && !_controller.isPublishing.value,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 10),

                        // Category Selector
                        Obx(() => CategorySelector(
                              selectedCategory: _controller.selectedCategory.value,
                              onCategoryChanged: _controller.setCategory,
                            )),

                        const SizedBox(height: 10),

                        // HTML Editor
                        HtmlEditorWidget(
                          controller: _controller.editorController,
                          hint: "Start writing your post...",
                            minHeight: MediaQuery.of(context).size.height * 0.7,
                          onChanged: (content) {
                            if (content != null) {
                              _controller.htmlContent.value = content;
                            }
                          },
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),

                    Obx(() => BlogActionsBar(
                          isSavingDraft: _controller.isSavingDraft.value,
                          isPublishing: _controller.isPublishing.value,
                          isDraftExists: _controller.draftId.value.isNotEmpty,
                          onSaveDraft: _controller.saveDraft,
                          onPublish: _controller.publishPost,
                          onDelete: _controller.deleteDraft,
                        )),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Future<bool?> _showExitConfirmationDialog(BuildContext context) {
    // Check if there's unsaved content to show dialog
    final hasContent = _controller.titleController.text.isNotEmpty || 
                      _controller.htmlContent.value.isNotEmpty;
    
    if (!hasContent) {
      // If no content, just exit without saving
      return Future.value(true);
    }
    
    // Store navigator reference to avoid deactivated widget issues
    final navigator = Navigator.of(context);
    
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Save Draft?'),
          content: const Text('Do you want to save the draft before exiting?'),
          actions: [
            TextButton(
              onPressed: () {
                // Exit without saving - use the dialog's context
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Exit Without Saving'),
            ),
            TextButton(
              onPressed: () {
                // Capture the navigator context before doing the async operation
                final localNavigator = Navigator.of(dialogContext);
                
                // Show progress indicator
                showDialog(
                  context: dialogContext,
                  barrierDismissible: false,
                  builder: (loadingContext) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
                
                // Save and exit
                _controller.saveDraft().then((_) {
                  // First pop the loading dialog
                  if (navigator.mounted) {
                    try {
                      localNavigator.pop();
                      // Then pop the confirmation dialog with result
                      localNavigator.pop(true);
                    } catch (e) {
                      print('Navigation error (non-critical): $e');
                    }
                  }
                }).catchError((e) {
                  // On error, pop loading dialog and show error
                  if (navigator.mounted) {
                    try {
                      localNavigator.pop();
                      localNavigator.pop(false);
                    } catch (e) {
                      print('Navigation error (non-critical): $e');
                    }
                  }
                });
              },
              child: const Text('Save & Exit'),
            ),
            TextButton(
              onPressed: () {
                // Cancel and return to editing - use the dialog's context
                Navigator.of(dialogContext).pop(false);
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
              ),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
