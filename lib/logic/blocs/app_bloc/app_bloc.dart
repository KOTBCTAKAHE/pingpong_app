import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinging/data/api/github_api.dart';
import 'package:pinging/data/error/app_error.dart';
import 'package:pinging/data/models/file_meta.dart';
import 'package:pinging/data/models/sstp_data.dart';
import 'package:pinging/data/repositories/github_repository.dart';
import 'package:pinging/data/storage/settings.dart';
import 'package:pinging/data/storage/storage.dart';
import 'package:pinging/logic/blocs/app_error_bloc/app_error_bloc.dart';
import 'package:pinging/logic/blocs/loading_bloc/loading_bloc.dart';
import 'package:pinging/logic/utils/device_id.dart';
import 'package:pinging/logic/utils/sstp_pinger.dart';

part 'app_event.dart';
part 'app_state.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  final AppErrorBloc appErrorBloc;
  final LoadingBloc loadingBloc;

  Set<SstpDataModel> allSstps = {};
  StreamSubscription<void>? pingSubscription;
  Completer<void>? cancelCompleter; // Completer для отмены пинга

  AppBloc({
    required this.appErrorBloc,
    required this.loadingBloc,
  }) : super(AppInitial()) {
    on<AppEventLoad>((event, emit) {
      loadSstpsFromCache(emit);
    });

    on<AppEventToggleGhFile>((event, emit) async {
      final found = Settings().selectedFiles.any((e) => e == event.file.name);

      if (found) {
        Settings().selectedFiles = Settings()
            .selectedFiles
            .where((e) => e != event.file.name)
            .toList();
      } else {
        Settings().selectedFiles = [
          ...Settings().selectedFiles,
          event.file.name
        ];
      }

      await loadSstpsFromCache(emit);
      emit(AppStateSstpFileChecked(
        key: event.index,
        value: !found,
      ));
    });

    on<AppEventDeleteGhFile>((event, emit) async {
      final cached = Storage().sstpFiles;
      for (var key in cached.keys) {
        if (cached.get(key)!.name == event.file.name) {
          cached.delete(key);
        }
      }
      emit(AppStateFiles(event.files, cached.values));

      await loadSstpsFromCache(emit);
    });

    on<AppEventDownloadGhFile>((event, emit) async {
      await handleError(() async {
        final sstps = await GithubRepository().getSstpsByFileName(
          event.file.name,
          onReceiveProgress: (count, total) => emit(AppStateUniqueProgress(
            key: event.index,
            progress: ProgressStatus(count, event.file.byteSize),
          )),
        );

        emit(AppStateUniqueProgress(
          key: event.index,
          progress: ProgressStatus.done(),
        ));

        await Storage().lazyBox.put(
          event.file.name,
          jsonEncode(sstps.map((e) => e.toMap()).toList()),
        );
      });

      Storage().putSstpFile(event.file);
      emit(AppStateFiles(event.files, Storage().sstpFiles.values));

      await loadSstpsFromCache(emit);
    });

    on<AppEventDownloadAllGhFiles>((event, emit) async {
      await handleError(() async {
        for (int i = 0; i < event.files.length; i++) {
          final file = event.files[i];
          final sstps = await GithubRepository().getSstpsByFileName(
            file.name,
            onReceiveProgress: (count, total) => emit(AppStateUniqueProgress(
              key: i,
              progress: ProgressStatus(count, file.byteSize),
            )),
          );

          await Storage().lazyBox.put(
            file.name,
            jsonEncode(sstps.map((e) => e.toMap()).toList()),
          );

          emit(AppStateUniqueProgress(
            key: i,
            progress: ProgressStatus.done(),
          ));
          Storage().putSstpFile(file);
        }
      });

      emit(AppStateFiles(event.files, Storage().sstpFiles.values));

      await loadSstpsFromCache(emit);
    });

    on<AppEventLoadFiles>((event, emit) async {
      await handleError(() async {
        try {
          var files = await GithubRepository().getListOfFiles();
          emit(AppStateFiles(files, Storage().sstpFiles.values));

          final files2 = files.toList();

          for (int i = 0; i < files2.length; i++) {
            emit(AppStateSstpFileChecked(
              key: i,
              value: Settings().selectedFiles.any((e) => e == files2[i].name),
            ));
          }

          await loadSstpsFromCache(emit);
        } catch (e, stacktrace) {
          print('Error: $e');
          print('Stacktrace: $stacktrace');
          rethrow;
        }
      });
    });

    on<AppEventAuth>((event, emit) async {
      loadingBloc.add(const StartLoadingEvent());

      await handleError(() async {
        Settings().deviceId =
        await DeviceIdGenerator().getDeviceId(Settings().deviceId);

        await GithubApi()
            .auth(authKey: event.authKey, deviceId: Settings().deviceId!)
            .loader();

        emit(AppStateUnlock());

        Storage()
            .getWorikingSstps()
            .then((sstps) => emit(AppStateSstps(sstps)));
      });

      loadingBloc.add(const StopLoadingEvent());

      await loadSstpsFromCache(emit);
    });

    on<AppEventPing>((event, emit) async {
      if (pingSubscription != null) {
        return;
      }

      cancelCompleter = Completer<void>();

      List<SstpDataModel> sstps = allSstps.toList();
      List<SstpDataModel> working = [];
      int chunkCount = 3;

      emit(AppStateInitialPingingProgress(chunkCount));

      BulkBulkSstpPinger pinger = BulkBulkSstpPinger(
        count: chunkCount,
        sstps: sstps.toList(),
        cancelCompleter: cancelCompleter!,
        onPing: (sstpPinger, progress, index) {
          if (sstpPinger.success) {
            final sstp = sstpPinger.sstp.copyWith(ms: sstpPinger.ms);
            working.add(sstp);
            emit(AppStateSstps(working));
            emit(AppStateAppBarProgress(
              ProgressStatus(working.length, allSstps.length),
            ));
          }

          emit(AppStatePingingProgress(
            process: index,
            progress: progress,
          ));
        },
      );

      pingSubscription = pinger.start().asStream().listen(
            (result) {
          List<SstpDataModel> working = result
              .where((e) => e.success)
              .map((e) => e.sstp.copyWith(ms: e.ms))
              .toList()
              .sortByPingTime();

          emit(AppStateSstps(working));
          emit(AppStateAppBarProgress(
            ProgressStatus(working.length, allSstps.length),
          ));

          Storage().setWorkingSstps(working);
        },
      );

      await pingSubscription!.asFuture();
      pingSubscription = null;
      cancelCompleter = null;
    });

    on<AppEventCancelPing>((event, emit) async {
      if (pingSubscription != null) {
        cancelCompleter?.complete();
        await pingSubscription!.cancel();
        pingSubscription = null;
        cancelCompleter = null;
        emit(AppStatePingCancelled());
      }
    });
  }

  loadSstpsFromCache(Emitter<AppState> emit) async {
    final files = Settings().selectedFiles;

    List<SstpDataModel> sstps = [];

    for (var filename in files) {
      if (!Storage().lazyBox.containsKey(filename)) {
        continue;
      }

      final raw = await Storage().lazyBox.get(filename);

      sstps.addAll(
        (jsonDecode(raw) as Iterable).map((e) => SstpDataModel.fromMap(e)),
      );
    }

    allSstps = sstps.toSet();
    emit(AppStateAppBarProgress(ProgressStatus(-1, allSstps.length)));
  }

  bool isFileSelected(String filename) {
    return Settings().selectedFiles.any((e) => e == filename);
  }

  FutureOr<void> handleError(FutureOr<void> Function() callback) async {
    try {
      await callback();
    } on AppError catch (err) {
      appErrorBloc.add(AppErrorAddEvent(err));
    } on DioError catch (err) {
      if (err.response != null && err.response!.statusCode == 500) {
        appErrorBloc.add(
          AppErrorAddEvent(
            DioLoadError(
              err.response!.data['error'],
            ),
          ),
        );
      } else {
        appErrorBloc.add(const AppErrorAddEvent(LoadError()));
      }
    } catch (_) {
      appErrorBloc.add(const AppErrorAddEvent(LoadError()));
    }
  }
}
