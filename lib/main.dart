import 'package:eat_sheet/screens/auth/login.dart';
import 'package:eat_sheet/screens/auth/register.dart';
import 'package:eat_sheet/screens/onboarding/onboarding_screen.dart';
import 'package:eat_sheet/screens/splash_screen.dart';
import 'package:eat_sheet/screens/main/dashboard_screen.dart';
import 'package:eat_sheet/screens/main/home_screen.dart';
import 'package:eat_sheet/screens/main/analytics_screen.dart';
import 'package:eat_sheet/screens/main/goals_screen.dart';
import 'package:eat_sheet/screens/main/profile_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eat Sheet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const Login(),
        '/register': (context) => const Register(),
        '/dashboard': (context) => const DashboardScreen(),
        '/home': (context) => const HomeScreen(),
        '/analytics': (context) => const AnalyticsScreen(),
        '/goals': (context) => const GoalsScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}