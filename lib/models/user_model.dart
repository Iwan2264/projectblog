import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String username;
  final String? photoURL;
  final String? bio;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final List<String> interests;
  final bool isVerified;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    this.photoURL,
    this.bio,
    required this.createdAt,
    required this.lastLoginAt,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.interests = const [],
    this.isVerified = false,
  });

  // Create from Firebase user
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      photoURL: map['photoURL'],
      bio: map['bio'],
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate() 
          : DateTime.parse(map['createdAt'].toString()),
      lastLoginAt: map['lastLoginAt'] is Timestamp 
          ? (map['lastLoginAt'] as Timestamp).toDate()
          : DateTime.parse(map['lastLoginAt'].toString()),
      followersCount: map['followersCount'] ?? 0,
      followingCount: map['followingCount'] ?? 0,
      postsCount: map['postsCount'] ?? 0,
      interests: List<String>.from(map['interests'] ?? []),
      isVerified: map['isVerified'] ?? false,
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'photoURL': photoURL,
      'bio': bio,
      'createdAt': createdAt,
      'lastLoginAt': lastLoginAt,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'interests': interests,
      'isVerified': isVerified,
    };
  }

  // Create copy with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? username,
    String? photoURL,
    String? bio,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    List<String>? interests,
    bool? isVerified,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      photoURL: photoURL ?? this.photoURL,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      interests: interests ?? this.interests,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}