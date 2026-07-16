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
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegistration = false;

  @override
  void dispose() {
    _emailController.dispose();
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
                    color: colors.onSurface,
                    width: RetroMetrics.border,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.onSurface,
                      offset: const Offset(
                        RetroMetrics.spaceSmall,
                        RetroMetrics.spaceSmall,
                      ),
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
                        Text(
                          'INSTANT CHAT // ${_isRegistration ? 'REGISTER' : 'SIGN IN'}',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: RetroMetrics.spaceSmall),
                        const Text('SECURE MACOS COMMUNICATION TERMINAL'),
                        const SizedBox(height: RetroMetrics.spaceLarge),
                        if (_isRegistration) ...[
                          TextFormField(
                            controller: _displayNameController,
                            decoration: const InputDecoration(
                              labelText: 'DISPLAY NAME',
                            ),
                            textInputAction: TextInputAction.next,
                            validator: _validateDisplayName,
                          ),
                          const SizedBox(height: RetroMetrics.spaceMedium),
                        ],
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'EMAIL ADDRESS',
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: RetroMetrics.spaceMedium),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'PASSWORD',
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
                                ? 'TRANSMITTING...'
                                : _isRegistration
                                ? 'CREATE ACCOUNT'
                                : 'SIGN IN',
                          ),
                        ),
                        const SizedBox(height: RetroMetrics.spaceSmall),
                        TextButton(
                          onPressed: auth?.isSubmitting == true
                              ? null
                              : _toggleMode,
                          child: Text(
                            _isRegistration
                                ? 'USE AN EXISTING ACCOUNT'
                                : 'CREATE A NEW ACCOUNT',
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
