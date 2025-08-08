import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:projectblog/controllers/post_controller.dart';
import 'package:projectblog/pages/blog/post/blog_image_picker.dart';
import 'package:projectblog/pages/blog/post/category_selector.dart';
import 'package:projectblog/pages/blog/post/blog_actions_bar.dart';
import 'package:projectblog/pages/blog/post/notepad.dart';

class CreatePostPage extends StatefulWidget {
  final String? draftId;
  
  const CreatePostPage({Key? key, this.draftId}) : super(key: key);

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
      _controller.loadDraft(widget.draftId!);
    }
  }

  @override
  void dispose() {
    Get.delete<BlogPostController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        elevation: 0,
      ),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return Form(
          key: _formKey,
          child: Column(
            children: [
              // Main content scrollable area
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Picker
                      Obx(() => BlogImagePicker(
                        mainImage: _controller.mainImage.value,
                        imageUrl: _controller.imageUrl.value,
                        onImageSelected: _controller.setMainImage,
                        isLoading: _controller.isSavingDraft.value || _controller.isPublishing.value,
                      )),
                      
                      const SizedBox(height: 16),
                      
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
                        style: const TextStyle(
                          fontSize: 18,
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
                      
                      const SizedBox(height: 16),
                      
                      // Category Selector
                      Obx(() => CategorySelector(
                        selectedCategory: _controller.selectedCategory.value,
                        onCategoryChanged: _controller.setCategory,
                      )),
                      
                      const SizedBox(height: 24),
                      
                      // HTML Editor
                      HtmlEditorWidget(
                        controller: _controller.editorController,
                        hint: "Start writing your post...",
                        minHeight: MediaQuery.of(context).size.height * 0.4,
                        onChanged: (content) {
                          if (content != null) {
                            _controller.htmlContent.value = content;
                          }
                        },
                      ),
                      
                      // Add some bottom padding for scrolling
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
              
              // Fixed bottom action bar
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
        );
      }),
    );
  }
}
