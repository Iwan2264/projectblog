import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize controllers
  Get.put(ThemeController());
  Get.put(AuthController());
  Get.put(SettingsController());
  Get.put(BlogService());
  Get.put(BlogController());
  
  runApp(MyApp());
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