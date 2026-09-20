import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers.dart';
import '../../widgets/auth/auth_form_field.dart';
import '../../widgets/auth/auth_button.dart';
import '../../widgets/auth/auth_divider.dart';
import '../../widgets/auth/social_login_button.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ref.read(authServiceProvider).signUpWithEmail(
            email: _emailController.text,
            password: _passwordController.text,
            displayName: _displayNameController.text,
          );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (result.hasError) {
          _errorMessage = result.error.toString();
        }
      });
      if (!result.hasError) {
        // Navigate to home (email verification prompt shown upstream if needed).
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Text(
                  'Create Account',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Join Settl to start tracking your expenses',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                AuthFormField(
                  labelText: 'Full Name',
                  hintText: 'Enter your full name',
                  controller: _displayNameController,
                  prefixIcon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthFormField(
                  labelText: 'Email Address',
                  hintText: 'Enter your email',
                  controller: _emailController,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    // Simple email validation
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthFormField(
                  labelText: 'Password',
                  hintText: 'Create a password',
                  controller: _passwordController,
                  prefixIcon: Icons.lock_outline,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.errorContainer.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.errorContainer,
                      ),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                AuthButton(
                  text: 'Sign Up',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _signUp,
                ),
                const SizedBox(height: 24),
                const AuthDivider(),
                const SizedBox(height: 24),
                const SocialLoginButton(
                  provider: 'google',
                  text: 'Continue with Google',
                ),
                const SizedBox(height: 16),
                const SocialLoginButton(
                  provider: 'apple',
                  text: 'Continue with Apple',
                ),
                const SizedBox(height: 32),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(
                    'Already have an account? Sign in',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}