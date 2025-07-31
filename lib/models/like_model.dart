import 'package:cloud_firestore/cloud_firestore.dart';

class LikeModel {
  final String id;
  final String userId;
  final String blogId;
  final String blogAuthorId;
  final DateTime createdAt;

  LikeModel({
    required this.id,
    required this.userId,
    required this.blogId,
    required this.blogAuthorId,
    required this.createdAt,
  });

  // Create from Firestore document
  factory LikeModel.fromMap(Map<String, dynamic> map, String documentId) {
    return LikeModel(
      id: documentId,
      userId: map['userId'] ?? '',
      blogId: map['blogId'] ?? '',
      blogAuthorId: map['blogAuthorId'] ?? '',
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate() 
          : DateTime.parse(map['createdAt'].toString()),
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'blogId': blogId,
      'blogAuthorId': blogAuthorId,
      'createdAt': createdAt,
    };
  }

  // Create copy with updated fields
  LikeModel copyWith({
    String? id,
    String? userId,
    String? blogId,
    String? blogAuthorId,
    DateTime? createdAt,
  }) {
    return LikeModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      blogId: blogId ?? this.blogId,
      blogAuthorId: blogAuthorId ?? this.blogAuthorId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
