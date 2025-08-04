import 'package:flutter/material.dart';

class SubSettingsListWidget extends StatelessWidget {
  final List<String> settings;
  final void Function(String setting)? onTap;

  const SubSettingsListWidget({
    super.key,
    required this.settings,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (settings.isEmpty) {
      return const Center(
        child: Text('No settings available.'),
      );
    }

    return Column(
      children: List.generate(settings.length, (index) {
        final setting = settings[index];
        return Column(
          children: [
            ListTile(
              title: Text(setting),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onTap?.call(setting),
            ),
            if (index < settings.length - 1)
              const Divider(height: 1),
          ],
        );
      }),
    );
  }
}