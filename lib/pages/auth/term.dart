import 'package:flutter/material.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            'Terms of Service\n\n'
            '1. Acceptance of Terms: By using this app, you agree to these terms.\n\n'
            '2. User Responsibilities: You are responsible for maintaining the confidentiality of your account.\n\n'
            '3. Content Ownership: All content you upload remains yours, but you grant us a license to use it for service improvement.\n\n'
            '4. Privacy: We respect your privacy and will not share your personal information without consent.\n\n'
            '5. Prohibited Activities: You may not use the app for illegal or harmful activities.\n\n'
            '6. Modifications: We may update these terms at any time. Continued use means acceptance of changes.\n\n'
            '7. Termination: We reserve the right to terminate accounts that violate these terms.\n\n'
            '8. Limitation of Liability: We are not liable for any damages resulting from the use of this app.\n\n'
            '9. Contact: For questions, contact support@example.com.\n\n'
            'Thank you for using our service!',
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}