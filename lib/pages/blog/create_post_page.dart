import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:html_editor_enhanced/html_editor.dart';
class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {

  final TextEditingController _titleController = TextEditingController();
  final HtmlEditorController _editorController = HtmlEditorController();
  File? _mainImage;

  Timer? _debounceTimer;
  bool _isSavingDraft = false;
  bool _isPublishing = false;
  String? _draftDocId;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _titleController.dispose();
    super.dispose();
  }
  void _onContentChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), _autoSaveDraft);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile != null) {
      setState(() => _mainImage = File(xfile.path));
      _onContentChanged();
    }
  }

  Future<void> _autoSaveDraft() async {
    final htmlContent = await _editorController.getText();
    if (_titleController.text.trim().isEmpty &&
        (htmlContent.trim().isEmpty || htmlContent.trim() == "<p></p>")) {
      return;
    }

    setState(() => _isSavingDraft = true);
    try {
      final draftData = {
        'title': _titleController.text,
        'content': htmlContent,
        'timestamp': FieldValue.serverTimestamp(),
      };

      if (_draftDocId == null) {
        final docRef = await FirebaseFirestore.instance.collection('drafts').add(draftData);
        _draftDocId = docRef.id;
      } else {
        await FirebaseFirestore.instance.collection('drafts').doc(_draftDocId).update(draftData);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isSavingDraft = false);
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final ref = FirebaseStorage.instance.ref('post_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
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

      final htmlContent = await _editorController.getText();
      final postData = {
        'title': _titleController.text,
        'content': htmlContent,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'scheduled': scheduled,
      };
      await FirebaseFirestore.instance.collection('posts').add(postData);

      // Delete the draft after successful publishing.
      if (_draftDocId != null) {
        await FirebaseFirestore.instance.collection('drafts').doc(_draftDocId).delete();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(scheduled ? 'Post scheduled!' : 'Post published!')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to ${scheduled ? 'schedule' : 'publish'}: $e')));
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }
  
  Future<void> _deleteDraft() async {
    if (_draftDocId != null) {
      await FirebaseFirestore.instance.collection('drafts').doc(_draftDocId).delete();
      _draftDocId = null;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Draft deleted')));
      }
    }
    setState(() {
      _titleController.clear();
      _editorController.clear();
      _mainImage = null;
    });
  }

  Future<bool> _canPop() async {
    final htmlContent = await _editorController.getText();
    if (_titleController.text.isNotEmpty || htmlContent.trim().isNotEmpty) {
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
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final bool shouldPop = await _canPop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Post'),
          actions: [
            // Show a "Saving..." indicator in the AppBar during auto-save.
            if (_isSavingDraft)
              const Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: Center(child: Text("Saving...")),
              )
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Input field for the post title.
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Post Title', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                
                // Area for selecting and displaying the main image.
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                    child: _mainImage != null
                        ? Image.file(_mainImage!, fit: BoxFit.cover)
                        : const Center(child: Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey)),
                  ),
                ),
                const SizedBox(height: 16),

                // This is the rich text editor from the html_editor_enhanced package.
                HtmlEditor(
                  controller: _editorController,
                  htmlEditorOptions: const HtmlEditorOptions(
                    hint: "Start writing your post...",
                    shouldEnsureVisible: true,
                  ),
                  htmlToolbarOptions: const HtmlToolbarOptions(
                    toolbarType: ToolbarType.nativeExpandable,
                    defaultToolbarButtons: [
                      FontButtons(),
                      ColorButtons(),
                      ListButtons(),
                      ParagraphButtons(),
                      InsertButtons(
                        audio: false,
                        table: true,
                        hr: true,
                        otherFile: false,
                      ),
                      OtherButtons(
                        fullscreen: true,
                        codeview: true,
                        help: false,
                      ),
                    ],
                  ),
                  otherOptions: const OtherOptions(height: 240),
                  callbacks: Callbacks(
                    onChangeContent: (String? content) {
                      _onContentChanged();
                    }
                  ),
                ),
                
                const SizedBox(height: 16),
                const Text(
                  'For more advanced editing, see the html_editor_enhanced documentation.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save Draft'),
                  onPressed: _isSavingDraft || _isPublishing ? null : _autoSaveDraft,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Delete'),
                  onPressed: _deleteDraft,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: const Text('Post Now'),
                  onPressed: _isPublishing ? null : () => _publishPost(scheduled: false),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.schedule),
                  label: const Text('Schedule'),
                  onPressed: _isPublishing ? null : () => _publishPost(scheduled: true),
                ),
                if (_isPublishing)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: LinearProgressIndicator(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}