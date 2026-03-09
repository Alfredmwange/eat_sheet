import 'package:eat_sheet/screens/auth/login.dart';
import 'package:eat_sheet/screens/auth/register.dart';
import 'package:eat_sheet/screens/onboarding/onboarding_screen.dart';
import 'package:eat_sheet/screens/splash_screen.dart';
import 'package:eat_sheet/screens/main/dashboard_screen.dart';
import 'package:eat_sheet/screens/main/home_screen.dart';
import 'package:eat_sheet/screens/main/analytics_screen.dart';
import 'package:eat_sheet/screens/main/goals_screen.dart';
import 'package:eat_sheet/screens/main/profile_screen.dart';
import 'package:eat_sheet/screens/main/complete_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:eat_sheet/providers/theme_provider.dart';
import 'package:eat_sheet/providers/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Eat Sheet',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              useMaterial3: true,
              brightness: Brightness.light,
            ),
            darkTheme: ThemeData(
              primarySwatch: Colors.blue,
              useMaterial3: true,
              brightness: Brightness.dark,
            ),
            themeMode: themeProvider.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            home: const SplashScreen(),
            routes: {
              '/splash': (context) => const SplashScreen(),
              '/onboarding': (context) => const OnboardingScreen(),
              '/login': (context) => const Login(),
              '/register': (context) => const Register(),
              '/dashboard': (context) => const DashboardScreen(),
              '/home': (context) => HomeScreen(
                onMealTap: (meal) {
                  // handle meal tap, e.g. navigate to meal detail or logging
                  // TODO: replace with real implementation
                  debugPrint('Tapped on meal: $meal');
                }, username: '',
              ),
              '/analytics': (context) => const WeightAnalyticsScreen(),
              '/goals': (context) => const GoalsScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/complete-profile': (context) => const CompleteProfileScreen(),
            },
          );
        },
      ),
    );
  }
}
