import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  bool _showSuccessMessage = false;
  late AnimationController _animationController;

  final String _validEmail = 'test@example.com'; // الإيميل الوهمي الصحيح

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _sendCode() {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }

    if (email != _validEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email not found. Please try again.')),
      );
      return;
    }

    // لو الإيميل صحيح
    _animationController.forward(from: 0);
    setState(() {
      _showSuccessMessage = true;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _showSuccessMessage = false;
      });
      Navigator.pushNamed(context, '/otp-verification', arguments: email);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00A8FF),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(38),

                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.lock_reset, size: 80, color: Color(0xFF00BFA6)),
                const SizedBox(height: 16),
                const Text(
                  "Forgot Password?",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00BFA6),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Don't worry! Enter your email and we'll send you a code.",
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'EMAIL',
                    hintText: 'your.email@example.com',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF00BFA6), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: _sendCode,
                  icon: RotationTransition(
                    turns: Tween(begin: 0.0, end: 1.0).animate(_animationController),
                    child: const Icon(Icons.key),
                  ),
                  label: const Text("Send Code"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BFA6),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    minimumSize: const Size(double.infinity, 0),
                  ),
                ),

                const SizedBox(height: 16),

                if (_showSuccessMessage)
                  const Text(
                    "Verification code sent to your email!",
                    style: TextStyle(color: Colors.green),
                  ),

                const SizedBox(height: 20),

                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  child: const Text(
                    "Back to Login",
                    style: TextStyle(
                      color: Color(0xFF00BFA6),
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
