import 'package:flutter/foundation.dart' show immutable;

@immutable
abstract class AppError {
  final String title;
  final String description;
  final String? detailedError; // Новое поле для точной информации об ошибке

  const AppError({
    required this.title,
    required this.description,
    this.detailedError, // Опциональное детализированное описание
  });
}

@immutable
class LoadError extends AppError {
  const LoadError([String? detailedError])
      : super(
          title: "Load error",
          description: "Maybe internet connection error",
          detailedError: detailedError, // Передаем детализированную ошибку
        );
}

@immutable
class DioLoadError extends AppError {
  const DioLoadError(String description, [String? detailedError])
      : super(
          title: "Load error",
          description: description,
          detailedError: detailedError, // Передаем детализированную ошибку
        );
}

@immutable
class DeviceIdAccessError extends AppError {
  const DeviceIdAccessError([String? detailedError])
      : super(
          title: "Access error",
          description: "Could not get device id",
          detailedError: detailedError, // Передаем детализированную ошибку
        );
}
