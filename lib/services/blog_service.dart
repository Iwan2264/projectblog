import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/blog_model.dart';
import '../utils/logger_util.dart';

class BlogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> createBlog(BlogModel blog) async {
    try {
      DocumentReference doc = await _firestore.collection('blogs').add(blog.toMap());
      await _firestore.collection('users').doc(blog.authorId).update({
        'postsCount': FieldValue.increment(1),
      });
      AppLogger.info('Blog created successfully: ${doc.id}');
      return doc.id;
    } catch (e) {
      AppLogger.error('Error creating blog', e);
      throw Exception('Failed to create blog: $e');
    }
  }

  Future<BlogModel?> getBlog(String blogId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('blogs').doc(blogId).get();
      if (doc.exists) {
        return BlogModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      AppLogger.error('Error getting blog', e);
      throw Exception('Failed to get blog: $e');
    }
  }

  Future<List<BlogModel>> getBlogsByAuthor(String authorId, {int limit = 10}) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('blogs')
          .where('authorId', isEqualTo: authorId)
          .where('isPublished', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) =>
          BlogModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)
      ).toList();
    } catch (e) {
      AppLogger.error('Error getting blogs by author', e);
      throw Exception('Failed to get blogs by author: $e');
    }
  }

  Future<List<BlogModel>> getRecentBlogs({int limit = 20}) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('blogs')
          .where('isPublished', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) =>
          BlogModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)
      ).toList();
    } catch (e) {
      AppLogger.error('Error getting recent blogs', e);
      throw Exception('Failed to get recent blogs: $e');
    }
  }

  Future<List<BlogModel>> searchBlogs(String searchTerm, {int limit = 20}) async {
    try {
      QuerySnapshot titleQuery = await _firestore
          .collection('blogs')
          .where('isPublished', isEqualTo: true)
          .where('title', isGreaterThanOrEqualTo: searchTerm)
          .where('title', isLessThanOrEqualTo: searchTerm + '\uf8ff')
          .limit(limit)
          .get();

      return titleQuery.docs.map((doc) =>
          BlogModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)
      ).toList();
    } catch (e) {
      AppLogger.error('Error searching blogs', e);
      throw Exception('Failed to search blogs: $e');
    }
  }

  Future<void> updateBlog(String blogId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = DateTime.now();
      await _firestore.collection('blogs').doc(blogId).update(data);
      AppLogger.info('Blog updated successfully: $blogId');
    } catch (e) {
      AppLogger.error('Error updating blog', e);
      throw Exception('Failed to update blog: $e');
    }
  }

  Future<void> deleteBlog(String blogId, String authorId) async {
    try {
      await _firestore.collection('blogs').doc(blogId).delete();
      await _firestore.collection('users').doc(authorId).update({
        'postsCount': FieldValue.increment(-1),
      });
      AppLogger.info('Blog deleted successfully: $blogId');
    } catch (e) {
      AppLogger.error('Error deleting blog', e);
      throw Exception('Failed to delete blog: $e');
    }
  }

  Future<String> uploadBlogImage(String blogId, XFile imageFile) async {
    try {
      File file = File(imageFile.path);
      Reference ref = _storage.ref().child('blog_images').child('$blogId.jpg');
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadURL = await snapshot.ref.getDownloadURL();
      AppLogger.info('Blog image uploaded successfully: $blogId');
      return downloadURL;
    } catch (e) {
      AppLogger.error('Error uploading blog image', e);
      throw Exception('Failed to upload blog image: $e');
    }
  }

  Future<void> incrementBlogViews(String blogId) async {
    try {
      await _firestore.collection('blogs').doc(blogId).update({
        'viewsCount': FieldValue.increment(1),
      });
    } catch (e) {
      AppLogger.warning('Error incrementing blog views (non-critical)', e);
    }
  }
}