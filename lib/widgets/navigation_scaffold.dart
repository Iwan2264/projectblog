import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/nav_controller.dart';
import '../controllers/settings_controller.dart';
import '../pages/settings/settings_page.dart';
import '../pages/home/homepage.dart';
import '../pages/blog/blog_homepage.dart';

class MainNavScaffold extends StatefulWidget {
  MainNavScaffold({super.key});

  @override
  State<MainNavScaffold> createState() => _MainNavScaffoldState();
}

class _MainNavScaffoldState extends State<MainNavScaffold> with AutomaticKeepAliveClientMixin {
  final NavigationController navController = Get.put(NavigationController());

  // Static screens to preserve state across tab changes
  static Widget? _blogHomePage;
  static Widget? _homePage;
  static Widget? _settingsPage;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Initialize screens once and reuse them
    _blogHomePage ??= const BlogHomePage();
    _homePage ??= const HomePage();
    _settingsPage ??= SettingsPage();
    
    // Add listener for navigation index changes
    navController.selectedIndex.listen((index) {
      // If Settings tab is selected, refresh the user profile
      if (index == 2) { // Settings tab index
        // Add a small delay to ensure UI is rebuilt properly
        Future.delayed(const Duration(milliseconds: 100), () {
          final settingsController = Get.find<SettingsController>();
          settingsController.refreshUserData();
        });
      }
    });
  }

  List<Widget> get _screens => [
    _blogHomePage!,
    _homePage!,
    _settingsPage!,
  ];

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Obx(() => Scaffold(
      body: IndexedStack(
        index: navController.selectedIndex.value,
        children: _screens,
      ),
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