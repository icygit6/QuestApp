import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../constants/app_colors.dart';

class GradientButton extends StatefulWidget {
  const GradientButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.isLoading = false,
    this.danger = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool danger;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = widget.danger
        ? [Colors.transparent, Colors.transparent]
        : [AppColors.gold, AppColors.goldDark];
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: 100.ms,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(8),
            border: widget.danger
                ? Border.all(color: AppColors.danger)
                : Border.all(color: AppColors.gold),
            boxShadow: widget.danger
                ? null
                : const [
                    BoxShadow(
                      color: AppColors.goldGlow,
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: widget.isLoading ? null : widget.onPressed,
              child: SizedBox(
                height: 52,
                child: Center(
                  child: widget.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(
                                widget.icon,
                                color: widget.danger
                                    ? AppColors.danger
                                    : AppColors.onAccent,
                              ),
                              const SizedBox(width: 10),
                            ],
                            Text(
                              widget.label,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: widget.danger
                                        ? AppColors.danger
                                        : AppColors.onAccent,
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
    );
  }
}
