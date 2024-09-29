import 'package:flutter/material.dart';
import 'package:pinging/data/error/app_error.dart';

import 'generic_dialog.dart';

Future<void> showAppError({
  required AppError error,
  required BuildContext context,
}) {
  return showGenericDialog<bool>(
    context: context,
    title: '', // Очищаем стандартный заголовок, чтобы кастомизировать его внутри контента
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 30.0,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error.title,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
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
    optionsBuilder: () => {
      'OK': true,
    },
    // Добавляем кастомные стили для кнопок
    optionButtonBuilder: (BuildContext context, String option, dynamic value) {
      return TextButton(
        style: TextButton.styleFrom(
          backgroundColor: Colors.red.shade700,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
        ),
        onPressed: () {
          Navigator.of(context).pop(value);
        },
        child: Text(
          option,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    },
  );
}
