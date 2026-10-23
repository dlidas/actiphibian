import 'package:flutter/material.dart';

class PondMessageState extends StatelessWidget {
  final IconData icon;
  final Widget? illustration;
  final String message;
  final String? details;
  final Widget? action;

  const PondMessageState({
    super.key,
    required this.icon,
    this.illustration,
    required this.message,
    this.details,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            illustration ?? Icon(icon, size: 48, color: colors.primary),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            if (details != null) ...[
              const SizedBox(height: 8),
              Text(details!, textAlign: TextAlign.center),
            ],
            if (action != null) ...[const SizedBox(height: 8), action!],
          ],
        ),
      ),
    );
  }
}
