import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class VerificationDialog extends StatefulWidget {
  const VerificationDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const VerificationDialog(),
    );
  }

  @override
  State<VerificationDialog> createState() => _VerificationDialogState();
}

class _VerificationDialogState extends State<VerificationDialog> {
  bool _isReloading = false;
  bool _isResending = false;

  Future<void> _handleReload(AppState appState) async {
    setState(() => _isReloading = true);
    await appState.reloadUser();
    if (mounted) {
      if (appState.isEmailVerified) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Email verified successfully! Welcome, Hero."),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Email not verified yet. Please check your inbox."),
          ),
        );
      }
      setState(() => _isReloading = false);
    }
  }

  Future<void> _handleResend(AppState appState) async {
    setState(() => _isResending = true);
    final error = await appState.sendEmailVerification();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? "Verification email resent!"),
          backgroundColor: error != null ? Colors.redAccent : Colors.blueAccent,
        ),
      );
      setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Row(
        children: [
          Icon(Icons.mark_email_read_rounded, color: colorScheme.primary),
          const SizedBox(width: 12),
          const Text("Verify Email"),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Please verify your email address to unlock all hero features and secure your account.",
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            appState.currentUser?.email ?? "your email",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            "Already clicked the link in your inbox?",
            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _isResending ? null : () => _handleResend(appState),
              child: _isResending
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Resend Email"),
            ),
            FilledButton(
              onPressed: _isReloading ? null : () => _handleReload(appState),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isReloading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text("I've Verified"),
            ),
          ],
        ),
      ],
    );
  }
}
