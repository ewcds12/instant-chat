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
      backgroundColor: Colors.transparent,
      body: SizedBox.expand(
        child: LiquidGradientBackground(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                RetroMetrics.spaceLarge,
                RetroMetrics.authContentTopInset,
                RetroMetrics.spaceLarge,
                RetroMetrics.spaceLarge,
              ),
              child: Center(
                child: ConstrainedBox(
                  key: const Key('auth-form'),
                  constraints: const BoxConstraints(
                    maxWidth: RetroMetrics.authFormMaxWidth,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            key: const Key('auth-logo'),
                            width: RetroMetrics.authLogoExtent,
                            height: RetroMetrics.authLogoExtent,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF4F8CFF),
                                  RetroColors.primary,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(13),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.primary.withValues(alpha: 0.18),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.chat_bubble_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _isRegistration
                              ? 'Create an account'
                              : 'Welcome back',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isRegistration
                              ? 'Join Instant Chat to start a conversation.'
                              : 'Sign in to continue to Instant Chat.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 20),
                        _AuthField(
                          key: const Key('auth-id'),
                          controller: _usernameController,
                          hintText: 'ID',
                          icon: Icons.person_outline_rounded,
                          autocorrect: false,
                          textCapitalization: TextCapitalization.none,
                          textInputAction: TextInputAction.next,
                          validator: _validateUsername,
                        ),
                        const SizedBox(height: 10),
                        if (_isRegistration) ...[
                          _AuthField(
                            key: const Key('auth-display-name'),
                            controller: _displayNameController,
                            hintText: 'Display name',
                            icon: Icons.badge_outlined,
                            textInputAction: TextInputAction.next,
                            validator: _validateDisplayName,
                          ),
                          const SizedBox(height: 10),
                        ],
                        _AuthField(
                          key: const Key('auth-password'),
                          controller: _passwordController,
                          hintText: 'Password',
                          icon: Icons.lock_outline_rounded,
                          obscureText: true,
                          onFieldSubmitted: (_) => _submit(auth?.isSubmitting),
                        ),
                        if (auth?.errorMessage case final message?) ...[
                          const SizedBox(height: 10),
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.error),
                          ),
                        ],
                        const SizedBox(height: RetroMetrics.spaceMedium),
                        SizedBox(
                          height: RetroMetrics.authButtonHeight,
                          child: FilledButton(
                            key: const Key('auth-submit'),
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
                        ),
                        const SizedBox(height: 2),
                        TextButton(
                          onPressed: auth?.isSubmitting == true
                              ? null
                              : _toggleMode,
                          child: Text(
                            _isRegistration
                                ? 'Already have an account? Sign in'
                                : 'New to Instant Chat? Create an account',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w600,
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

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.autocorrect = true,
    this.textCapitalization = TextCapitalization.sentences,
    this.textInputAction,
    this.validator,
    this.obscureText = false,
    this.onFieldSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool autocorrect;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final bool obscureText;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autocorrect: autocorrect,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      validator: validator,
      obscureText: obscureText,
      onFieldSubmitted: onFieldSubmitted,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: hintText,
        isDense: true,
        constraints: const BoxConstraints(
          minHeight: RetroMetrics.authFieldHeight,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        prefixIcon: Icon(icon, size: 17),
        prefixIconConstraints: const BoxConstraints(minWidth: 38),
      ),
    );
  }
}
