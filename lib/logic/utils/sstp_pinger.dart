import 'dart:async';
import 'dart:io';
import 'package:pinging/data/models/sstp_data.dart';
import 'package:pinging/data/models/sstp_data_result.dart';

class SstpPinger {
  final Duration? timeout;
  final SstpDataModel sstp;

  SstpPinger(this.sstp, this.timeout);

  Future<SstpPingerResult> ping() async {
    final stopwatch = Stopwatch()..start();
    bool success = false;

    try {
      final socket = await Socket.connect(
        sstp.ip,
        sstp.port,
        timeout: timeout,
      );

      socket.destroy();
      success = true;
    } catch (_) {}

    return SstpPingerResult(sstp, success, stopwatch.elapsedMilliseconds);
  }
}

class BulkSstpPinger {
  final Duration? timeout;
  final List<SstpDataModel> sstps;
  final Function(SstpPingerResult sstpPinger)? onPing;
  final Completer<void> cancelCompleter; // Для отмены
  int doneCount = 0;

  BulkSstpPinger({
    required this.sstps,
    this.onPing,
    this.timeout,
    required this.cancelCompleter,
  });

  Future<List<SstpPingerResult>> pingAll() async {
    // Параллельный запуск пингов для всех адресов
    List<Future<SstpPingerResult>> pingers = [];

    for (var sstp in sstps) {
      // Проверка на отмену перед каждым пингом
      if (cancelCompleter.isCompleted) {
        break;
      }

      pingers.add(SstpPinger(sstp, timeout).ping());
    }

    // Ожидаем завершения всех пингов параллельно
    final results = await Future.wait(pingers);

    for (var result in results) {
      onPing?.call(result);
      doneCount++;
    }

    return results;
  }
}

class BulkBulkSstpPinger {
  final int count;
  final Duration? timeout;
  final Function(
      SstpPingerResult sstpPinger,
      ProgressStatus progress,
      int index,
      )? onPing;
  final List<SstpDataModel> sstps;
  final Completer<void> cancelCompleter; // Для отмены

  BulkBulkSstpPinger({
    required this.count,
    required this.sstps,
    this.timeout = const Duration(milliseconds: 3000),
    this.onPing,
    required this.cancelCompleter,
  });

  Future<List<SstpPingerResult>> start() async {
    final chunks = sstps.splitIntoChunks(count);
    final done = List<int>.generate(chunks.length, (_) => 0);

    // Используем Future.wait для выполнения задач параллельно
    List<Future<List<SstpPingerResult>>> futures = [];

    for (int i = 0; i < chunks.length; i++) {
      final sstpsChunk = chunks[i];

      // Проверка на отмену перед запуском новой задачи
      if (cancelCompleter.isCompleted) {
        break;
      }

      futures.add(
        BulkSstpPinger(
          sstps: sstpsChunk,
          timeout: timeout,
          cancelCompleter: cancelCompleter, // Передаем Completer для отмены
          onPing: (sstpPinger) {
            onPing?.call(
              sstpPinger,
              ProgressStatus(++done[i], sstpsChunk.length),
              i,
            );
          },
        ).pingAll(),
      );
    }

    // Ожидаем завершения всех групп пингов
    final list = await Future.wait(futures);

    return list.joinChunks();
  }
}

extension SplitIntoChunks<T> on List<T> {
  List<List<T>> splitIntoChunks(int n) {
    int chunkSize = (length / n).ceil();
    List<List<T>> chunks = [];

    for (var i = 0; i < length; i += chunkSize) {
      chunks.add(sublist(
        i,
        i + chunkSize > length ? length : i + chunkSize,
      ));
    }

    return chunks;
  }
}

extension ChunksJoiner<T> on List<List<T>> {
  List<T> joinChunks() {
    List<T> result = [];

    for (var list in this) {
      result.addAll(list);
    }

    return result;
  }
}

class ProgressStatus {
  final int count;
  final int total;
  final bool done;

  ProgressStatus(this.count, this.total, [this.done = false]);

  factory ProgressStatus.done() => ProgressStatus(0, 0, true);

  double get value => total == 0 ? 0 : count / total;
}
