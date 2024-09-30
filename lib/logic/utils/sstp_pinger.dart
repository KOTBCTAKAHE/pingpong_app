import 'dart:async';
import 'dart:io';
import 'dart:isolate';
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
  final Completer<void> cancelCompleter;

  BulkSstpPinger({
    required this.sstps,
    this.onPing,
    this.timeout,
    required this.cancelCompleter,
  });

  Future<List<SstpPingerResult>> pingAll() async {
    List<SstpPingerResult> result = [];

    // Многопоточная обработка
    List<Future<SstpPingerResult>> futures = sstps.map<Future<SstpPingerResult>>((sstp) async {
      if (cancelCompleter.isCompleted) return Future.value();

      final sstpPinger = await SstpPinger(sstp, timeout).ping();
      result.add(sstpPinger);

      onPing?.call(sstpPinger);
      return sstpPinger;
    }).toList();

    await Future.wait(futures);
    return result;
  }
}

class BulkBulkSstpPinger {
  final int count;
  final Duration? timeout;
  final Function(SstpPingerResult sstpPinger, ProgressStatus progress, int index)? onPing;
  final List<SstpDataModel> sstps;
  final Completer<void> cancelCompleter;

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

    List<Future<List<SstpPingerResult>>> futures = [];

    for (int i = 0; i < chunks.length; i++) {
      final sstpsChunk = chunks[i];

      if (cancelCompleter.isCompleted) break;

      futures.add(
        _runIsolateForPing(
          sstpsChunk,
          timeout,
          cancelCompleter,
          (sstpPinger) {
            onPing?.call(
              sstpPinger,
              ProgressStatus(++done[i], sstpsChunk.length),
              i,
            );
          },
        ),
      );
    }

    final list = await Future.wait(futures);

    return list.joinChunks();
  }

  Future<List<SstpPingerResult>> _runIsolateForPing(
      List<SstpDataModel> sstpsChunk,
      Duration? timeout,
      Completer<void> cancelCompleter,
      Function(SstpPingerResult) onPing) async {
    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn(
      _pingIsolateEntry,
      PingIsolateArgs(
        sstpsChunk,
        timeout,
        cancelCompleter,
        receivePort.sendPort,
      ),
    );

    final results = await receivePort.first as List<SstpPingerResult>;
    isolate.kill();
    return results;
  }
}

void _pingIsolateEntry(PingIsolateArgs args) async {
  final results = await BulkSstpPinger(
    sstps: args.sstps,
    timeout: args.timeout,
    cancelCompleter: args.cancelCompleter,
    onPing: (result) {
      args.sendPort.send(result);
    },
  ).pingAll();

  args.sendPort.send(results);
}

class PingIsolateArgs {
  final List<SstpDataModel> sstps;
  final Duration? timeout;
  final Completer<void> cancelCompleter;
  final SendPort sendPort;

  PingIsolateArgs(
    this.sstps,
    this.timeout,
    this.cancelCompleter,
    this.sendPort,
  );
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
