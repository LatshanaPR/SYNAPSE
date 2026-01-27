import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../theme/app_theme.dart';

class TaskPasswordDialog extends StatefulWidget {
  final String? taskTitle;
  final bool isForgotPassword;
  final bool isSettingPassword;

  const TaskPasswordDialog({
    super.key,
    this.taskTitle,
    this.isForgotPassword = false,
    this.isSettingPassword = false,
  });

  @override
  State<TaskPasswordDialog> createState() => _TaskPasswordDialogState();
}

class _TaskPasswordDialogState extends State<TaskPasswordDialog> {
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      title: Text(
        widget.isForgotPassword
            ? 'Forgot Password'
            : widget.isSettingPassword
                ? 'Set Password'
                : 'Enter Password',
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
      ),
      content: widget.isForgotPassword
          ? const Text(
              'Password cannot be reset. Access to this task is cancelled.',
              style: TextStyle(color: Colors.grey),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.taskTitle != null && !widget.isSettingPassword) ...[
                  Text(
                    widget.taskTitle!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (widget.isSettingPassword)
                  Text(
                    'Set a password (min 4 characters)',
                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: widget.isSettingPassword ? 'New Password' : 'Password',
                    labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
      actions: [
        if (widget.isForgotPassword)
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('OK'),
          )
        else ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final password = _passwordController.text.trim();
              if (password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a password'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              if (widget.isSettingPassword && password.length < 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password must be at least 4 characters'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.of(context).pop(hashPassword(password));
            },
            child: Text(
              widget.isSettingPassword ? 'Set' : 'Unlock',
              style: const TextStyle(color: AppTheme.netflixRed),
            ),
          ),
        ],
      ],
    );
  }
}
