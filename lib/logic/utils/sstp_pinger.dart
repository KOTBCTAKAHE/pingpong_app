import 'dart:async';
import 'dart:io';

import 'package:pinging/data/models/sstp_data.dart';
import 'package:pinging/data/models/sstp_data_result.dart';

/// Класс для одиночного пинга с точным измерением времени отклика
class SstpPinger {
  final Duration? timeout;
  final SstpDataModel sstp;

  SstpPinger(this.sstp, this.timeout);

  Future<SstpPingerResult> ping() async {
    final stopwatch = Stopwatch()..start();
    bool success = false;

    try {
      // Запускаем соединение и ограничиваем время выполнения
      final socket = await Socket.connect(
        sstp.ip,
        sstp.port,
        timeout: timeout,
      );
      // Фиксируем время сразу после установления соединения
      stopwatch.stop();
      // Закрываем соединение сразу после подключения
      socket.destroy();
      success = true;
    } catch (e) {
      stopwatch.stop();
      // Можно добавить логирование ошибки e для отладки
    }

    return SstpPingerResult(sstp, success, stopwatch.elapsedMilliseconds);
  }
}

/// Класс для массового параллельного пинга с ограничением одновременных запросов
class BulkBulkSstpPinger {
  /// Максимальное число одновременных пингов
  final int maxConcurrent;
  final Duration? timeout;
  final Function(
    SstpPingerResult sstpPinger,
    ProgressStatus progress,
    int index,
  )? onPing;
  final List<SstpDataModel> sstps;
  final Completer<void> cancelCompleter; // Для отмены

  BulkBulkSstpPinger({
    required this.maxConcurrent,
    required this.sstps,
    this.timeout = const Duration(milliseconds: 3000),
    this.onPing,
    required this.cancelCompleter,
  });

  /// Запускает пинг всех серверов с параллельным выполнением
  Future<List<SstpPingerResult>> start() async {
    final results = <SstpPingerResult>[];
    int doneCount = 0;
    // Создаем очередь пингов
    final queue = List<SstpDataModel>.from(sstps);

    // Функция, которая выполняет пинги из очереди до её опустошения
    Future<void> worker(int workerIndex) async {
      while (queue.isNotEmpty) {
        // Проверка на отмену перед началом нового пинга
        if (cancelCompleter.isCompleted) break;
        // Извлекаем сервер из очереди
        final sstp = queue.removeAt(0);
        final result = await SstpPinger(sstp, timeout).ping();
        results.add(result);
        doneCount++;

        // Вызываем callback с информацией о прогрессе
        onPing?.call(result, ProgressStatus(doneCount, sstps.length), workerIndex);
      }
    }

    // Запускаем пул из [maxConcurrent] параллельных задач
    final workers = List.generate(
      maxConcurrent,
      (index) => worker(index),
    );

    await Future.wait(workers);

    return results;
  }
}

/// Статус прогресса пинга
class ProgressStatus {
  final int count;
  final int total;
  final bool done;

  ProgressStatus(this.count, this.total, [this.done = false]);

  factory ProgressStatus.done() => ProgressStatus(0, 0, true);

  double get value => total == 0 ? 0 : count / total;
}
