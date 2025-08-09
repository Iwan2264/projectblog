import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:projectblog/controllers/settings_controller.dart';
import 'package:projectblog/pages/settings/account_page.dart';
import 'package:projectblog/widgets/cached_network_image.dart';

class ProfileInfoWidget extends StatelessWidget {
  final SettingsController controller;

  const ProfileInfoWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Card(
        elevation: 3,
        color: theme.colorScheme.surface.withAlpha(225),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Get.to(() => AccountPage()),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                controller.isNetworkImage()
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: CachedImage(
                      imageUrl: controller.getProfileImageSource(),
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    ),
                  )
                : CircleAvatar(
                    radius: 32,
                    backgroundColor: theme.colorScheme.surface,
                    backgroundImage: controller.getProfileImageSource() != null
                        ? FileImage(controller.getProfileImageSource()) as ImageProvider
                        : null,
                    child: controller.getProfileImageSource() == null
                        ? Icon(
                            Icons.person,
                            size: 32,
                            color: theme.colorScheme.primary.withAlpha(100),
                          )
                        : null,
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.name.value,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        controller.username.value,
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 18)
              ],
            ),
          ),
        ),
      ),
    ));
  }
}