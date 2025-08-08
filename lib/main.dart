import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'dart:io' show File;

// Import Firebase options
import 'firebase_options.dart'; 
// Try to import dev options if they exist
import 'firebase_options_dev.dart' if (dart.library.io) 'firebase_options.dart' as dev;

import 'controllers/auth_controller.dart';
import 'controllers/settings_controller.dart';
import 'controllers/blog_controller.dart';
import 'services/blog_service.dart';
import 'pages/auth/auth_page.dart';
import 'pages/auth/email_verification.dart';
import 'widgets/navigation_scaffold.dart';
import 'controllers/theme_controller.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Check if development configuration file exists
    bool useDevConfig = await File('lib/firebase_options_dev.dart').exists();
    
    // Initialize Firebase with appropriate configuration
    await Firebase.initializeApp(
      options: useDevConfig 
        ? dev.DevFirebaseOptions.currentPlatform 
        : DefaultFirebaseOptions.currentPlatform,
    );
    
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