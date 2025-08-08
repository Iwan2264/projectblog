import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
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
            throw parseError; // If none of our custom formats matched
          } catch (e) {
            print('Error parsing date with custom formats: $e for value: $value');
            throw e;
          }
        }
      }
    } catch (e) {
      print('Error parsing date in CommentModel: $e for value: $value');
    }
    
    return null;
  }
  final String id;
  final String postId;
  final String authorId;
  final String authorUsername;
  final String? authorPhotoURL;
  final String? authorName;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likesCount;
  final List<String> likedBy;
  final String? parentCommentId; // For nested replies
  final List<String> replies; // IDs of reply comments

  CommentModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorUsername,
    this.authorPhotoURL,
    this.authorName,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.likesCount = 0,
    this.likedBy = const [],
    this.parentCommentId,
    this.replies = const [],
  });

  factory CommentModel.fromMap(String id, Map<String, dynamic> map) {
    return CommentModel(
      id: id,
      postId: map['postId'] ?? '',
      authorId: map['authorId'] ?? '',
      authorUsername: map['authorUsername'] ?? '',
      authorPhotoURL: map['authorPhotoURL'],
      authorName: map['authorName'],
      content: map['content'] ?? '',
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updatedAt']) ?? DateTime.now(),
      likesCount: map['likesCount'] ?? 0,
      likedBy: List<String>.from(map['likedBy'] ?? []),
      parentCommentId: map['parentCommentId'],
      replies: List<String>.from(map['replies'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'authorId': authorId,
      'authorUsername': authorUsername,
      'authorPhotoURL': authorPhotoURL,
      'authorName': authorName,
      'content': content,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'likesCount': likesCount,
      'likedBy': likedBy,
      'parentCommentId': parentCommentId,
      'replies': replies,
    };
  }

  CommentModel copyWith({
    String? id,
    String? postId,
    String? authorId,
    String? authorUsername,
    String? authorPhotoURL,
    String? authorName,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likesCount,
    List<String>? likedBy,
    String? parentCommentId,
    List<String>? replies,
  }) {
    return CommentModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      authorUsername: authorUsername ?? this.authorUsername,
      authorPhotoURL: authorPhotoURL ?? this.authorPhotoURL,
      authorName: authorName ?? this.authorName,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likesCount: likesCount ?? this.likesCount,
      likedBy: likedBy ?? this.likedBy,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      replies: replies ?? this.replies,
    );
  }
}
