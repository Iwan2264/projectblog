import 'package:flutter/material.dart';
import 'package:projectblog/models/blog_model.dart';
import 'package:projectblog/pages/blog/category.dart';
import 'package:projectblog/pages/blog/readerpage.dart';

// Example dummy data using your BlogModel (replace this with Firestore fetch in real usage)
final List<BlogModel> dummyBlogs = [
  BlogModel(
    id: '1',
    authorId: 'user1',
    authorUsername: 'Jane Doe',
    authorPhotoURL: 'https://i.pravatar.cc/150?img=5',
    title: 'The Ultimate Guide to Flutter Performance',
    content: 'Flutter is a powerful cross-platform toolkit...',
    imageURL: 'https://placehold.co/600x400/7E57C2/FFFFFF/png?text=Flutter',
    tags: ['Flutter', 'Performance'],
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    likesCount: 102,
    commentsCount: 10,
    viewsCount: 900,
    isPublished: true,
    category: 'Technology',
  ),
  // Add more BlogModel instances as needed...
];

class BlogHomePage extends StatelessWidget {
  const BlogHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Blogs'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CategoriesSection(),
            const SizedBox(height: 16),
            TrendingBlogsSection(blogs: dummyBlogs),
          ],
        ),
      ),
    );
  }
}

class CategoriesSection extends StatelessWidget {
  const CategoriesSection({super.key});

  final List<String> categories = const [
    'Technology', 'Health & Wellness', 'Finance & Investing', 'Travel',
    'Food & Recipes', 'Lifestyle & Fashion', 'Business & Marketing', 'Education',
    'Arts & Culture', 'Science', 'Personal Growth', 'Gaming'
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Text(
            'Categories',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 45,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryBlogsPage(categoryName: categories[index]),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    categories[index],
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class TrendingBlogsSection extends StatelessWidget {
  final List<BlogModel> blogs;
  const TrendingBlogsSection({super.key, required this.blogs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trending Blogs',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            itemCount: blogs.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return BlogCard(blog: blogs[index]);
            },
          )
        ],
      ),
    );
  }
}

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