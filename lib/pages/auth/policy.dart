import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            '''
Demo Privacy Policy

1. Introduction
We value your privacy and are committed to protecting your personal information.

2. Information Collection
We may collect information such as your name, email address, and usage data to improve our services.

3. Use of Information
Your information is used to provide and enhance our services, and will not be shared with third parties without your consent.

4. Data Security
We implement security measures to protect your data from unauthorized access.

5. Changes to Policy
We may update this policy from time to time. Please review it periodically.

6. Contact Us
If you have any questions about this policy, please contact us at support@example.com.
''',
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}