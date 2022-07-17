import 'package:flutter/material.dart';
import 'package:hashtagable/hashtagable.dart';
import 'package:naegot/constants/colors.constants.dart';

class AppHashTagTextField extends StatefulWidget {
  const AppHashTagTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    this.enabled = true,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 12),
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
  }) : super(key: key);
  final TextEditingController controller;
  final String hintText;
  final bool enabled;
  final EdgeInsets contentPadding;
  final int? maxLength;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;

  @override
  State<AppHashTagTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppHashTagTextField> {
  bool showPassword = true;

  @override
  Widget build(BuildContext context) {
    return HashTagTextField(
      onChanged: widget.onChanged,
      maxLength: widget.maxLength,
      enabled: widget.enabled,
      controller: widget.controller,
      autocorrect: false,
      decoration: InputDecoration(
        // prefixIcon: Padding(padding: EdgeInsets.all(15), child: Text('# ')),
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
      ),
    );
  }
}
