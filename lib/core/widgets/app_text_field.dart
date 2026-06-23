import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppTextField extends StatefulWidget {
  final String labelText;
  final String? hintText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool isPassword;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;

  const AppTextField({
    super.key,
    required this.labelText,
    this.hintText,
    this.controller,
    this.validator,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      obscureText: _obscureText,
      keyboardType: widget.keyboardType,
      enabled: widget.enabled,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon, size: 20) : null,
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20,
                  color: AppColors.textSecondaryLight,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : widget.suffixIcon,
      ),
    );
  }
}
