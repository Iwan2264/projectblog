import 'package:flutter/material.dart';
import 'dart:math'; // Used to ensure we don't load more than available

class PublishedBlogsGrid extends StatefulWidget {
  const PublishedBlogsGrid({super.key});

  @override
  State<PublishedBlogsGrid> createState() => _PublishedBlogsGridState();
}

class _PublishedBlogsGridState extends State<PublishedBlogsGrid> {
  final int _totalBlogs = 25; 
  int _displayCount = 6;

  void _loadMore() {
    setState(() {
      _displayCount = min(_totalBlogs, _displayCount + 6);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _displayCount,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemBuilder: (context, index) {
            return Card(
              child: Center(child: Text("Published Blog ${index + 1}")),
            );
          },
        ),
        
        if (_displayCount < _totalBlogs)
          Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: OutlinedButton(
              onPressed: _loadMore,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                side: BorderSide(color: theme.colorScheme.primary),
              ),
              child: const Text('Load More'),
            ),
          ),
      ],
    );
  }
}