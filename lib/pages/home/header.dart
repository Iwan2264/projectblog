import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:projectblog/controllers/settings_controller.dart';
import 'package:projectblog/widgets/cached_network_image.dart';

// Using a record to hold all style properties for a given time of day.
// This makes the code cleaner and more organized.
typedef TimeOfDayStyle = ({
  String greeting,
  IconData icon,
  Gradient gradient,
});

class Header extends StatelessWidget {
  final String? name;

  const Header({this.name, super.key});

  // A single function to get all UI properties based on the time.
  // This is more efficient than having separate functions.
  TimeOfDayStyle _getStyleForTimeOfDay(BuildContext context) {
    final hour = DateTime.now().hour;

    // Morning (6 AM - 11:59 AM)
    if (hour >= 6 && hour < 12) {
      return (
        greeting: 'Good Morning! 🌅',
        icon: Icons.wb_twilight_outlined, // Represents sunrise
        gradient: const LinearGradient(
          colors: [Color(0xFF89F7FE), Color(0xFF66A6FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    }
    // Afternoon (12 PM - 4:59 PM)
    if (hour >= 12 && hour < 17) {
      return (
        greeting: 'Good Afternoon! ☀️',
        icon: Icons.wb_sunny_outlined, // Represents full sun
        gradient: const LinearGradient(
          colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      );
    }
    // Evening (5 PM - 7:59 PM)
    if (hour >= 17 && hour < 20) {
      return (
        greeting: 'Good Evening! 🌇',
        icon: Icons.wb_twilight, // Represents sunset
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9A8B), Color(0xFFFF6A88)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    }
    // Night (8 PM - 5:59 AM)
    return (
      greeting: 'Good Night! 🌙',
      icon: Icons.nightlight_round, // Represents the moon
      gradient: const LinearGradient(
        colors: [Color(0xFF232526), Color(0xFF414345)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.find<SettingsController>();
    final textTheme = Theme.of(context).textTheme;
    // Get all the style properties for the current time in one call.
    final style = _getStyleForTimeOfDay(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: style.gradient, // Use the dynamic gradient
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Obx(() {
            final profileImageFile = settingsController.profileImage.value;
            final profileImageUrl = settingsController.profileImagePath.value;

            if (profileImageFile != null) {
              return CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white24,
                backgroundImage: FileImage(profileImageFile),
              );
            } else if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
              return CachedAvatar(
                imageUrl: profileImageUrl,
                radius: 32,
                backgroundColor: Colors.white24,
                fallback: const CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, size: 32, color: Colors.white),
                ),
              );
            }

            return const CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, size: 32, color: Colors.white),
            );
          }),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  style.greeting, // Use the dynamic greeting
                  style: textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withAlpha(225),
                  ),
                ),
                Obx(() {
                  final controllerName = settingsController.name.value;
                  final displayName = controllerName.isNotEmpty 
                                      ? controllerName 
                                      : name ?? 'User';

                  return Text(
                    displayName,
                    style: textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  );
                }),
              ],
            ),
          ),
          // --- Sun/Moon Icon ---
          // This icon now changes based on the time of day.
          Icon(style.icon, color: Colors.white, size: 30),
        ],
      ),
    );
  }
}