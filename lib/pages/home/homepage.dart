import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:projectblog/controllers/auth_controller.dart'; // Import AuthController
import 'package:projectblog/pages/home/header.dart';
import 'package:projectblog/pages/home/dashboard.dart'; 
import 'package:projectblog/pages/home/blog_section.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AuthController authController = Get.find();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(left: 6, right: 6, top: 10, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() {
                  final user = authController.userModel.value;
                  return Header(
                    name: user?.name ?? 'Guest',
                  );
                }),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(6.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          "Dashboard!",
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Dashboard(
                        totalBlogs: 15,
                        totalLikes: 1200,
                        totalViews: 10000,
                        profileViews: 450,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(6.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const BlogSection(),
                ),              
              ],
            ),
          ),
        ),
      ),
    );
  }
}
