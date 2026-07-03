import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class AuthTextField extends StatefulWidget {
  final String labelText;
  final TextEditingController controller;
  final IconData? prefixIcon;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final String? helperText;
  final bool readOnly;
  final VoidCallback? onTap;

  const AuthTextField({
    super.key,
    required this.labelText,
    required this.controller,
    this.prefixIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.helperText,
    this.readOnly = false,
    this.onTap,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscureText = true;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Focus(
      onFocusChange: (hasFocus) {
        setState(() {
          _isFocused = hasFocus;
        });
      },
      child: TextFormField(
        controller: widget.controller,
        obscureText: widget.isPassword ? _obscureText : false,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        readOnly: widget.readOnly,
        onTap: widget.onTap,
        style: AppTextStyles.bodyMedium.copyWith(
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
        decoration: InputDecoration(
          labelText: widget.labelText,
          helperText: widget.helperText,
          prefixIcon: widget.prefixIcon != null 
              ? Icon(
                  widget.prefixIcon, 
                  size: 20, 
                  color: _isFocused 
                      ? AppColors.primary 
                      : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                ) 
              : null,
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 20,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 16),
          filled: true,
          fillColor: isDark ? AppColors.surfaceDark : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight, 
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight, 
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
          labelStyle: TextStyle(
            color: _isFocused 
                ? AppColors.primary 
                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
