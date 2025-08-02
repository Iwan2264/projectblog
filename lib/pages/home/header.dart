import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  final String userName;
  final String photoUrl;

  const Header({required this.userName, required this.photoUrl, super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning! 🌅';
    if (hour < 17) return 'Good Afternoon! 🌞';
    return 'Good Evening! 🌙';
  }

  // This function returns a different gradient based on the time
  LinearGradient _getGradient() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      // Sunrise Gradient
      return LinearGradient(
        colors: [Colors.orange.shade300, Colors.lightBlue.shade300],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (hour < 17) {
      // Afternoon Gradient
      return LinearGradient(
        colors: [Colors.blue.shade400, Colors.lightBlue.shade200],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    }
    // Evening/Night Gradient
    return LinearGradient(
      colors: [Colors.deepPurple.shade700, Colors.indigo.shade900],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        gradient: _getGradient(),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: NetworkImage(photoUrl),
          ),
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
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
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