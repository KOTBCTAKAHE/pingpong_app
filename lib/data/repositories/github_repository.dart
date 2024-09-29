import 'package:dio/dio.dart';
import 'package:pinging/data/api/github_api.dart';
import 'package:pinging/data/models/file_meta.dart';
import 'package:pinging/data/models/sstp_data.dart';

import 'dart:convert'; // Не забудьте импортировать этот пакет

class GithubRepository {
  Future<Iterable<SstpFileMeta>> getListOfFiles() async {
    final apiLoader = GithubApi().getFile("files.json");

    // Получаем данные из API
    final data = await apiLoader.dataLoader();

    // Логируем полученные данные для отладки
    print('Received data: $data');

    // Декодируем строку JSON в список объектов
    final decodedData = json.decode(data);

    // Проверяем, является ли декодированные данные списком (Iterable)
    if (decodedData is Iterable) {
      // Преобразуем каждый элемент списка в SstpFileMeta
      return decodedData.map<SstpFileMeta>((e) => SstpFileMeta.fromMap(e));
    } else {
      // Если данные не являются списком, выбрасываем ошибку
      throw TypeError();
    }
  }

  Future<Iterable<SstpDataModel>> getSstpsByFileName(
      String file, {
        ProgressCallback? onReceiveProgress,
      }) async {
    final apiLoader = GithubApi().getFile(
      file,
      onReceiveProgress: onReceiveProgress,
    );

    // Получаем данные из API
    final data = await apiLoader.dataLoader();

    // Логируем данные для отладки
    print('Received data for file $file: $data');

    // Декодируем строку JSON в список объектов
    final decodedData = json.decode(data);

    // Проверяем, является ли декодированные данные списком (Iterable)
    if (decodedData is Iterable) {
      // Преобразуем каждый элемент списка в SstpDataModel
      return decodedData.map<SstpDataModel>((e) => SstpDataModel.fromMap(e));
    } else {
      // Если данные не являются списком, выбрасываем ошибку
      throw TypeError();
    }
  }
}

