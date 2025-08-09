import 'package:flutter/material.dart';
import 'package:projectblog/models/blog_post_model.dart';
import 'package:projectblog/pages/blog/reader_page.dart';
import 'package:projectblog/widgets/cached_network_image.dart';

class BlogCard extends StatelessWidget {
  final BlogPostModel blog;
  const BlogCard({super.key, required this.blog});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BlogReaderPage(blog: blog)),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        elevation: 3,
        color: theme.colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              blog.imageURL != null
                  ? ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                      child: CachedImage(
                        imageUrl: blog.imageURL,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        maxCacheHeight: 400,
                        maxCacheWidth: 600,
                      ),
                    )
                  : const SizedBox.shrink(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      blog.category.toUpperCase(),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      blog.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (blog.authorPhotoURL != null)
                          CachedAvatar(
                            imageUrl: blog.authorPhotoURL,
                            radius: 15,
                            name: blog.authorUsername,
                          ),
                        const SizedBox(width: 8),
                        Text(
                          blog.authorUsername,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${blog.readTime.toInt()} min read',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
