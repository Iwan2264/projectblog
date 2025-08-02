// lib/pages/blog/all_published_page.dart

import 'package:flutter/material.dart';

class AllPublishedBlogsPage extends StatelessWidget {
  const AllPublishedBlogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('All Published Blogs'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: 25, 
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemBuilder: (context, index) {
          return Card(
            child: Center(child: Text("Blog ${index + 1}")),
          );
        },
      ),
    );
  }
}