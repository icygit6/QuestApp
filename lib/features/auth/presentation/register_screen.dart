import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/quest_snack_bar.dart';
import '../domain/auth_provider_type.dart';
import 'auth_provider.dart';
import 'login_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _touched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = ref.read(authProviderSelectionProvider);
      if (!provider.supportsRegistration) {
        ref.read(authProviderSelectionProvider.notifier).state =
            AuthProviderType.backendless;
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        context.go('/quests');
      }
      if (next.status == AuthStatus.error) {
        showQuestSnackBar(
          context,
          message: next.message ?? 'Registration failed.',
          icon: Icons.error_outline_rounded,
          color: AppColors.danger,
        );
      }
    });

    final isLoading = ref.watch(authStateProvider).status == AuthStatus.loading;
    final selectedProvider = ref.watch(authProviderSelectionProvider);
    final usernameValid = _usernameController.text.trim().length >= 3;
    final emailValid = _emailController.text.contains('@');
    final strength = _passwordStrength(_passwordController.text);
    final passwordValid = strength >= 0.5;
    final confirmValid =
        _confirmController.text == _passwordController.text &&
        _confirmController.text.isNotEmpty;
    final canSubmit =
        usernameValid &&
        emailValid &&
        passwordValid &&
        confirmValid &&
        !isLoading;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.heroBackground, AppColors.heroGradientEnd],
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'CREATE CHARACTER',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.displayLarge?.copyWith(color: AppColors.gold),
                ).animate().fadeIn().slideY(begin: 0.16),
                const SizedBox(height: 26),
                _AuthProviderSelector(selected: selectedProvider),
                const SizedBox(height: 16),
                RpgTextField(
                  controller: _usernameController,
                  label: AppStrings.username,
                  icon: Icons.person_add_alt_1_rounded,
                  valid: _touched ? usernameValid : null,
                  onChanged: (_) => _markTouched(),
                ),
                const SizedBox(height: 14),
                RpgTextField(
                  controller: _emailController,
                  label: AppStrings.email,
                  icon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  valid: _touched ? emailValid : null,
                  onChanged: (_) => _markTouched(),
                ),
                const SizedBox(height: 14),
                RpgTextField(
                  controller: _passwordController,
                  label: AppStrings.password,
                  icon: Icons.lock_rounded,
                  obscureText: true,
                  valid: _touched ? passwordValid : null,
                  onChanged: (_) => _markTouched(),
                ),
                const SizedBox(height: 10),
                _PasswordStrengthMeter(value: strength),
                const SizedBox(height: 14),
                RpgTextField(
                  controller: _confirmController,
                  label: AppStrings.confirmPassword,
                  icon: Icons.verified_user_rounded,
                  obscureText: true,
                  valid: _touched ? confirmValid : null,
                  onChanged: (_) => _markTouched(),
                ),
                const SizedBox(height: 24),
                GradientButton(
                  label: AppStrings.registerAction,
                  icon: Icons.auto_awesome_rounded,
                  isLoading: isLoading,
                  onPressed: canSubmit ? _register : null,
                ),
                const SizedBox(height: 18),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text(AppStrings.existingAdventurer),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.12),
          ),
        ),
      ),
    );
  }

  void _markTouched() {
    setState(() => _touched = true);
  }

  void _register() {
    FocusScope.of(context).unfocus();
    final provider = ref.read(authProviderSelectionProvider);
    ref
        .read(authStateProvider.notifier)
        .register(
          provider: provider,
          username: _usernameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
  }

  double _passwordStrength(String password) {
    var score = 0;
    if (password.length >= 8) {
      score++;
    }
    if (RegExp('[A-Z]').hasMatch(password)) {
      score++;
    }
    if (RegExp('[0-9]').hasMatch(password)) {
      score++;
    }
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      score++;
    }
    return (score / 4).clamp(0, 1);
  }
}

class _AuthProviderSelector extends ConsumerWidget {
  const _AuthProviderSelector({required this.selected});

  final AuthProviderType selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providers = AuthProviderType.values
        .where((provider) => provider.supportsRegistration)
        .toList(growable: false);
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        for (final provider in providers)
          ChoiceChip(
            label: Text(provider.label),
            selected: selected == provider,
            onSelected: (_) =>
                ref.read(authProviderSelectionProvider.notifier).state =
                    provider,
            selectedColor: AppColors.gold,
            backgroundColor: context.palette.surface,
            labelStyle: TextStyle(
              color: selected == provider
                  ? AppColors.onAccent
                  : context.palette.textSecondary,
            ),
            side: BorderSide(color: context.palette.border),
          ),
      ],
    );
  }
}

class _PasswordStrengthMeter extends StatelessWidget {
  const _PasswordStrengthMeter({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final color = value < 0.5
        ? AppColors.danger
        : value < 0.75
        ? AppColors.medium
        : AppColors.easy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: value),
            duration: 240.ms,
            builder: (context, animated, _) {
              return LinearProgressIndicator(
                value: animated,
                minHeight: 8,
                backgroundColor: context.palette.border,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Password strength',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}
