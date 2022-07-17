import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naegot/constants/colors.constants.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    this.textInputType = TextInputType.text,
    this.enabled = true,
    this.maxLines = 1,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 12),
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.inputFormatters,
  }) : super(key: key);
  final TextEditingController controller;
  final String hintText;
  final TextInputType? textInputType;
  final bool enabled;
  final int maxLines;
  final EdgeInsets contentPadding;
  final int? maxLength;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool showPassword = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      inputFormatters: widget.inputFormatters,
      // onSubmitted: widget.onSubmitted,
      validator: widget.validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return "${widget.hintText} 입력해주세요";
            }
            return null;
          },
      onChanged: widget.onChanged,
      maxLength: widget.maxLength,
      maxLines: widget.maxLines,
      enabled: widget.enabled,
      controller: widget.controller,
      autocorrect: false,
      keyboardType: widget.textInputType,
      decoration: InputDecoration(
        filled: true,
        contentPadding: widget.contentPadding,
        hintText: widget.hintText,
        hintStyle: const TextStyle(color: AppColors.hintText, fontSize: 13),
        fillColor: Colors.white,
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.transparent),
        ),
        disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: AppColors.hintBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: AppColors.hintBorder)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}
