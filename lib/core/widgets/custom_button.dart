import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final IconData? icon;
  final bool hasGoldenOutline;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.icon,
    this.hasGoldenOutline = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = onPressed != null && !isLoading;

    final primaryStyle = ElevatedButton.styleFrom(
      backgroundColor: AppTheme.primaryGreen,
      foregroundColor: Colors.white,
      disabledBackgroundColor: AppTheme.primaryGreen.withOpacity(0.5),
      disabledForegroundColor: Colors.white.withOpacity(0.8),
      side: hasGoldenOutline ? const BorderSide(color: Color(0xFFC3A575), width: 2) : null,
      shape: hasGoldenOutline 
          ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(26))
          : null,
    );

    final secondaryStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: AppTheme.primaryGreen,
      surfaceTintColor: Colors.white,
      shadowColor: Colors.transparent,
      side: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
      disabledBackgroundColor: Colors.white,
      disabledForegroundColor: AppTheme.primaryGreen.withOpacity(0.5),
    );

    Widget buttonContent = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null && !isLoading) ...[
          Icon(icon, size: 20),
          const SizedBox(width: 8),
        ],
        if (isLoading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                isSecondary ? AppTheme.primaryGreen : Colors.white,
              ),
            ),
          )
        else
          Text(text),
      ],
    );

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: isSecondary ? secondaryStyle : primaryStyle,
        onPressed: isEnabled ? onPressed : null,
        child: buttonContent,
      ),
    );
  }
}
