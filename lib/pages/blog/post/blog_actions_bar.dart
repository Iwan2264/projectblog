import 'package:flutter/material.dart';

class BlogActionsBar extends StatelessWidget {
  final bool isSavingDraft;
  final bool isPublishing;
  final bool isDraftExists;
  final Function() onSaveDraft;
  final Function() onPublish;
  final Function() onDelete;

  const BlogActionsBar({
    super.key,
    required this.isSavingDraft,
    required this.isPublishing,
    required this.isDraftExists,
    required this.onSaveDraft,
    required this.onPublish,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Save Draft Button
          Expanded(
            child: ElevatedButton.icon(
              icon: isSavingDraft
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(isSavingDraft ? 'Saving...' : 'Save Draft'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: isSavingDraft || isPublishing ? null : onSaveDraft,
            ),
          ),
          const SizedBox(width: 8),
          
          // Delete Button (only shown if draft exists)
          if (isDraftExists)
            ElevatedButton.icon(
              icon: const Icon(Icons.delete),
              label: const Text('Delete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: onDelete,
            ),
          if (isDraftExists) 
            const SizedBox(width: 8),
          
          // Publish Button
          Expanded(
            child: ElevatedButton.icon(
              icon: isPublishing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.publish),
              label: Text(isPublishing ? 'Publishing...' : 'Publish'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: isPublishing ? null : onPublish,
            ),
          ),
        ],
      ),
    );
  }
}
