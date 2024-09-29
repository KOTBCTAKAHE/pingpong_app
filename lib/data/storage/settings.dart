import 'package:hive_flutter/hive_flutter.dart';

class Settings {
  factory Settings() => instance;

  static Settings instance = Settings._constructor();

  Settings._constructor() {
    settings = Hive.box("settings");
  }

  late Box settings;

  static Future<void> init() async {
    await Hive.initFlutter(); // Инициализация Hive
    await Hive.openBox("settings");
  }

  // Геттеры и сеттеры для сохранения данных
  String? get deviceId =>
      settings.get("deviceId", defaultValue: null) as String?;

  String get authKey => settings.get("authKey", defaultValue: "") as String;

  int get lastRequestedTime =>
      settings.get("lastRequestedTime", defaultValue: 0) as int;

  List<String> get selectedFiles =>
      (settings.get("selectedFiles", defaultValue: []) as List)
          .map<String>((e) => e)
          .toList();

  bool get alwaysSkipRegistration =>
      settings.get("alwaysSkipRegistration", defaultValue: false) as bool;

  set deviceId(String? value) => settings.put("deviceId", value);
  set authKey(String value) => settings.put("authKey", value);
  set lastRequestedTime(int value) => settings.put("lastRequestedTime", value);
  set selectedFiles(List<String> value) => settings.put("selectedFiles", value);

  // Новый сеттер для alwaysSkipRegistration
  set alwaysSkipRegistration(bool value) =>
      settings.put("alwaysSkipRegistration", value);
}
