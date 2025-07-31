import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  final themeMode = ThemeMode.system.obs;
  SharedPreferences? _prefs;
  Timer? _saveTimer;

  @override
  void onInit() {
    super.onInit();
    _initPrefs();
  }

  @override
  void onClose() {
    _saveTimer?.cancel();
    super.onClose();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    loadTheme();
  }

  void loadTheme() {
    if (_prefs == null) return;
    final modeIndex = _prefs!.getInt('themeMode') ?? ThemeMode.system.index;
    themeMode.value = ThemeMode.values[modeIndex];
    Get.changeThemeMode(themeMode.value);
  }

  void setThemeImmediate(ThemeMode mode) {
    themeMode.value = mode;
    Get.changeThemeMode(mode);
    
    // Debounce saves to reduce disk I/O
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () {
      _saveThemeToPrefs(mode);
    });
  }

  Future<void> _saveThemeToPrefs(ThemeMode mode) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.setInt('themeMode', mode.index);
    } catch (e) {
      debugPrint('Failed to save theme preference: $e');
    }
  }
}