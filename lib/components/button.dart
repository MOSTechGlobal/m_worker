import 'package:flutter/material.dart';

class MButton extends StatelessWidget {
  final ColorScheme colorScheme;
  final String label;
  final  dynamic onPressed;
  const MButton({super.key, required this.colorScheme, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        fixedSize: const Size(200, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(label, style: TextStyle(color: colorScheme.onPrimary)),
    );
  }
}
