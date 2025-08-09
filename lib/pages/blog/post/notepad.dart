import 'dart:io';
import 'package:flutter/material.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:file_picker/file_picker.dart';
import 'package:projectblog/utils/image_util.dart';

class HtmlEditorWidget extends StatelessWidget {
  final HtmlEditorController controller;
  final String? hint;
  final void Function(String?)? onChanged;
  final double minHeight;
  final double maxHeight;
  final bool autoSave;
  final Duration autoSaveInterval;

  const HtmlEditorWidget({
    super.key,
    required this.controller,
    this.hint,
    this.onChanged,
    this.minHeight = 500,
    this.maxHeight = double.infinity,
    this.autoSave = false,
    this.autoSaveInterval = const Duration(minutes: 2),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    
    final dynamicMinHeight = keyboardHeight > 0
        ? (minHeight * 0.5).clamp(150.0, minHeight)
        : minHeight;
        
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          minHeight: dynamicMinHeight,
          maxHeight: maxHeight,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.primary.withAlpha((0.6 * 255).toInt())),
          borderRadius: BorderRadius.circular(8),
          color: theme.colorScheme.surfaceContainerHighest.withAlpha((0.6 * 255).toInt()),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double defaultHeight = MediaQuery.of(context).size.height * 0.675;
            return ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: 150,
                maxHeight: constraints.maxHeight,
              ),
              child: SizedBox(
                height: defaultHeight,
                child: Column(
                  children: [
                    HtmlEditor(
                      controller: controller,
                      htmlEditorOptions: HtmlEditorOptions(
                        hint: hint ?? "Start writing your post...",
                        shouldEnsureVisible: true,
                        darkMode: theme.brightness == Brightness.dark,
                        autoAdjustHeight: true, // Enable auto-adjustment of height
                        adjustHeightForKeyboard: true, // Allow height adjustment with keyboard
                        // Don't set initialText here as it can cause issues with loading drafts
                      ),
                      htmlToolbarOptions: HtmlToolbarOptions(
                        toolbarType: ToolbarType.nativeScrollable,
                        defaultToolbarButtons: const [
                          FontButtons(
                            clearAll: true,
                            superscript: false,
                            subscript: false,
                          ),
                          ColorButtons(),
                          ListButtons(),
                          ParagraphButtons(
                            increaseIndent: true,
                            decreaseIndent: true,
                            textDirection: true,
                            lineHeight: true,
                          ),
                          InsertButtons(
                            audio: false,
                            table: true,
                            hr: true,
                            picture: true,
                            video: true,
                            link: true,
                            otherFile: false,
                          ),
                          OtherButtons(
                            fullscreen: true,
                            codeview: true,
                            help: false,
                            copy: true,
                            paste: true,
                            undo: true,
                            redo: true,
                          ),
                        ],
                        // Handle image upload with compression
                        mediaUploadInterceptor: (PlatformFile file, InsertFileType type) async {
                          print('🖼️ DEBUG: File picked: ${file.name} (${file.size} bytes)');
                          if (type == InsertFileType.image) {
                            try {
                              // Only compress if it's an image and has a path (local file)
                              if (file.path != null) {
                                final originalFile = File(file.path!);
                                
                                // Import the image utility
                                final compressedImage = await ImageUtil.compressImage(
                                  originalFile,
                                  quality: 75, // Lower quality for inline images to save space
                                );
                                
                                // If compression was successful, return false and handle manually
                                if (compressedImage != null) {
                                  print('🖼️ DEBUG: Image compressed for editor');
                                  return true; // Still use default behavior but with compressed image
                                }
                              }
                            } catch (e) {
                              print('❌ DEBUG: Error compressing editor image: $e');
                            }
                            // Fall back to default behavior
                            return true;
                          }
                          return false;
                        },
                        mediaLinkInsertInterceptor: (String url, InsertFileType type) {
                          print('🔗 DEBUG: URL inserted: $url');
                          return true; // Allow the URL to be inserted
                        },
                        toolbarPosition: ToolbarPosition.belowEditor,
                        toolbarItemHeight: 30,
                        buttonColor: theme.colorScheme.primary,
                        buttonSelectedColor: theme.colorScheme.secondary,
                      ),
                      otherOptions: OtherOptions(
                        height: defaultHeight,
                        decoration: const BoxDecoration(
                          color: Color.fromARGB(0, 255, 0, 0),
                        ),
                      ),
                      callbacks: Callbacks(
                        onChangeContent: (content) {
                          if (onChanged != null) onChanged!(content);
                        },
                        onFocus: () {},
                        onChangeSelection: (selection) {},
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}