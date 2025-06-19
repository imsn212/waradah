import 'package:flutter/material.dart';

class OtpVerificationPage extends StatefulWidget {
  const OtpVerificationPage({super.key});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  late AnimationController _animationController;
  bool _error = false;

  final String _correctCode = '123456'; // كود وهمي للتجربة

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
    for (var controller in _controllers) {
      controller.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  void _verifyCode() {
    String inputCode = _controllers.map((e) => e.text).join();
    if (inputCode == _correctCode) {
      Navigator.pushReplacementNamed(context, '/create-new-password');
    } else {
      _animationController.forward(from: 0);
      setState(() {
        _error = true;
      });
    }
  }

  Widget _buildOtpField(int index) {
    return SizedBox(
      width: 45,
      child: TextField(
        controller: _controllers[index],
        textAlign: TextAlign.center,
        maxLength: 1,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00BFA6), width: 2),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            FocusScope.of(context).nextFocus();
          } else if (value.isEmpty && index > 0) {
            FocusScope.of(context).previousFocus();
          }
        },
      ),
    );
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
                const Icon(Icons.verified_user, size: 80, color: Color(0xFF00BFA6)),
                const SizedBox(height: 16),
                const Text(
                  "Enter Verification Code",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00BFA6),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "We’ve sent a 6-digit code to your email.",
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // 6 خانات للكود
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) => _buildOtpField(index)),
                ),
                const SizedBox(height: 20),

                // زر تأكيد
                ElevatedButton.icon(
                  onPressed: _verifyCode,
                  icon: RotationTransition(
                    turns: Tween(begin: 0.0, end: 1.0).animate(_animationController),
                    child: const Icon(Icons.check_circle),
                  ),
                  label: const Text("Verify Code"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BFA6),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    minimumSize: const Size(double.infinity, 0),
                  ),
                ),

                if (_error) ...[
                  const SizedBox(height: 16),
                  const Text(
                    "Incorrect code. Please try again.",
                    style: TextStyle(color: Colors.red),
                  ),
                ],

                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/forgot-password');
                  },
                  child: const Text(
                    "Resend Code",
                    style: TextStyle(
                      color: Color(0xFF00BFA6),
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
