import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/core/theme/glass.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegistration = false;

  @override
  void dispose() {
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
      body: LiquidGradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(RetroMetrics.spaceLarge),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: RetroMetrics.maxAuthPanelWidth,
                ),
                child: GlassPanel(
                  padding: const EdgeInsets.all(26),
                  tint: RetroColors.glassStrong,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF4F8CFF),
                                  RetroColors.primary,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.primary.withValues(alpha: 0.25),
                                  blurRadius: 22,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.chat_bubble_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
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
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(labelText: 'ID'),
                          autocorrect: false,
                          textCapitalization: TextCapitalization.none,
                          textInputAction: TextInputAction.next,
                          validator: _validateUsername,
                        ),
                        const SizedBox(height: RetroMetrics.spaceMedium),
                        if (_isRegistration) ...[
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
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                          ),
                          obscureText: true,
                          onFieldSubmitted: (_) => _submit(auth?.isSubmitting),
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
        username: _usernameController.text,
        displayName: _displayNameController.text,
        password: _passwordController.text,
      );
      return;
    }
    await controller.login(
      username: _usernameController.text,
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
}
