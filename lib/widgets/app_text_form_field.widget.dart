import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naegot/constants/colors.constants.dart';

class AppTextFormField extends StatefulWidget {
  const AppTextFormField({
    Key? key,
    required this.controller,
    required this.hintText,
    required this.validator,
    this.onChanged,
    this.obscureText = false,
    this.inputFormatters,
    this.suffix,
    this.keyboardType = TextInputType.text,
    this.onEditingComplete,
    this.maxLines = 1,
    this.enabled = true,
  }) : super(key: key);

  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;
  final String? Function(String?)? onChanged;
  final bool obscureText;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final void Function()? onEditingComplete;
  final int maxLines;
  final bool? enabled;

  @override
  State<AppTextFormField> createState() => _AppTextFormFieldState();
}

class _AppTextFormFieldState extends State<AppTextFormField> {
  bool showPassword = false;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      enabled: widget.enabled,
      maxLines: widget.maxLines,
      inputFormatters: widget.inputFormatters,
      controller: widget.controller,
      obscureText: showPassword ? false : widget.obscureText,
      obscuringCharacter: '*',
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: widget.keyboardType,
      style: const TextStyle(
        color: AppColors.black,
        fontSize: 16.7,
        decoration: TextDecoration.none,
      ),
      onEditingComplete: widget.onEditingComplete,
      decoration: InputDecoration(
          fillColor: Colors.white,
          filled: true,
          contentPadding:
              const EdgeInsets.only(top: 13, bottom: 15, left: 19, right: 19),
          hintText: widget.hintText,
          hintStyle: const TextStyle(color: AppColors.grey, fontSize: 16.7),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(0),
            borderSide:
                BorderSide(width: 1, color: AppColors.grey.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(0),
            borderSide: const BorderSide(width: 1, color: AppColors.primary),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(0),
            borderSide: BorderSide(width: 1, color: Colors.red.shade100),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(0),
            borderSide: const BorderSide(width: 1, color: Colors.red),
          ),
          suffix: widget.suffix ??
              (widget.obscureText
                  ? GestureDetector(
                      onTap: () {
                        showPassword = !showPassword;
                        setState(() {});
                      },
                      child: showPassword
                          ? Image.asset(
                              "assets/images/password_on.png",
                              width: 26,
                              height: 18,
                              color: AppColors.primary,
                            )
                          : Image.asset(
                              "assets/images/password_off.png",
                              width: 26,
                              height: 18,
                              color: AppColors.grey,
                            ),
                    )
                  : null)),
      onChanged: widget.onChanged,
      validator: widget.validator,
    );
  }
}
