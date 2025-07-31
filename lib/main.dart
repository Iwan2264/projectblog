import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';

import 'controllers/auth_controller.dart';
import 'controllers/settings_controller.dart';
import 'pages/auth/auth_page.dart';
import 'pages/auth/email_verification.dart';
import 'pages/home/homepage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize controllers
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
        GetPage(name: '/auth', page: () => AuthPage()),
        GetPage(name: '/verify-email', page: () => EmailVerificationPage()),
        GetPage(name: '/home', page: () => HomePage()),
      ],
      home: Obx(() {
        if (_authController.firebaseUser.value == null) {
          return AuthPage();
        } else {
          if (!_authController.isEmailVerified()) {
            return EmailVerificationPage();
          } else {
            return HomePage();
          }
        }
      }),
      debugShowCheckedModeBanner: false,
    );
  }
}