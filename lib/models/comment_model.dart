import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
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
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate() 
          : DateTime.parse(map['createdAt'].toString()),
      updatedAt: map['updatedAt'] is Timestamp 
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(map['updatedAt'].toString()),
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
