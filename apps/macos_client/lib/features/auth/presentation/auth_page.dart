import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegistration = false;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _displayNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider).value;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(RetroMetrics.spaceLarge),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: RetroMetrics.maxAuthPanelWidth,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border.all(
                    color: colors.outlineVariant,
                    width: RetroMetrics.border,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow,
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(RetroMetrics.spaceLarge),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          child: const Icon(
                            Icons.chat_bubble_rounded,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: RetroMetrics.spaceMedium),
                        Text(
                          _isRegistration
                              ? 'Create an account'
                              : 'Welcome back',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: RetroMetrics.spaceSmall),
                        Text(
                          _isRegistration
                              ? 'Join Instant Chat to start a conversation.'
                              : 'Sign in to continue to Instant Chat.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: RetroMetrics.spaceLarge),
                        if (_isRegistration) ...[
                          TextFormField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                            ),
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            textInputAction: TextInputAction.next,
                            validator: _validateUsername,
                          ),
                          const SizedBox(height: RetroMetrics.spaceMedium),
                          TextFormField(
                            controller: _displayNameController,
                            decoration: const InputDecoration(
                              labelText: 'Display name',
                            ),
                            textInputAction: TextInputAction.next,
                            validator: _validateDisplayName,
                          ),
                          const SizedBox(height: RetroMetrics.spaceMedium),
                        ],
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email address',
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: RetroMetrics.spaceMedium),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                          ),
                          obscureText: true,
                          onFieldSubmitted: (_) => _submit(auth?.isSubmitting),
                          validator: _validatePassword,
                        ),
                        const SizedBox(height: RetroMetrics.spaceMedium),
                        if (auth?.errorMessage case final message?)
                          Text(message, style: TextStyle(color: colors.error)),
                        const SizedBox(height: RetroMetrics.spaceMedium),
                        FilledButton(
                          onPressed: auth?.isSubmitting == true
                              ? null
                              : () => _submit(false),
                          child: Text(
                            auth?.isSubmitting == true
                                ? 'Please wait…'
                                : _isRegistration
                                ? 'Create account'
                                : 'Sign in',
                          ),
                        ),
                        const SizedBox(height: RetroMetrics.spaceSmall),
                        TextButton(
                          onPressed: auth?.isSubmitting == true
                              ? null
                              : _toggleMode,
                          child: Text(
                            _isRegistration
                                ? 'Already have an account? Sign in'
                                : 'New to Instant Chat? Create an account',
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
      ),
    );
  }

  void _toggleMode() {
    ref.read(authControllerProvider.notifier).clearError();
    setState(() => _isRegistration = !_isRegistration);
    _formKey.currentState?.reset();
  }

  Future<void> _submit(bool? isSubmitting) async {
    if (isSubmitting == true || _formKey.currentState?.validate() != true) {
      return;
    }
    final controller = ref.read(authControllerProvider.notifier);
    if (_isRegistration) {
      await controller.register(
        email: _emailController.text,
        username: _usernameController.text,
        displayName: _displayNameController.text,
        password: _passwordController.text,
      );
      return;
    }
    await controller.login(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  String? _validateDisplayName(String? value) {
    final length = value?.trim().length ?? 0;
    if (length < 2 || length > 80) {
      return 'Use 2 to 80 characters.';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    final username = value?.trim().toLowerCase() ?? '';
    if (!RegExp(r'^[a-z][a-z0-9_]{2,31}$').hasMatch(username)) {
      return 'Use 3 to 32 lowercase letters, numbers, or underscores.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (!email.contains('@') || email.length > 254) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final length = value?.length ?? 0;
    if (length < 12 || length > 128) {
      return 'Use 12 to 128 characters.';
    }
    return null;
  }
}
