import 'package:flutter/material.dart';
import 'package:projectblog/models/blog_model.dart';
import 'package:projectblog/pages/blog/reader_page.dart';

class BlogCard extends StatelessWidget {
  final BlogModel blog;
  const BlogCard({super.key, required this.blog});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BlogReaderPage(blog: blog)),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 20),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (blog.imageURL != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Image.network(
                  blog.imageURL!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox(height: 200, child: Icon(Icons.image_not_supported)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    blog.category.toUpperCase(),
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    blog.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (blog.authorPhotoURL != null)
                        CircleAvatar(
                          radius: 15,
                          backgroundImage: NetworkImage(blog.authorPhotoURL!),
                        ),
                      const SizedBox(width: 8),
                      Text(blog.authorUsername, style: TextStyle(color: Colors.grey.shade700)),
                      const Spacer(),
                      Text(
                        '${blog.readingTimeMinutes} min read',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
