import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:projectblog/controllers/settings_controller.dart';

class Header extends StatelessWidget {
  final String? name;

  const Header({required this.name, super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning! 🌅';
    if (hour < 17) return 'Good Afternoon! 🌞';
    return 'Good Evening! 🌙';
  }

  LinearGradient _getGradient() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return LinearGradient(
        colors: [Colors.orange.shade300, Colors.lightBlue.shade300],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (hour < 17) {
      return LinearGradient(
        colors: [Colors.blue.shade400, Colors.lightBlue.shade200],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    }
    return LinearGradient(
      colors: [Colors.deepPurple.shade700, Colors.indigo.shade900],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.find<SettingsController>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        gradient: _getGradient(),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Obx(() {
            final profileImage = settingsController.profileImage.value;
            final profileImagePath = settingsController.profileImagePath.value;

            if (profileImage != null) {
              return CircleAvatar(
                radius: 40,
                backgroundImage: FileImage(profileImage),
                backgroundColor: Colors.grey.shade400,
              );
            } else if (profileImagePath != null && profileImagePath.isNotEmpty) {
              return CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(profileImagePath),
                backgroundColor: Colors.grey.shade400,
              );
            } else {
              return CircleAvatar(
                radius: 40,
                child: const Icon(Icons.person, size: 40, color: Colors.white),
                backgroundColor: Colors.grey.shade400,
              );
            }
          }),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
                Obx(() => Text(
                  settingsController.name.value.isNotEmpty 
                      ? settingsController.name.value
                      : name ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }
}