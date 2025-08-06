import 'package:flutter/material.dart';
import 'package:html_editor_enhanced/html_editor.dart';

/// Notepad widget using html_editor_enhanced
class NotepadWidget extends StatefulWidget {
  final HtmlEditorController controller;
  const NotepadWidget({Key? key, required this.controller}) : super(key: key);

  @override
  State<NotepadWidget> createState() => _NotepadWidgetState();
}

class _NotepadWidgetState extends State<NotepadWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HtmlEditor(
          controller: widget.controller,
          htmlEditorOptions: HtmlEditorOptions(
            hint: "Start writing your post...",
            shouldEnsureVisible: true,
          ),
          htmlToolbarOptions: HtmlToolbarOptions(
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
          otherOptions: OtherOptions(height: 240),
        ),
        const SizedBox(height: 16),
        const Text(
          'For more advanced editing, see the html_editor_enhanced documentation.',
          style: TextStyle(color: Colors.grey, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}