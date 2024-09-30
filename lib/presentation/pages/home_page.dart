import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:pinging/data/storage/storage.dart';
import 'package:pinging/logic/blocs/app_bloc/app_bloc.dart';
import 'package:pinging/logic/utils/sstp_pinger.dart';
import 'package:pinging/presentation/components/cards/sstp_address_card.dart';
import 'package:pinging/presentation/components/pinging_progress_indicator.dart';
import 'package:pinging/presentation/pages/register_page.dart';
import 'package:pinging/data/models/sstp_data.dart';

class HomePage extends HookWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scrollController1 = useScrollController();
    final isPinging = useState(false);
    final isSorted = useState(false);
    final loading = useState(false); // Исправлено: добавлено состояние для загрузки

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.key_outlined),
              tooltip: 'Auth key',
              onPressed: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (context) => const RegisterPage(),
                ));
              },
            ),
            IconButton(
              icon: Icon(
                isSorted.value ? Icons.sort : Icons.sort_by_alpha,
                color: isSorted.value ? Colors.green : Colors.white,
              ),
              tooltip: 'Sort by Ping',
              onPressed: () {
                isSorted.value = !isSorted.value;
                showSnackbar(context, isSorted.value ? "Sorted by ping" : "Unsorted");
              },
            ),
          ],
          title: BlocBuilder<AppBloc, AppState>(
            buildWhen: (_, state) => state is AppStateAppBarProgress,
            builder: (context, state) {
              String text = "Pinging App ";

              if (state is AppStateAppBarProgress) {
                text += "${state.progress.count}/${state.progress.total}";
              }

              return Text(
                text,
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: kBottomNavigationBarHeight,
              child: Container(
                color: Theme.of(context).colorScheme.surface,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: IconButton(
                        icon: const Icon(Icons.download),
                        onPressed: () {
                          selectFiles(context);
                        },
                        color: Colors.white,
                        tooltip: "Get all",
                      ),
                    ),
                    Expanded(
                      child: isPinging.value
                          ? IconButton(
                              icon: const Icon(Icons.cancel),
                              onPressed: () {
                                context.read<AppBloc>().add(AppEventCancelPing());
                                isPinging.value = false;
                                showSnackbar(context, "Ping canceled", color: Colors.red);
                              },
                              color: Colors.red,
                              tooltip: 'Cancel Ping',
                            )
                          : IconButton(
                              icon: const Icon(Icons.upload),
                              onPressed: () {
                                context.read<AppBloc>().add(AppEventPing());
                                isPinging.value = true;
                                showSnackbar(context, "Ping started");
                              },
                              color: Colors.green,
                              tooltip: 'Ping all',
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const PingingProgressIndicator(),
          ],
        ),
        body: buildBody(scrollController1, isSorted.value, loading),
      ),
    );
  }

  Widget buildBody(ScrollController scrollController1, bool isSorted, ValueNotifier<bool> loading) {
    return BlocBuilder<AppBloc, AppState>(
      buildWhen: (_, state) => state is AppStateSstps,
      builder: (context, state) {
        if (state is! AppStateSstps) return const SizedBox();

        var sstps = state.sstps.toList();

        if (isSorted) {
          sstps.sortByPingTime();
        }

        return Scrollbar(
          controller: scrollController1,
          thumbVisibility: true, // Исправлено: заменён устаревший параметр
          child: AnimatedList(
            key: GlobalKey<AnimatedListState>(),
            initialItemCount: sstps.length,
            itemBuilder: (context, index, animation) {
              return FadeTransition(
                opacity: animation,
                child: SstpAddressCard(sstp: sstps[index]),
              );
            },
            controller: scrollController1,
            shrinkWrap: true,
          ),
        );
      },
    );
  }

  selectFiles(BuildContext context) {
    final bloc = context.read<AppBloc>();

    bloc.add(AppEventLoadFiles());

    return showDialog<String>(
      context: context,
      builder: (context) {
        return BlocBuilder<AppBloc, AppState>(
          buildWhen: (_, state) => state is AppStateFiles,
          builder: (context, state) {
            Widget child = const Center(child: CircularProgressIndicator());

            if (state is AppStateFiles) {
              final files = state.files.toList();
              final cached = state.cached.toList();

              child = ListView.builder(
                shrinkWrap: true,
                itemCount: files.length,
                itemBuilder: (context, index) {
                  final file = files[index];

                  Icon icon = const Icon(
                    Icons.download_rounded,
                    color: Colors.green,
                  );

                  if (cached.any((e) => e.name == file.name)) {
                    icon = const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                    );

                    final cachedFile =
                        cached.firstWhere((e) => e.name == file.name);

                    if (file.byteSize != cachedFile.byteSize) {
                      icon = const Icon(
                        Icons.refresh_rounded,
                        color: Colors.green,
                      );
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Material(
                      elevation: 5,
                      child: BlocBuilder<AppBloc, AppState>(
                        buildWhen: (_, state) =>
                            state is AppStateSstpFileChecked && state.key == index,
                        builder: (context, state) {
                          bool checked = bloc.isFileSelected(file.name);

                          return CheckboxListTile(
                            value: checked,
                            onChanged: (_) {
                              bloc.add(AppEventToggleGhFile(files, index));
                              showSnackbar(context, checked ? "File deselected" : "File selected");
                            },
                            title: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Text(
                                "${file.name} - ${file.sstpCount}",
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                BlocBuilder<AppBloc, AppState>(
                                  buildWhen: (_, state) =>
                                      state is AppStateUniqueProgress &&
                                      state.key == index,
                                  builder: (context, state) {
                                    double value = 0;
                                    ProgressStatus? progress;
                                    String text = "Empty";

                                    if (Storage().sstpFiles.values.any(
                                        (e) => e.name == files[index].name)) {
                                      value = 1;
                                      text = "Done";
                                    }

                                    if (state is AppStateUniqueProgress) {
                                      progress = state.progress;

                                      if (progress.total != 0) {
                                        value = progress.count / progress.total;
                                      }

                                      text =
                                          "${progress.count}/${progress.total}";

                                      if (progress.done) {
                                        text = "Done";
                                      }
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4.0,
                                      ),
                                      child: Stack(
                                        children: [
                                          LinearProgressIndicator(
                                            color: Colors.green,
                                            value: value,
                                            minHeight: 15,
                                          ),
                                          Center(
                                            child: Text(
                                              text,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall!
                                                  .copyWith(
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        bloc.add(
                                          AppEventDeleteGhFile(files, index),
                                        );
                                        showSnackbar(context, "File deleted", color: Colors.red);
                                      },
                                      icon: const Icon(
                                        Icons.delete_rounded,
                                        color: Colors.red,
                                      ),
                                    ),
                                    const SizedBox(width: 8.0),
                                    IconButton(
                                      onPressed: () {
                                        loading.value = true; // Исправлено: установка загрузки
                                        bloc.add(AppEventDownloadGhFile(files, index));
                                        loading.value = false; // Исправлено: сброс загрузки
                                        showSnackbar(context, "File downloaded");
                                      },
                                      icon: loading.value
                                          ? const CircularProgressIndicator()
                                          : icon,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            }
            final size = MediaQuery.of(context).size;
            return AlertDialog(
              title: const Text("Search from files:"),
              content: SizedBox(
                width: size.width > 400 ? 400 : size.width,
                child: child,
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void showSnackbar(BuildContext context, String message, {Color color = Colors.green}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }
}
