import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _titleController = TextEditingController();
  final QuillController _quillController = QuillController.basic();
  File? _mainImage;

  Timer? _debounceTimer;
  bool _isSavingDraft = false;
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onContentChanged);
    _quillController.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _titleController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), _saveDraft);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile != null) {
      setState(() {
        _mainImage = File(xfile.path);
      });
      _onContentChanged();
    }
  }

  Future<void> _saveDraft() async {
    setState(() => _isSavingDraft = true);
    try {
      final contentJson = _quillController.document.toDelta().toJson();
      final draftData = {
        'title': _titleController.text,
        'content': contentJson,
        'timestamp': FieldValue.serverTimestamp(),
      };
      await FirebaseFirestore.instance.collection('drafts').add(draftData);
    } catch (_) {
      // Optional error handling
    } finally {
      setState(() => _isSavingDraft = false);
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final ref = FirebaseStorage.instance
          .ref('post_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  Future<void> _publishPost({bool scheduled = false}) async {
    setState(() => _isPublishing = true);
    try {
      String? imageUrl;
      if (_mainImage != null) {
        imageUrl = await _uploadImage(_mainImage!);
      }
      final contentJson = _quillController.document.toDelta().toJson();
      final postData = {
        'title': _titleController.text,
        'content': contentJson,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'scheduled': scheduled,
      };
      await FirebaseFirestore.instance.collection('posts').add(postData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(scheduled ? 'Post scheduled!' : 'Post published!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to ${scheduled ? 'schedule' : 'publish'}: $e')),
        );
      }
    } finally {
      setState(() => _isPublishing = false);
    }
  }

  Future<bool> _onWillPop() async {
    if (_titleController.text.isNotEmpty || _quillController.document.length > 0) {
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard changes?'),
          content: const Text('You have unsaved changes. Are you sure you want to exit?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Exit')),
          ],
        ),
      );
      return shouldExit ?? false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(title: const Text('Create Post')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Post Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _mainImage != null
                      ? Image.file(_mainImage!, fit: BoxFit.cover)
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Tap to choose main image'),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              QuillSimpleToolbar(controller: _quillController),

              const SizedBox(height: 8),
              Container(
                height: 240,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: QuillEditor.basic(
                  controller: _quillController,
                  ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.send),
                      label: _isPublishing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Post Now'),
                      onPressed: _isPublishing ? null : () => _publishPost(scheduled: false),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.schedule),
                      label: _isPublishing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Schedule'),
                      onPressed: _isPublishing ? null : () => _publishPost(scheduled: true),
                    ),
                  ),
                ],
              ),
              if (_isSavingDraft)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Saving draft...'),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
