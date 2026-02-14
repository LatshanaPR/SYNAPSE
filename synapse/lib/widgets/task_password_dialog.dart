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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      title: Text(
        widget.isForgotPassword
            ? 'Forgot Password'
            : widget.isSettingPassword
                ? 'Set Password'
                : 'Enter Password',
        style: TextStyle(color: colorScheme.onSurface),
      ),
      content: widget.isForgotPassword
          ? Text(
              'Password cannot be reset. Access to this task is cancelled.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.taskTitle != null && !widget.isSettingPassword) ...[
                  Text(
                    widget.taskTitle!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (widget.isSettingPassword)
                  Text(
                    'Set a password (min 4 characters)',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: widget.isSettingPassword ? 'New Password' : 'Password',
                    labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: colorScheme.onSurfaceVariant,
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
                  SnackBar(
                    content: const Text('Please enter a password'),
                    backgroundColor: colorScheme.error,
                  ),
                );
                return;
              }
              if (widget.isSettingPassword && password.length < 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Password must be at least 4 characters'),
                    backgroundColor: colorScheme.error,
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
