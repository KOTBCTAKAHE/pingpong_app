import 'package:dio/dio.dart';

final baseOptions = BaseOptions(
  sendTimeout: 30 * 1000,
);

final localOptions = baseOptions.copyWith(
  baseUrl: "https://github.com/KOTBCTAKAHE/pinging-server/raw/main/data",
);

final backupOptions = baseOptions.copyWith(
  baseUrl: "https://raw.gitmirror.com/KOTBCTAKAHE/pinging-server/main/data",
);

class ApiClient {
  late final Dio dio;
  late final Dio backupDio;

  ApiClient._sharedInstance()
      : dio = Dio(localOptions),
        backupDio = Dio(backupOptions);

  static final ApiClient _shared = ApiClient._sharedInstance();
  factory ApiClient() => _shared;
}

class ApiLoader {
  final String path;
  late Future<Response> Function() loader;

  ApiLoader({
    required this.path,
    required Future<Response> Function(String path) loader,
  }) {
    this.loader = () => _attemptLoad(loader, path);
  }

  Future<dynamic> dataLoader() => loader().then((res) => res.data);

  Future<Response> _attemptLoad(
      Future<Response> Function(String path) loader, String path) async {
    try {
      // Пытаемся загрузить данные с основного URL
      return await loader(path);
    } catch (e) {
      // Если произошла ошибка, пытаемся загрузить с резервного URL
      print('Основной запрос не удался, пробуем резервный: $e');
      return await ApiClient().backupDio.get(path);
    }
  }
}
