import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_worker/bloc/theme_bloc.dart';

class ShiftDetails3rdCard extends StatefulWidget {
  final String title;
  final String subtitle;

  const ShiftDetails3rdCard({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  State<ShiftDetails3rdCard> createState() => _ShiftDetails3rdCardState();
}

class _ShiftDetails3rdCardState extends State<ShiftDetails3rdCard> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeMode>(
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: <Widget>[
              Expanded(
                flex: 1,
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Text(
                  widget.subtitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: colorScheme.secondary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
