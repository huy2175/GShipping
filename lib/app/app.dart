import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/home/screens/main_screen.dart';

class GShippingApp extends StatelessWidget {
  const GShippingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GShipping',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const MainScreen();
        }

        return const LoginScreen();
      },
    );
  }
}

// Delete the old HomeScreen class
