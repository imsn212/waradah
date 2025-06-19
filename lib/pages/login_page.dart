import 'package:flutter/material.dart';
import 'package:waradah/pages/forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  static const testEmail = 'test@example.com';
  static const testPassword = '123456';

  late AnimationController _controller;
  late Animation<Offset> _animation;

  bool _isVisible = false; // لعرض العناصر بشكل تدريجي
  bool _isPressed = false; // لتأثير الضغط على زر تسجيل الدخول

  @override
  void initState() {
    super.initState();

    // تحريك الشعار من الأسفل إلى الأعلى
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = Tween<Offset>(
      begin: const Offset(0, 0.5), // يبدأ من الأسفل
      end: Offset.zero, // ينتهي في المنتصف
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward(); // بدء الرسم المتحرك

    // عرض العناصر بشكل تدريجي بعد تأخير بسيط
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _isVisible = true;
      });
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _performLogin() {
    final inputEmail = emailController.text.trim();
    final inputPassword = passwordController.text;

    // التحقق من أن الحقول ليست فارغة
    if (inputEmail.isEmpty || inputPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال البريد الإلكتروني وكلمة المرور')),
      );
      return;
    }

    // التحقق من صحة البريد الإلكتروني
    if (inputEmail != testEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('البريد الإلكتروني غير صحيح')),
      );
      return;
    }

    // التحقق من صحة كلمة المرور
    if (inputPassword != testPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('كلمة المرور غير صحيحة')),
      );
      return;
    }

    // إذا كانت البيانات صحيحة، انتقل إلى الصفحة الرئيسية
    Navigator.pushReplacementNamed(context, '/home_page');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00A8FF),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SlideTransition(
            position: _animation,
            child: AnimatedOpacity(
              opacity: _isVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Hero(
                      tag: 'logo',
                      child: const CircleAvatar(
                        radius: 40,
                        backgroundImage: AssetImage('assets/images/gift_212.png'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00BFA6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Let's get you signed in!",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),

                    // Email
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'EMAIL',
                        hintText: 'your.email@example.com',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF00BFA6), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _performLogin(),
                      decoration: InputDecoration(
                        labelText: 'PASSWORD',
                        hintText: '••••••',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF00BFA6), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                          );
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Colors.grey,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Log in button with press animation
                    GestureDetector(
                      onTapDown: (_) => setState(() => _isPressed = true),
                      onTapUp: (_) => setState(() => _isPressed = false),
                      onTapCancel: () => setState(() => _isPressed = false),
                      onTap: _performLogin,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        height: _isPressed ? 50 : 60,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00BFA6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            'Log in',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: _isPressed ? 16 : 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // OR separator
                    Row(
                      children: const [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text('OR', style: TextStyle(color: Colors.grey)),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Google Sign-in Button
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: Image.asset(
                        'assets/images/google_logo.png',
                        height: 20,
                      ),
                      label: const Text(
                        'Sign in with Google',
                        style: TextStyle(color: Color(0xFF4285F4)),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 0),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sign up
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/create-account');
                      },
                      child: const Text(
                        'Sign up!',
                        style: TextStyle(
                          color: Color(0xFF00BFA6),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}