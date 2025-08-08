import 'package:cloud_firestore/cloud_firestore.dart';

class BlogPostModel {
  final String id;
  final String authorId;
  final String authorUsername;
  final String? authorPhotoURL;
  final String? authorName;
  final String title;
  final String content;
  final String? imageURL;
  final String category;
  final List<String> tags;
  final bool isDraft;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;
  final int likesCount;
  final int commentsCount;
  final int viewsCount;
  final bool featured;
  final List<String> likedBy;
  final double readTime; // estimated reading time in minutes

  BlogPostModel({
    required this.id,
    required this.authorId,
    required this.authorUsername,
    this.authorPhotoURL,
    this.authorName,
    required this.title,
    required this.content,
    this.imageURL,
    required this.category,
    this.tags = const [],
    this.isDraft = false,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.viewsCount = 0,
    this.featured = false,
    this.likedBy = const [],
    this.readTime = 0.0,
  });

  factory BlogPostModel.fromMap(String id, Map<String, dynamic> map) {
    return BlogPostModel(
      id: id,
      authorId: map['authorId'] ?? '',
      authorUsername: map['authorUsername'] ?? '',
      authorPhotoURL: map['authorPhotoURL'],
      authorName: map['authorName'],
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      imageURL: map['imageURL'],
      category: map['category'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      isDraft: map['isDraft'] ?? false,
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate() 
          : DateTime.parse(map['createdAt'].toString()),
      updatedAt: map['updatedAt'] is Timestamp 
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(map['updatedAt'].toString()),
      publishedAt: map['publishedAt'] != null
          ? (map['publishedAt'] is Timestamp 
              ? (map['publishedAt'] as Timestamp).toDate() 
              : DateTime.parse(map['publishedAt'].toString()))
          : null,
      likesCount: map['likesCount'] ?? 0,
      commentsCount: map['commentsCount'] ?? 0,
      viewsCount: map['viewsCount'] ?? 0,
      featured: map['featured'] ?? false,
      likedBy: List<String>.from(map['likedBy'] ?? []),
      readTime: (map['readTime'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorUsername': authorUsername,
      'authorPhotoURL': authorPhotoURL,
      'authorName': authorName,
      'title': title,
      'content': content,
      'imageURL': imageURL,
      'category': category,
      'tags': tags,
      'isDraft': isDraft,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'publishedAt': publishedAt,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'viewsCount': viewsCount,
      'featured': featured,
      'likedBy': likedBy,
      'readTime': readTime,
    };
  }

  BlogPostModel copyWith({
    String? id,
    String? authorId,
    String? authorUsername,
    String? authorPhotoURL,
    String? authorName,
    String? title,
    String? content,
    String? imageURL,
    String? category,
    List<String>? tags,
    bool? isDraft,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
    int? likesCount,
    int? commentsCount,
    int? viewsCount,
    bool? featured,
    List<String>? likedBy,
    double? readTime,
  }) {
    return BlogPostModel(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorUsername: authorUsername ?? this.authorUsername,
      authorPhotoURL: authorPhotoURL ?? this.authorPhotoURL,
      authorName: authorName ?? this.authorName,
      title: title ?? this.title,
      content: content ?? this.content,
      imageURL: imageURL ?? this.imageURL,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      isDraft: isDraft ?? this.isDraft,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      viewsCount: viewsCount ?? this.viewsCount,
      featured: featured ?? this.featured,
      likedBy: likedBy ?? this.likedBy,
      readTime: readTime ?? this.readTime,
    );
  }

  // Helper method to calculate estimated reading time
  static double calculateReadTime(String content) {
    // Remove HTML tags and count words
    String plainText = content.replaceAll(RegExp(r'<[^>]*>'), '');
    int wordCount = plainText.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
    
    // Average reading speed is 200-250 words per minute
    double readTime = wordCount / 225.0;
    return readTime < 1 ? 1.0 : double.parse(readTime.toStringAsFixed(1));
  }
}
