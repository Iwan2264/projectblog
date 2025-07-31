import 'package:flutter/material.dart';

class Dashboard extends StatelessWidget {
  final int totalBlogs;
  final int totalLikes;
  final int totalViews;
  final int profileViews;

  const Dashboard({
    required this.totalBlogs,
    required this.totalLikes,
    required this.totalViews,
    required this.profileViews,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2.5,
      children: [
        DashboardCard(title: "Total Blogs", value: totalBlogs.toString(), icon: Icons.article),
        DashboardCard(title: "Total Views", value: totalViews.toString(), icon: Icons.visibility),
        DashboardCard(title: "My Likes", value: totalLikes.toString(), icon: Icons.favorite),
        DashboardCard(title: "Profile Views", value: profileViews.toString(), icon: Icons.person),
      ],
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          )
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: Colors.deepPurple),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}