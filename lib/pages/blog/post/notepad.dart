import 'package:flutter/material.dart';
import 'package:html_editor_enhanced/html_editor.dart';

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
    this.minHeight = 500, // Reduced minimum height
    this.maxHeight = double.infinity,
    this.autoSave = false,
    this.autoSaveInterval = const Duration(minutes: 2),
  });

  static const String _mobileImgCss = """
    <style>
      img {max-width: 98vw !important; height: auto !important; display: block; margin-left: auto; margin-right: auto;}
      body { color: inherit !important; font-family: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif; }
      h1, h2, h3, h4, h5, h6 { margin-top: 1em; margin-bottom: 0.5em; }
      p { margin-bottom: 0.8em; line-height: 1.6; }
      blockquote { border-left: 4px solid #ccc; margin-left: 0; padding-left: 16px; }
    </style>
  """;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    
    // Calculate dynamic height based on available space
    final dynamicMinHeight = keyboardHeight > 0
        ? (minHeight * 0.7).clamp(150.0, minHeight) // Smaller when keyboard is showing
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
        child: HtmlEditor(
          controller: controller,
          htmlEditorOptions: HtmlEditorOptions(
            hint: hint ?? "Start writing your post...",
            shouldEnsureVisible: true,
            darkMode: theme.brightness == Brightness.dark,
            autoAdjustHeight: true,
            initialText: _mobileImgCss,
            // Better text handling
            adjustHeightForKeyboard: true,
          ),
          htmlToolbarOptions: HtmlToolbarOptions(
            toolbarType: ToolbarType.nativeExpandable,
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
            // Customize toolbar styling
            toolbarPosition: ToolbarPosition.belowEditor,
            toolbarItemHeight: 36,
            buttonColor: theme.colorScheme.primary,
            buttonSelectedColor: theme.colorScheme.secondary,
          ),
          otherOptions: OtherOptions(
            height: dynamicMinHeight, // Use the dynamic height
            // Make the editor expand to fill available space
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
          ),
          callbacks: Callbacks(
            onChangeContent: (content) {
              if (onChanged != null) onChanged!(content);
            },
            // Improve focus handling
            onFocus: () {
              // Add focus behavior if needed
            },
            // Add auto-save logic
            onChangeSelection: (selection) {
              // Could be used for highlighting features
            },
          ),
        ),
      ),
    );
  }
}