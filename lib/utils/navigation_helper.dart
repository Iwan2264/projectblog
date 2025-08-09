// This file contains standardized navigation helpers to ensure consistent navigation
// patterns throughout the app

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NavigationHelper {
  /// Navigate to a new page with consistent animation and behavior
  static Future<T?> toPage<T>(Widget page, {String? name}) async {
    return await Get.to<T>(
      () => page,
      transition: Transition.rightToLeft,
      preventDuplicates: true,
      popGesture: true,
      fullscreenDialog: false,
      curve: Curves.easeInOut,
      duration: const Duration(milliseconds: 300),
      routeName: name,
    );
  }

  /// Replace the current page with a new one
  static Future<T?> toPageReplacement<T>(Widget page, {String? name}) async {
    return await Get.off<T>(
      () => page,
      transition: Transition.rightToLeft,
      preventDuplicates: true,
      popGesture: true,
      curve: Curves.easeInOut,
      duration: const Duration(milliseconds: 300),
      routeName: name,
    );
  }

  /// Navigate to a named route
  static Future<T?> toNamedPage<T>(String routeName, {dynamic arguments}) async {
    return await Get.toNamed<T>(
      routeName,
      arguments: arguments,
      preventDuplicates: true,
    );
  }

  /// Navigate back with optional result
  static void back<T>({T? result}) {
    Get.back<T>(result: result);
  }

  /// Back until a specific route
  static void backUntil(String routeName) {
    Get.until((route) => route.settings.name == routeName);
  }

  /// Replace all previous pages with a new one
  static Future<T?> replaceAllWith<T>(Widget page, {String? name}) async {
    return await Get.offAll<T>(
      () => page,
      transition: Transition.rightToLeft,
      popGesture: true,
      curve: Curves.easeInOut,
      duration: const Duration(milliseconds: 300),
      routeName: name,
    );
  }
}
