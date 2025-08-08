import 'package:cloud_firestore/cloud_firestore.dart';

// This file contains test/debug code to check if blogs exist in Firestore
// You can run this to verify the database connection and data structure

Future<void> checkBlogData() async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  
  print('🔍 Starting blog data check...');
  
  try {
    // Check global blogs collection
    QuerySnapshot globalBlogs = await firestore
        .collection('blogs')
        .get();
    
    print('📊 Found ${globalBlogs.docs.length} documents in global blogs collection');
    
    if (globalBlogs.docs.isNotEmpty) {
      print('📄 Example global blog: ${globalBlogs.docs.first.data()}');
    }
    
    // Check users collection
    QuerySnapshot users = await firestore
        .collection('users')
        .get();
    
    print('👤 Found ${users.docs.length} users');
    
    if (users.docs.isNotEmpty) {
      // Check first user's blogs
      String firstUserId = users.docs.first.id;
      print('👤 Checking blogs for user: $firstUserId');
      
      QuerySnapshot userBlogs = await firestore
          .collection('users')
          .doc(firstUserId)
          .collection('blogs')
          .get();
      
      print('📄 Found ${userBlogs.docs.length} blogs for user $firstUserId');
      
      if (userBlogs.docs.isNotEmpty) {
        print('📄 Example user blog: ${userBlogs.docs.first.data()}');
      }
    }
  } catch (e) {
    print('❌ Error checking blog data: $e');
  }
  
  print('✅ Blog data check complete');
}
