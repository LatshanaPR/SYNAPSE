import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import 'login_screen.dart';
import 'home_screen.dart';

/// AuthGate widget that checks Firebase authentication state
/// and routes users to the appropriate screen
/// Shows Instagram-style logo screen at startup
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _showLogo = true;
  bool _minTimePassed = false;
  bool _authReady = false;

  @override
  void initState() {
    super.initState();
    // Ensure logo shows for at least 2 seconds
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _minTimePassed = true;
          _checkReady();
        });
      }
    });
  }

  void _checkReady() {
    if (_minTimePassed && _authReady && _showLogo) {
      // Small delay to ensure smooth transition
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            _showLogo = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Mark auth as ready when resolved
        if (snapshot.connectionState != ConnectionState.waiting && !_authReady) {
          Future.microtask(() {
            if (mounted) {
              setState(() {
                _authReady = true;
                _checkReady();
              });
            }
          });
        }

        // Show logo until both minimum time passed AND auth is ready
        if (_showLogo && (!_minTimePassed || !_authReady || 
            snapshot.connectionState == ConnectionState.waiting)) {
          return Scaffold(
            backgroundColor: AppTheme.black,
            body: Center(
              child: AppLogo(size: 200),
            ),
          );
        }

        // If user is logged in, show HomeScreen
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        }

        // If user is not logged in, show LoginScreen
        return const LoginScreen();
      },
    );
  }
}
