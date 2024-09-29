import 'package:flutter/material.dart' show BuildContext, AlertDialog, TextButton, Icon, Icons, TextStyle;
import 'package:pinging/data/error/app_error.dart';

import 'generic_dialog.dart';

Future<void> showAppError({
  required AppError error,
  required BuildContext context,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 28.0,
            ),
            const SizedBox(width: 10),
            Text(
              error.title,
              style: TextStyle(
                color: Colors.red,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              error.description,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
            if (error.detailedError != null) ...[
              const SizedBox(height: 12),
              Text(
                'Details:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                error.detailedError!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                  height: 1.4,
                ),
              ),
            ]
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.red,
              primary: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}
