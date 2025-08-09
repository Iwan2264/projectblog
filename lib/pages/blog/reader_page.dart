import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projectblog/models/blog_post_model.dart';
import 'package:projectblog/widgets/cached_network_image.dart';

class BlogReaderPage extends StatelessWidget {
  final BlogPostModel blog;
  const BlogReaderPage({super.key, required this.blog});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                blog.title,
                style: const TextStyle(fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (blog.imageURL != null)
                    CachedImage(
                      imageUrl: blog.imageURL!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(onPressed: () { /* Share logic */ }, icon: const Icon(Icons.share)),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (blog.authorPhotoURL != null)
                        CachedAvatar(
                          imageUrl: blog.authorPhotoURL!,
                          radius: 22,
                          name: blog.authorUsername,
                        ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            blog.authorUsername,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Published on ${DateFormat.yMMMd().format(blog.publishedAt ?? blog.createdAt)}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    blog.content, // For actual blog content
                    style: const TextStyle(fontSize: 16, height: 1.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.favorite_border),
                    onPressed: () { /* Handle like */ },
                  ),
                  Text(blog.likesCount.toString()),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.comment_outlined),
                    onPressed: () { /* Handle comment */ },
                  ),
                  Text(blog.commentsCount.toString()),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_border),
                onPressed: () { /* Handle bookmark */ },
              ),
            ],
          ),
        ),
      ),
    );
  }
}