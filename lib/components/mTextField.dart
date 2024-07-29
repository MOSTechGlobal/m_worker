import 'package:flutter/material.dart';

class MTextField extends StatefulWidget {
  final String? labelText;
  final String? hintText;
  final String? initialValue;
  final bool? isPassword;
  final ColorScheme? colorScheme;
  final TextEditingController? controller;
  final Function onChanged;
  const MTextField({super.key, this.labelText, this.hintText, this.initialValue, this.isPassword, this.controller, this.colorScheme, required this.onChanged});

  @override
  State<MTextField> createState() => _MTextFieldState();
}

class _MTextFieldState extends State<MTextField> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      key: widget.key,
      controller: widget.controller,
      obscureText: widget.isPassword ?? false,
      style: TextStyle(
        color: widget.colorScheme!.primary,
        fontSize: 20,
      ),
      decoration: InputDecoration(
        labelText: widget.labelText,
        labelStyle: TextStyle(
          color: widget.colorScheme?.primary,
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: widget.colorScheme!.primary,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: widget.colorScheme!.primary,
          ),
        ),
      ),
      onChanged: (value) {
        widget.onChanged(value);
      },
    );
  }
}
