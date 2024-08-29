import 'package:flutter/material.dart';

Color getColor(String status) {
  switch (status) {
    case 'P':
      return Colors.yellow;
    case 'A':
      return Colors.green;
    case 'R':
      return Colors.red;
    case 'U':
    default:
      return Colors.white;
  }
}
