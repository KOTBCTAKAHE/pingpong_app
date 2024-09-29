import 'package:flutter/material.dart';

typedef DialogOptionBuilder<T> = Map<String, T?> Function();
typedef OptionButtonBuilder<T> = Widget Function(BuildContext context, String option, T? value);

Future<T?> showGenericDialog<T>({
  required BuildContext context,
  required String title,
  required Widget content, // Изменяем тип content на Widget для большей гибкости
  required DialogOptionBuilder<T> optionsBuilder,
  OptionButtonBuilder<T>? optionButtonBuilder, // Добавляем этот параметр
}) {
  final options = optionsBuilder();
  return showDialog<T>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: content,
        actions: options.keys.map((optionTitle) {
          final value = options[optionTitle];

          // Используем кастомный билд для кнопок, если он предоставлен
          if (optionButtonBuilder != null) {
            return optionButtonBuilder(context, optionTitle, value);
          }

          // Стандартная кнопка, если кастомный билд не предоставлен
          return TextButton(
            onPressed: () {
              Navigator.of(context).pop(value);
            },
            child: Text(optionTitle),
          );
        }).toList(),
      );
    },
  );
}
