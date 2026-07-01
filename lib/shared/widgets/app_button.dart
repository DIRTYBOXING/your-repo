import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Button variant types
enum ButtonVariant { filled, outlined, text }

/// Button size types
enum ButtonSize { small, medium, large }

/// Custom button widget with consistent styling
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool isLoading;
  final IconData? icon;
  final Color? color;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.filled,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.icon,
    this.color,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AppTheme.neonCyan;
    final contentColor = variant == ButtonVariant.filled
        ? AppTheme.primaryBackground
        : buttonColor;

    final EdgeInsets padding = switch (size) {
      ButtonSize.small => const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      ButtonSize.medium => const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 16,
      ),
      ButtonSize.large => const EdgeInsets.symmetric(
        horizontal: 32,
        vertical: 20,
      ),
    };

    final double fontSize = switch (size) {
      ButtonSize.small => 14,
      ButtonSize.medium => 16,
      ButtonSize.large => 18,
    };

    final Widget buttonChild = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(contentColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: fontSize + 4, color: contentColor),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: contentColor,
                ),
              ),
            ],
          );

    Widget button;

    switch (variant) {
      case ButtonVariant.filled:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style:
              ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: contentColor,
                padding: padding,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ).copyWith(
                overlayColor: WidgetStateProperty.all(
                  Colors.white.withValues(alpha: 0.1),
                ),
              ),
          child: buttonChild,
        );
        break;

      case ButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: buttonColor,
            padding: padding,
            side: BorderSide(color: buttonColor, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: buttonChild,
        );
        break;

      case ButtonVariant.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: buttonColor,
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: buttonChild,
        );
        break;
    }

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }

    return button;
  }
}
