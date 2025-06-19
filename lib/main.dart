import 'package:flutter/material.dart';
import 'pages/profile_page.dart';
import 'pages/splash_screen.dart';
import 'pages/welcome_page.dart';
import 'pages/create_account_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/forgot_password_page.dart';
import 'pages/otp_verification_page.dart';
import 'pages/create_new_password_page.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Waradah',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.light, // ✅ استخدام الوضع الفاتح فقط
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(), // ✅ الصفحة الأولى التي تظهر عند التشغيل (غيّرها لو حبيت)
      routes: {
        '/welcome': (context) => const WelcomePage(),
        '/create-account': (context) => const CreateAccountPage(),
        '/login': (context) => const LoginPage(),
        '/home_page': (context) => const HomePage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/otp-verification': (context) => const OtpVerificationPage(),
        '/create-new-password': (context) => const CreateNewPasswordPage(),
        '/profile': (context) => ProfilePage(), // ✅ تم إضافة صفحة الملف الشخصي
      },
    );
  }
}

// ✅ الثيم الفاتح المستخدم في التطبيق
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: const Color(0xFF00BFA6),
  scaffoldBackgroundColor: Colors.grey[200], // ✅ تم تغييره إلى لون رمادي فاتح
  fontFamily: 'Roboto',
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.black),
    bodyMedium: TextStyle(color: Colors.black87),
  ),
);

// ✅ الثيم الداكن (غير مستخدم حالياً)
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
);
