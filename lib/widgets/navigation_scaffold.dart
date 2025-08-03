import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/nav_controller.dart';
import '../pages/settings/settings_page.dart';
import '../pages/home/homepage.dart';
import '../pages/blog/blog_homepage.dart';

class MainNavScaffold extends StatelessWidget {
  MainNavScaffold({super.key});
  final NavigationController navController = Get.put(NavigationController());

  final List<Widget> _screens = [
    const BlogHomePage(),
    const HomePage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
      body: _screens[navController.selectedIndex.value],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navController.selectedIndex.value,
        onTap: (index) => navController.selectedIndex.value = index,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.article_outlined),
            label: 'Blog',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    ));
  }
}