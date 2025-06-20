import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 5), () {
      _checkAuthStatus();
    });
  }

  void _checkAuthStatus() {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/ExpenseTracker.gif',
              width: 300,
              height: 300,
            ),
            const SizedBox(height: 20),
            const Text(
              'Welcome',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
//  - -------------------------------------------------

// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   _SplashScreenState createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> {
//   @override
//   void initState() {
//     super.initState();
    
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _startSplashTimer();
//     });
//   }

//   void _startSplashTimer() {
//     Future.delayed(const Duration(seconds: 4), () {
//       if (mounted) {
//         _checkAuthStatus();
//       }
//     });
//   }

//   void _checkAuthStatus() {
//     final User? user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       Navigator.pushReplacementNamed(context, '/login');
//     } else {
//       Navigator.pushReplacementNamed(context, '/home');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Image.asset(
//               'assets/ExpenseLogo.png',
//               width: 300,
//               height: 300,
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               'Welcome',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 40,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.teal,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
