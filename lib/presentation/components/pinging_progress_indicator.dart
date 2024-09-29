import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinging/logic/blocs/app_bloc/app_bloc.dart';

class PingingProgressIndicator extends StatelessWidget {
  const PingingProgressIndicator({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppBloc, AppState>(
      buildWhen: (_, state) =>
      state is AppStateInitialPingingProgress || state is AppStatePingCancelled || state is AppStatePingingProgress,
      builder: (context, state) {
        if (state is AppStatePingCancelled || state is! AppStateInitialPingingProgress) {
          // Если скан был отменен или скан не начат, индикатор скрывается
          return const SizedBox.shrink();
        }

        int count = 0;

        if (state is AppStateInitialPingingProgress) count = state.chunkCount;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            children: List.generate(
              count,
                  (index) => Expanded(
                child: BlocBuilder<AppBloc, AppState>(
                  buildWhen: (_, state) =>
                  state is AppStatePingingProgress && state.process == index,
                  builder: (context, state) {
                    if (state is! AppStatePingingProgress) {
                      return const SizedBox.shrink();
                    }

                    final progress = state.progress;

                    if (progress.value == 0 || progress.value == 1) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5.0),
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.grey[300],
                          color: Colors.green,
                          minHeight: 10,
                          value: progress.value,
                          semanticsLabel: 'Ping progress indicator',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
