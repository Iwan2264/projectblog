import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'firebase_options.dart'; 

import 'controllers/auth_controller.dart';
import 'controllers/settings_controller.dart';
import 'pages/auth/auth_page.dart';
import 'pages/auth/email_verification.dart';
import 'widgets/navigation_scaffold.dart';
import 'controllers/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize controllers
  Get.put(ThemeController());
  Get.put(AuthController());
  Get.put(SettingsController());
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AuthController _authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Project Blog',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
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
  }
}