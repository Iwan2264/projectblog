// lib/pages/home/widget/draft.dart

import 'package:flutter/material.dart';

class DraftsGrid extends StatelessWidget {
  const DraftsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    // Replace this with your UI for drafts when you have data
    return const Center(
      child: Text(
        "You have no saved drafts.",
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
}