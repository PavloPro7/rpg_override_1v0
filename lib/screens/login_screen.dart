import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

  // Removed confirm password check from here as it's now handled below.

    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    final appState = context.read<AppState>();
    String? error;

    if (_isLogin) {
      error = await appState.signIn(email, password);
    } else {
      if (password != _confirmPasswordController.text.trim()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Passwords do not match"),
            backgroundColor: Colors.orangeAccent,
          ),
        );
        return;
      }
      error = await appState.signUp(email, password);
    }

    if (mounted && error != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(error), 
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            left: 16, 
            right: 16, 
            bottom: 16 + MediaQuery.of(context).padding.bottom,
          ),
          duration: Duration(seconds: error.length > 50 ? 5 : 3),
        ),
      );
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController(text: _emailController.text);
    final colorScheme = Theme.of(context).colorScheme;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter your email and we\'ll send you a reset link.'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) async {
                final email = emailController.text.trim();
                if (email.isEmpty) return;

                final messenger = ScaffoldMessenger.of(context);
                final error = await context
                    .read<AppState>()
                    .sendPasswordResetEmail(email);

                if (context.mounted) Navigator.pop(context);

                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      error ?? 'Password reset link sent to $email',
                    ),
                    backgroundColor: error != null
                        ? Colors.redAccent
                        : Colors.green,
                  ),
                );
              },
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) return;

              final messenger = ScaffoldMessenger.of(context);
              final error = await context
                  .read<AppState>()
                  .sendPasswordResetEmail(email);

              if (context.mounted) Navigator.pop(context);

              messenger.showSnackBar(
                SnackBar(
                  content: Text(error ?? 'Password reset link sent to $email'),
                  backgroundColor: error != null
                      ? Colors.redAccent
                      : Colors.green,
                ),
              );
            },
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Premium Background Layer 1: Base Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.surface,
                  colorScheme.primaryContainer.withValues(alpha: 0.1),
                ],
              ),
            ),
          ),

          // Layer 2: Abstract Blobs
          Positioned(
            top: -100,
            right: -50,
            child: _buildBlob(250, colorScheme.primary.withValues(alpha: 0.15)),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: _buildBlob(
              300,
              colorScheme.secondary.withValues(alpha: 0.15),
            ),
          ),
          if (!_isLogin)
            Positioned(
              top: size.height * 0.4,
              right: -100,
              child: _buildBlob(
                200,
                colorScheme.tertiary.withValues(alpha: 0.1),
              ),
            ),

          // Layer 3: Glassmorphism Blur
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(color: Colors.transparent),
            ),
          ),

          // Layer 4: Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: AutofillGroup(
                  child: Card(
                    elevation: 0,
                    color: colorScheme.surface.withValues(alpha: 0.7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                      side: BorderSide(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isLogin
                                  ? Icons.login_rounded
                                  : Icons.person_add_rounded,
                              size: 48,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _isLogin ? 'Welcome Back' : 'Create Hero',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: colorScheme.onSurface,
                                  letterSpacing: -0.5,
                                ),
                          ),
                          const SizedBox(height: 32),
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: [AutofillHints.email],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _passwordController,
                            label: 'Password',
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                            isPasswordVisible: _showPassword,
                            onToggleVisibility: () =>
                                setState(() => _showPassword = !_showPassword),
                            autofillHints: [AutofillHints.password],
                            textInputAction: _isLogin
                                ? TextInputAction.done
                                : TextInputAction.next,
                            onSubmitted: _isLogin ? (_) => _submit() : null,
                          ),
                          if (!_isLogin) ...[
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _confirmPasswordController,
                              label: 'Repeat Password',
                              icon: Icons.lock_reset_rounded,
                              isPassword: true,
                              isPasswordVisible: _showConfirmPassword,
                              onToggleVisibility: () => setState(
                                () => _showConfirmPassword =
                                    !_showConfirmPassword,
                              ),
                              autofillHints: [AutofillHints.newPassword],
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _submit(),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Consumer<AppState>(
                            builder: (context, appState, child) => Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: Checkbox(
                                        value: appState.staySignedIn,
                                        onChanged: (val) => appState
                                            .setStaySignedIn(val ?? true),
                                        activeColor: colorScheme.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Stay Signed in',
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                if (_isLogin)
                                  TextButton(
                                    onPressed: _showForgotPasswordDialog,
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: FilledButton(
                              onPressed: _isLoading ? null : _submit,
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _isLogin ? 'Login' : 'Register',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          GestureDetector(
                            onTap: () => setState(() {
                              _isLogin = !_isLogin;
                              _confirmPasswordController.clear();
                            }),
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: _isLogin
                                        ? "Don't have an account? "
                                        : "Already have an account? ",
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  TextSpan(
                                    text: _isLogin ? "Register" : "Login",
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: colorScheme.outlineVariant.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  "OR",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: colorScheme.outlineVariant.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const SizedBox(height: 16),
                          // Premium Social Login Buttons
                          _buildSocialButton(
                            label: "Continue with Google",
                            icon: Icons.g_mobiledata_rounded,
                            onPressed: _isLoading
                                ? null
                                : () async {
                                    final bottomPadding = MediaQuery.of(context).padding.bottom;
                                    setState(() => _isLoading = true);
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    final error = await context
                                        .read<AppState>()
                                        .signInWithGoogle();
                                    if (mounted && error != null) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(error),
                                          backgroundColor: Colors.redAccent,
                                          behavior: SnackBarBehavior.floating,
                                          margin: EdgeInsets.only(
                                            left: 16, 
                                            right: 16, 
                                            bottom: 16 + bottomPadding,
                                          ),
                                        ),
                                      );
                                    }
                                    if (mounted) {
                                      setState(() => _isLoading = false);
                                    }
                                  },
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            isLoading: _isLoading,
                          ),
                          const SizedBox(height: 12),
                          _buildSocialButton(
                            label: "Continue with Apple",
                            icon: Icons.apple,
                            onPressed: _isLoading
                                ? null
                                : () async {
                                    final bottomPadding = MediaQuery.of(context).padding.bottom;
                                    setState(() => _isLoading = true);
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    final error = await context
                                        .read<AppState>()
                                        .signInWithApple();
                                    if (mounted && error != null) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(error),
                                          backgroundColor: Colors.redAccent,
                                          behavior: SnackBarBehavior.floating,
                                          margin: EdgeInsets.only(
                                            left: 16, 
                                            right: 16, 
                                            bottom: 16 + bottomPadding,
                                          ),
                                        ),
                                      );
                                    }
                                    if (mounted) {
                                      setState(() => _isLoading = false);
                                    }
                                  },
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            isLoading: _isLoading,
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton.icon(
                              onPressed: _isLoading
                                  ? null
                                  : () async {
                                      final bottomPadding = MediaQuery.of(context).padding.bottom;
                                      setState(() => _isLoading = true);
                                      final messenger = ScaffoldMessenger.of(
                                        context,
                                      );
                                      final error = await context
                                          .read<AppState>()
                                          .signInAnonymously();
                                      if (mounted && error != null) {
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(error),
                                            backgroundColor: Colors.redAccent,
                                            behavior: SnackBarBehavior.floating,
                                            margin: EdgeInsets.only(
                                              left: 16, 
                                              right: 16, 
                                              bottom: 16 + bottomPadding,
                                            ),
                                            duration: Duration(seconds: error.length > 50 ? 5 : 3),
                                          ),
                                        );
                                      }
                                      if (mounted) {
                                        setState(() => _isLoading = false);
                                      }
                                    },
                              icon: const Icon(
                                Icons.person_outline_rounded,
                                size: 20,
                              ),
                              label: const Text(
                                "Continue as Guest",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: colorScheme.onSurfaceVariant,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool? isPasswordVisible,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
    Iterable<String>? autofillHints,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      obscureText: isPassword && !(isPasswordVisible ?? false),
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      textInputAction: textInputAction ?? TextInputAction.next,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 22),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  (isPasswordVisible ?? false)
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 22,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        floatingLabelStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required Color backgroundColor,
    required Color foregroundColor,
    required bool isLoading,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 28),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 0.2,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: backgroundColor == Colors.white
                ? BorderSide(color: Colors.grey.shade300)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
