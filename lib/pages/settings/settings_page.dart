
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:projectblog/controllers/settings_controller.dart';
import 'package:projectblog/pages/settings/profile_card.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with AutomaticKeepAliveClientMixin {
  final SettingsController controller = Get.find<SettingsController>();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.1,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.settings, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 6),
                child: Obx(
                  () => Form(
                    key: controller.formKey,
                    child: Column(
                      children: [
                        ProfileInfoWidget(controller: controller),
                        const SizedBox(height: 10),
                        if (controller.settings.isEmpty)
                          const Center(
                            child: Text('No settings available.'),
                          )
                        else
                          Column(
                          children: [
                            ...List.generate(controller.settings.length, (index) {
                            final setting = controller.settings[index];
                            return Column(
                              children: [
                              Container(
                                color: Theme.of(context).colorScheme.surface.withAlpha(200),
                                child: ListTile(
                                shape: Border.all(style: BorderStyle.none),
                                title: Text(setting),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => controller.navigateToSetting(setting),
                                ),
                              ),
                              if (index < controller.settings.length - 1)
                                const Divider(height: 1),
                              ],
                            );
                            }),
                            const Divider(height: 1),
                          ],
                          )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}