import 'dart:io';
import 'package:flutter/material.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:image_picker/image_picker.dart';
// Ensure this path points to your updated HtmlEditorWidget file
import 'package:projectblog/pages/blog/widgets/notepad.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({Key? key}) : super(key: key);

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _titleController = TextEditingController();
  final HtmlEditorController _editorController = HtmlEditorController();
  File? _mainImage;
  bool _isSavingDraft = false;
  bool _isPublishing = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (pickedFile != null) {
      setState(() {
        _mainImage = File(pickedFile.path);
      });
    }
  }

  Future<bool> _canPop() async {
    return true; // Implement unsaved changes logic if needed
  }

  void _onContentChanged([String? _]) {
    // Handle auto-save, etc.
  }
  
  void _autoSaveDraft() {}
  void _deleteDraft() {}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          title: Text('Create Post', style: TextStyle(color: theme.colorScheme.primary)),
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          actions: [
            if (_isSavingDraft)
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(child: Text("Saving...", style: TextStyle(color: theme.colorScheme.secondary))),
              )
          ],
          iconTheme: IconThemeData(color: theme.colorScheme.primary),
        ),
        // IMPORTANT: The main SingleChildScrollView is removed.
        // The body is now a Column to control layout directly.
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0), // Padding adjusted for no scroll
            child: Column(
              children: [
                // Post Title (non-scrollable part)
                TextField(
                  controller: _titleController,
                  style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 20),
                  decoration: InputDecoration(
                    labelText: 'Post Title',
                    labelStyle: TextStyle(color: theme.colorScheme.primary),
                    border: const OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.colorScheme.primary)),
                  ),
                ),
                const SizedBox(height: 16),

                // Main Image (non-scrollable part)
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _mainImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(_mainImage!, fit: BoxFit.cover, width: double.infinity),
                          )
                        : Center(
                            child: Icon(Icons.add_photo_alternate, size: 48, color: theme.colorScheme.primary.withOpacity(0.3)),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // IMPORTANT: The editor is wrapped in an Expanded widget.
                // This makes it take up all remaining vertical space, allowing its
                // own content to scroll while the title and image fields above remain fixed.
                Expanded(
                  child: HtmlEditorWidget(
                    controller: _editorController,
                    onChanged: _onContentChanged,
                    hint: "Start writing your post...",
                  ),
                ),
              ],
            ),
          ),
        ),
        // The bottom navigation bar remains the same
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Delete'),
                  onPressed: _deleteDraft,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.publish),
                  label: const Text('Publish'),
                  onPressed: _isPublishing ? null : () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondary,
                    foregroundColor: theme.colorScheme.onSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}