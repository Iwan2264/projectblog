import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

// Import Firebase options - use default options for now
import 'firebase_options.dart';

import 'controllers/auth_controller.dart';
import 'controllers/settings_controller.dart';
import 'controllers/blog_controller.dart';
import 'services/blog_service.dart';
import 'pages/auth/auth_page.dart';
import 'pages/auth/email_verification.dart';
import 'widgets/navigation_scaffold.dart';
import 'controllers/theme_controller.dart';
import 'utils/app_theme.dart';
import 'pages/blog/blog_detail_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase with default configuration
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Configure Firestore settings to handle large documents
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    
    // Clear Firestore cache to resolve any corruption issues
    try {
      await FirebaseFirestore.instance.clearPersistence();
      print('✅ Firestore cache cleared successfully');
    } catch (e) {
      print('⚠️ Could not clear Firestore cache (normal if app was running): $e');
    }
    
    // Initialize controllers
    Get.put(ThemeController());
    Get.put(AuthController());
    Get.put(SettingsController());
    Get.put(BlogService());
    Get.put(BlogController());
  } catch (e) {
    // If Firebase initialization fails, show a meaningful error
    runApp(ErrorApp(error: e.toString()));
    return;
  }
  
  runApp(MyApp());
}

// Simple error app to show Firebase initialization errors
class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Firebase Initialization Error',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  error,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    main();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class MyApp extends StatelessWidget {
  final ThemeController _themeController = Get.find<ThemeController>();
  final AuthController _authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return GetMaterialApp(
        title: 'Project Blog',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _themeController.themeMode.value, 

        initialRoute: '/auth',
        getPages: [
          GetPage(name: '/auth', page: () => const AuthPage()),
          GetPage(name: '/verify-email', page: () => const EmailVerificationPage()),
          GetPage(name: '/home', page: () => MainNavScaffold()),
          // Blog detail page with dynamic parameter for blog ID
          GetPage(
            name: '/blog/detail/:blogId',
            page: () {
              // Get the blogId parameter from the URL
              final blogId = Get.parameters['blogId'] ?? '';
              print('🔍 DEBUG: Blog detail route called with blogId: $blogId');
              // Make sure the parameter is correctly passed to BlogDetailPage
              return BlogDetailPage(blogId: blogId);
            }
          ),
        ],
        home: Obx(() {
          if (_authController.firebaseUser.value == null) {
            return const AuthPage();
          } else {
            if (!_authController.isEmailVerified()) {
              return const EmailVerificationPage();
            } else {
              return MainNavScaffold();
            }
          }
        }),
        debugShowCheckedModeBanner: false,
      );
    });
  }
}