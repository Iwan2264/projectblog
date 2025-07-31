import 'package:flutter/material.dart';
import 'package:projectblog/pages/home/header.dart';
import 'package:projectblog/pages/home/dashboard.dart';
import 'package:projectblog/pages/home/blog_section.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Header(
                  userName: "Safwan", // <-- Updated to your name!
                  photoUrl: 'https://i.pravatar.cc/150?img=58',
                ),
                const SizedBox(height: 24),
                const Text(
                  "Dashboard",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                // Use a sized box to prevent overflow
                SizedBox(
                  height: 120, // Adjust as needed
                  child: Dashboard(
                    totalBlogs: 15,
                    totalLikes: 1205,
                    totalViews: 8300,
                    profileViews: 450,
                  ),
                ),
                const SizedBox(height: 24),
                const BlogSection(),
              ],
            ),
          ),
        ),
      ),
      // bottomNavigationBar: BottomNavigationBar(...)
    );
  }
}