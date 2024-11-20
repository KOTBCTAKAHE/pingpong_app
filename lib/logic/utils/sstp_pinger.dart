import 'dart:async';
import 'dart:io';

class SstpPinger {
  final Duration timeout;
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
  final List<SstpDataModel> sstps;
  final Duration timeout;
  final Function(SstpPingerResult)? onPing;
  final Completer<void> cancelCompleter;
  final int maxConcurrentPings;

  BulkSstpPinger({
    required this.sstps,
    required this.timeout,
    this.onPing,
    required this.cancelCompleter,
    this.maxConcurrentPings = 5, // Ограничение параллельных задач
  });

  Future<List<SstpPingerResult>> pingAll() async {
    final results = <SstpPingerResult>[];
    final sem = Semaphore(maxConcurrentPings);

    for (var sstp in sstps) {
      if (cancelCompleter.isCompleted) break;

      await sem.acquire();
      Future(() async {
        final result = await SstpPinger(sstp, timeout).ping();
        onPing?.call(result);
        results.add(result);
        sem.release();
      });
    }

    return results;
  }
}

class Semaphore {
  int _count;
  final _queue = <Completer>[];

  Semaphore(this._count);

  Future<void> acquire() async {
    if (_count > 0) {
      _count--;
    } else {
      final completer = Completer<void>();
      _queue.add(completer);
      await completer.future;
    }
  }

  void release() {
    if (_queue.isNotEmpty) {
      _queue.removeAt(0).complete();
    } else {
      _count++;
    }
  }
}

class SstpDataModel {
  final String ip;
  final int port;

  SstpDataModel(this.ip, this.port);
}

class SstpPingerResult {
  final SstpDataModel sstp;
  final bool success;
  final int ping;

  SstpPingerResult(this.sstp, this.success, this.ping);
}
