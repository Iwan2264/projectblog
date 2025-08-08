import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ScheduledBlogsGrid extends StatefulWidget {
  const ScheduledBlogsGrid({super.key});

  @override
  State<ScheduledBlogsGrid> createState() => _ScheduledBlogsGridState();
}

class _ScheduledBlogsGridState extends State<ScheduledBlogsGrid> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            "Scheduled posting coming soon!",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Schedule your posts to publish at the perfect time.",
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              Get.snackbar(
                'Coming Soon',
                'Scheduled posting feature will be available in the next update!',
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 3),
              );
            },
            icon: const Icon(Icons.notifications_outlined),
            label: const Text('Notify me when ready'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}