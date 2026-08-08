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
                        const SizedBox(height: 8),
                        if (_isRegistration) ...[
                          _AuthField(
                            key: const Key('auth-display-name'),
                            controller: _displayNameController,
                            hintText: 'Display name',
                            icon: Icons.badge_outlined,
                            textInputAction: TextInputAction.next,
                            validator: _validateDisplayName,
                          ),
                          const SizedBox(height: 8),
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
                          const SizedBox(height: 8),
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.error),
                          ),
                        ],
                        const SizedBox(height: 12),
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
                        SizedBox(
                          height: 32,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              overlayColor: Colors.transparent,
                            ),
                            onPressed: auth?.isSubmitting == true
                                ? null
                                : _toggleMode,
                            child: Text(
                              _isRegistration
                                  ? 'Back to sign in'
                                  : 'Create an account',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w600,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        prefixIcon: Icon(icon, size: 16),
        prefixIconConstraints: const BoxConstraints(minWidth: 36),
      ),
    );
  }
}
