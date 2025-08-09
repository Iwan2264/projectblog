import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String username;
  final String? name;
  final String? photoURL;
  final String? bio;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final List<String> interests;
  final bool isVerified;
  final int profileViews;
  final int totalLikesReceived;
  final int totalBlogViews;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    this.name,
    this.photoURL,
    this.bio,
    required this.createdAt,
    required this.lastLoginAt,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.interests = const [],
    this.isVerified = false,
    this.profileViews = 0,
    this.totalLikesReceived = 0,
    this.totalBlogViews = 0,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      name: map['name'],
      photoURL: map['photoURL'],
      bio: map['bio'],
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      lastLoginAt: _parseDateTime(map['lastLoginAt']) ?? DateTime.now(),
      followersCount: map['followersCount'] ?? 0,
      followingCount: map['followingCount'] ?? 0,
      postsCount: map['postsCount'] ?? 0,
      interests: List<String>.from(map['interests'] ?? []),
      isVerified: map['isVerified'] ?? false,
      profileViews: map['profileViews'] ?? 0,
      totalLikesReceived: map['totalLikesReceived'] ?? 0,
      totalBlogViews: map['totalBlogViews'] ?? 0,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    
    try {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String && value.isNotEmpty) {
        return DateTime.parse(value);
      } else if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
    } catch (e) {
      print('⚠️ WARNING: Failed to parse date: $value - Error: $e');
    }
    
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'name': name,
      'photoURL': photoURL,
      'bio': bio,
      'createdAt': createdAt,
      'lastLoginAt': lastLoginAt,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'interests': interests,
      'isVerified': isVerified,
      'profileViews': profileViews,
      'totalLikesReceived': totalLikesReceived,
      'totalBlogViews': totalBlogViews,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? username,
    String? name,
    String? photoURL,
    String? bio,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    List<String>? interests,
    bool? isVerified,
    int? profileViews,
    int? totalLikesReceived,
    int? totalBlogViews,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      name: name ?? this.name,
      photoURL: photoURL ?? this.photoURL,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      interests: interests ?? this.interests,
      isVerified: isVerified ?? this.isVerified,
      profileViews: profileViews ?? this.profileViews,
      totalLikesReceived: totalLikesReceived ?? this.totalLikesReceived,
      totalBlogViews: totalBlogViews ?? this.totalBlogViews,
    );
  }
}