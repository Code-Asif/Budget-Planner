// import 'package:budget_planner/home3.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login.dart';
import 'register.dart'; // Import the register page
// import 'home.dart';
import 'splash.dart';
import 'home2.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const MyApp());
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Your Expense Tracker',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        // '/home': (context) => const HomePage(),
        '/home': (context) => const Home2(),
        // '/home': (context) => const Home3(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        // '/settings': (context) => const SettingsPage(),
      },
    );
  }
}
