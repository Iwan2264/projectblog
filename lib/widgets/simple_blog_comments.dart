import 'package:flutter/material.dart';
import '../models/blog_model.dart';

/// A simple widget that integrates with Disqus for comments
/// Works on both web and mobile platforms
class SimpleBlogComments extends StatelessWidget {
  final BlogModel blog;
  final String baseUrl; // Your website base URL

  const SimpleBlogComments({
    Key? key,
    required this.blog,
    required this.baseUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Comments & Discussion',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildCommentsPlaceholder(context),
        ],
      ),
    );
  }

  Widget _buildCommentsPlaceholder(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.comment, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Comments section coming soon!',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Blog: ${blog.title}',
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
