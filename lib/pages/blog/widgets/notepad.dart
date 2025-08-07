import 'package:flutter/material.dart';
import 'package:html_editor_enhanced/html_editor.dart';

class HtmlEditorWidget extends StatelessWidget {
  final HtmlEditorController controller;
  final String? hint;
  final void Function(String?)? onChanged;
  final double minHeight;
  final double maxHeight;

  const HtmlEditorWidget({
    super.key,
    required this.controller,
    this.hint,
    this.onChanged,
    this.minHeight = 600,
    this.maxHeight = double.infinity,
  });

  static const String _mobileImgCss = """
    <style>
      img {max-width: 98vw !important; height: auto !important; display: block; margin-left: auto; margin-right: auto;}
      body { color: inherit !important; }
    </style>
  """;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          minHeight: minHeight,
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
          otherOptions: OtherOptions(
            height: minHeight,
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
          ),
          callbacks: Callbacks(
            onChangeContent: (content) {
              if (onChanged != null) onChanged!(content);
            },
          ),
        ),
      ),
    );
  }
}