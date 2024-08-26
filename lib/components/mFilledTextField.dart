import 'package:flutter/material.dart';

class MFilledtextfield extends StatefulWidget {
  final String? labelText;
  final String? hintText;
  final String? initialValue;
  final bool? isPassword;
  final bool? multiLine;
  final ColorScheme? colorScheme;
  final TextEditingController? controller;
  final bool? isValid;
  final Function onChanged;
  const MFilledtextfield(
      {super.key,
      this.labelText,
      this.hintText,
      this.initialValue,
      this.isPassword,
      this.controller,
      this.colorScheme,
      this.multiLine,
      required this.onChanged,
      this.isValid});

  @override
  State<MFilledtextfield> createState() => _MTextFieldState();
}

class _MTextFieldState extends State<MFilledtextfield> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      key: widget.key,
      controller: widget.controller,
      obscureText: widget.isPassword ?? false,
      style: TextStyle(
        color: widget.colorScheme!.primary,
        fontSize: 18,
      ),
      maxLines: widget.multiLine ?? false ? 3 : 1,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        hintStyle: TextStyle(
          color: widget.colorScheme?.secondary,
          fontSize: 16,
          fontStyle: FontStyle.italic,
        ),
        labelStyle: TextStyle(
          color: widget.colorScheme?.secondary,
        ),
        fillColor: widget.colorScheme?.secondaryContainer,
        filled: true,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: widget.isValid ?? true ? Colors.transparent : Colors.red,
          ),
        ),
        errorText: widget.isValid ?? true ? null : 'Required',
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: widget.isValid ?? true ? Colors.transparent : Colors.red,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: widget.isValid ?? true ? Colors.transparent : Colors.red,
          ),
        ),
      ),
      onChanged: (value) {
        widget.onChanged(value);
      },
    );
  }
}
