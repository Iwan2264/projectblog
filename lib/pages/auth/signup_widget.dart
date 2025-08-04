import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import 'term.dart';
import 'policy.dart';

class SignupWidget extends StatefulWidget {
  const SignupWidget({super.key});

  @override
  State<SignupWidget> createState() => _SignupWidgetState();
}

class _SignupWidgetState extends State<SignupWidget> {
  final _authController = Get.find<AuthController>();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false; // State for the checkbox

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // Welcome text
            Text(
              'Create Account',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                shadows: [
                    Shadow(
                    offset: const Offset(0, 1),
                    blurRadius: 3,
                    color: Colors.black.withAlpha(80),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Join us and start blogging',
                style: TextStyle(
                fontSize: 16,
                color: Colors.white.withAlpha(200),
              ),
            ),
            const SizedBox(height: 28),

            // Name field
            _buildTextField(
              controller: _nameController,
              hintText: 'Name',
              icon: Icons.badge_rounded,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Name required';
                if (value!.length < 2) return 'Name too short (min 2 chars)';
                return null;
              },
              style: const TextStyle(color: Colors.black),
            ),
            const SizedBox(height: 14),
            
            // Username field
            _buildTextField(
              controller: _usernameController,
              hintText: 'Username',
              icon: Icons.person_rounded,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Username required';
                if (value!.length < 3) return 'Username too short (min 3 chars)';
                return null;
              },
              style: const TextStyle(color: Colors.black),
            ),
            const SizedBox(height: 14),
            
            // Email field
            _buildTextField(
              controller: _emailController,
              hintText: 'Email',
              icon: Icons.email_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Email required';
                if (!GetUtils.isEmail(value!)) return 'Invalid email';
                return null;
              },
              style: const TextStyle(color: Colors.black),
            ),
            const SizedBox(height: 14),
            
            // Password field
            _buildTextField(
              controller: _passwordController,
              hintText: 'Password',
              icon: Icons.lock_rounded,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: Colors.grey[600],
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Password required';
                if (value!.length < 6) return 'Password too short (min 6 chars)';
                return null;
              },
              style: const TextStyle(color: Colors.black),
            ),
            const SizedBox(height: 14),
            
            // Confirm password field
            _buildTextField(
              controller: _confirmPasswordController,
              hintText: 'Confirm Password',
              icon: Icons.lock_rounded,
              obscureText: _obscureConfirmPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: Colors.grey[600],
                ),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Confirm password required';
                if (value != _passwordController.text) return 'Passwords do not match';
                return null;
              },
              style: const TextStyle(color: Colors.black),
            ),
            const SizedBox(height: 20),
            
            // --- NEW: Terms and Privacy Checkbox and Links ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Checkbox(
                  value: _agreeToTerms,
                  onChanged: (value) {
                    setState(() {
                      _agreeToTerms = value ?? false;
                    });
                  },
                  visualDensity: VisualDensity.compact,
                  activeColor: Colors.white,
                  checkColor: const Color(0xFF5D4DA8),
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      text: 'I agree to the ',
                      style: TextStyle(
                        color: Colors.white.withAlpha(180),
                        fontSize: 12,
                      ),
                      children: [
                        TextSpan(
                          text: 'Terms of Service',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Get.to(() => const TermsOfServicePage());
                            },
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Get.to(() => const PrivacyPolicyPage());
                            },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Error message
            Obx(() => _authController.errorMessage.value.isNotEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withAlpha(80)),
                    ),
                    child: Text(
                      _authController.errorMessage.value,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  )
                : const SizedBox.shrink()),
            
            // Sign up button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: Obx(() => ElevatedButton(
                onPressed: _authController.isLoading.value ? null : _handleSignup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF5D4DA8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                child: _authController.isLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Create Account',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              )),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    TextStyle style = const TextStyle(color: Colors.black),
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(230),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        style: style,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  void _handleSignup() async {
    // Check if terms are agreed to
    if (!_agreeToTerms) {
      Get.snackbar(
        'Terms and Conditions',
        'Please agree to the terms and conditions to continue.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withAlpha(200),
        colorText: Colors.white,
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      _authController.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _usernameController.text.trim(),
        _nameController.text.trim(),
      );
    }
  }
}