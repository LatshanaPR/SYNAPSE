import 'package:flutter/material.dart';

/// App-wide messenger utilities (safe to call from services).
///
/// Allows services (like notification/alarm services) to show SnackBars without
/// needing a BuildContext.
class AppMessenger {
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void showSnackBar(
    String message, {
    Color backgroundColor = Colors.orange,
    Duration duration = const Duration(seconds: 4),
  }) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) {
      // App not ready / no scaffold yet.
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
      ),
    );
  }
}

