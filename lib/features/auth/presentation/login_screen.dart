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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
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
          message: next.message ?? 'Login failed.',
          icon: Icons.error_outline_rounded,
          color: AppColors.danger,
        );
      }
    });

    final isLoading = ref.watch(authStateProvider).status == AuthStatus.loading;
    final selectedProvider = ref.watch(authProviderSelectionProvider);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.heroBackground, AppColors.heroGradientEnd],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.shield_moon_rounded,
                    color: AppColors.gold,
                    size: 74,
                  ).animate().scale(curve: Curves.elasticOut),
                  const SizedBox(height: 18),
                  Text(
                    AppStrings.appTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppColors.gold,
                      shadows: const [
                        Shadow(color: AppColors.goldGlow, blurRadius: 26),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.16),
                  const SizedBox(height: 34),
                  _AuthProviderSelector(selected: selectedProvider),
                  const SizedBox(height: 16),
                  RpgTextField(
                    controller: _usernameController,
                    label: selectedProvider == AuthProviderType.backendless
                        ? 'Email or username'
                        : AppStrings.username,
                    icon: Icons.person_rounded,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  RpgTextField(
                    controller: _passwordController,
                    label: AppStrings.password,
                    icon: Icons.lock_rounded,
                    obscureText: true,
                    onSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: 24),
                  GradientButton(
                    label: AppStrings.loginAction,
                    icon: Icons.login_rounded,
                    isLoading: isLoading,
                    onPressed: _login,
                  ),
                  const SizedBox(height: 18),
                  const _OrDivider(),
                  const SizedBox(height: 18),
                  _GoogleSignInButton(
                    isLoading: isLoading,
                    onPressed: _loginWithGoogle,
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child:
                        TextButton(
                          onPressed: () => context.go('/register'),
                          child: const Text(AppStrings.newAdventurer),
                        ).animate().shimmer(
                          duration: 1800.ms,
                          color: AppColors.goldGlow,
                        ),
                  ),
                ],
              ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.12),
            ),
          ),
        ),
      ),
    );
  }

  void _login() {
    FocusScope.of(context).unfocus();
    final provider = ref.read(authProviderSelectionProvider);
    ref
        .read(authStateProvider.notifier)
        .login(provider, _usernameController.text, _passwordController.text);
  }

  void _loginWithGoogle() {
    FocusScope.of(context).unfocus();
    ref.read(authStateProvider.notifier).loginWithGoogle();
  }
}

/// "OR" separator between the credential form and the Google button.
class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: [
        Expanded(child: Divider(color: palette.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: palette.textSecondary),
          ),
        ),
        Expanded(child: Divider(color: palette.border)),
      ],
    );
  }
}

/// Flat, theme-consistent "Sign in with Google" button.
class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      height: 52,
      child: Material(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isLoading ? null : onPressed,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.border),
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.gold,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.g_mobiledata_rounded,
                          size: 32,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Sign in with Google',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: palette.textPrimary),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthProviderSelector extends ConsumerWidget {
  const _AuthProviderSelector({required this.selected});

  final AuthProviderType selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        for (final provider in AuthProviderType.values)
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

class RpgTextField extends StatelessWidget {
  const RpgTextField({
    required this.controller,
    required this.label,
    required this.icon,
    super.key,
    this.obscureText = false,
    this.textInputAction,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.errorText,
    this.valid,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? errorText;
  final bool? valid;

  @override
  Widget build(BuildContext context) {
    final borderColor = valid == null
        ? AppColors.gold
        : valid!
        ? AppColors.easy
        : AppColors.danger;
    return AnimatedContainer(
      duration: 180.ms,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: borderColor.withValues(alpha: 0.12), blurRadius: 18),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        textInputAction: textInputAction,
        keyboardType: keyboardType,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          errorText: errorText,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor),
          ),
        ),
      ),
    );
  }
}
