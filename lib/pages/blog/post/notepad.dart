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
        ? (minHeight * 0.7).clamp(150.0, minHeight)
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
            final double defaultHeight = MediaQuery.of(context).size.height * 0.68;
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
                        initialText: "<style>img {max-width: 50%; height: auto; display: block; margin: 0 auto;}</style>", // Restrict image size to 50% and center align
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