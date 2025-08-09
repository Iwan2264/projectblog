// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';

class BlogModel {
  // Helper method to safely parse DateTime from various formats
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    
    try {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is DateTime) {
        return value;
      } else if (value is String) {
        // Try standard ISO format first
        try {
          return DateTime.parse(value);
        } catch (parseError) {
          // Try common regional formats if standard parsing fails
          try {
            // Check for MM/DD/YYYY format (US)
            if (value.contains('/')) {
              List<String> parts = value.split('/');
              if (parts.length == 3) {
                return DateTime(
                  int.parse(parts[2]), // year
                  int.parse(parts[0]), // month
                  int.parse(parts[1]), // day
                );
              }
            }
            // Check for DD-MM-YYYY format (UK/India/many countries)
            else if (value.contains('-')) {
              List<String> parts = value.split('-');
              if (parts.length == 3) {
                return DateTime(
                  int.parse(parts[2]), // year
                  int.parse(parts[1]), // month
                  int.parse(parts[0]), // day
                );
              }
            }
            rethrow; // If none of our custom formats matched
          } catch (e) {
            print('Error parsing date with custom formats: $e for value: $value');
            rethrow;
          }
        }
      }
    } catch (e) {
      print('Error parsing date in BlogModel: $e for value: $value');
    }
    
    return null;
  }
  final String id;
  final String authorId;
  final String authorUsername;
  final String? authorPhotoURL;
  final String title;
  final String content;
  final String? imageURL;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likesCount;
  final int commentsCount;
  final int viewsCount;
  final bool isPublished;
  final String category;

  BlogModel({
    required this.id,
    required this.authorId,
    required this.authorUsername,
    this.authorPhotoURL,
    required this.title,
    required this.content,
    this.imageURL,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.viewsCount = 0,
    this.isPublished = true,
    this.category = 'General',
  });

  // Create from Firestore document
  factory BlogModel.fromMap(Map<String, dynamic> map, String documentId) {
    return BlogModel(
      id: documentId,
      authorId: map['authorId'] ?? '',
      authorUsername: map['authorUsername'] ?? '',
      authorPhotoURL: map['authorPhotoURL'],
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      imageURL: map['imageURL'],
      tags: List<String>.from(map['tags'] ?? []),
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updatedAt']) ?? DateTime.now(),
      likesCount: map['likesCount'] ?? 0,
      commentsCount: map['commentsCount'] ?? 0,
      viewsCount: map['viewsCount'] ?? 0,
      isPublished: map['isPublished'] ?? true,
      category: map['category'] ?? 'General',
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorUsername': authorUsername,
      'authorPhotoURL': authorPhotoURL,
      'title': title,
      'content': content,
      'imageURL': imageURL,
      'tags': tags,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'viewsCount': viewsCount,
      'isPublished': isPublished,
      'category': category,
    };
  }

  // Create copy with updated fields
  BlogModel copyWith({
    String? id,
    String? authorId,
    String? authorUsername,
    String? authorPhotoURL,
    String? title,
    String? content,
    String? imageURL,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likesCount,
    int? commentsCount,
    int? viewsCount,
    bool? isPublished,
    String? category,
  }) {
    return BlogModel(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorUsername: authorUsername ?? this.authorUsername,
      authorPhotoURL: authorPhotoURL ?? this.authorPhotoURL,
      title: title ?? this.title,
      content: content ?? this.content,
      imageURL: imageURL ?? this.imageURL,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      viewsCount: viewsCount ?? this.viewsCount,
      isPublished: isPublished ?? this.isPublished,
      category: category ?? this.category,
    );
  }

  // Get formatted date
  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  // Get reading time estimate (assuming 200 words per minute)
  int get readingTimeMinutes {
    final wordCount = content.split(' ').length;
    return (wordCount / 200).ceil();
  }
}
