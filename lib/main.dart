import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';

import 'config/firebase_config.dart';
import 'controllers/auth_controller.dart';
import 'controllers/settings_controller.dart';
import 'pages/auth/auth_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await FirebaseConfig.initializeFirebase();
  
  // Initialize controllers
  Get.put(AuthController());
  Get.put(SettingsController());
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final SettingsController _settingsController = Get.find<SettingsController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
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
        themeMode: _settingsController.isDarkMode.value 
            ? ThemeMode.dark 
            : ThemeMode.light,
        initialRoute: '/auth',
        getPages: [
          GetPage(
            name: '/auth',
            page: () => AuthPage(),
          ),
          // Add more routes here
        ],
        debugShowCheckedModeBanner: false,
      );
    });
  }
}