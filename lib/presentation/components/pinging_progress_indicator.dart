import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinging/logic/blocs/app_bloc/app_bloc.dart';

class PingingProgressIndicator extends StatelessWidget {
  const PingingProgressIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const nothing = SizedBox();

    return BlocBuilder<AppBloc, AppState>(
      buildWhen: (_, state) => state is AppStateInitialPingingProgress,
      builder: (context, state) {
        int count = 0;

        if (state is AppStateInitialPingingProgress) count = state.chunkCount;

        return Row(
          children: List.generate(
            count,
            (index) => Expanded(
              child: BlocBuilder<AppBloc, AppState>(
                buildWhen: (_, state) =>
                    state is AppStatePingingProgress && state.process == index,
                builder: (context, state) {
                  if (state is! AppStatePingingProgress) return nothing;

                  final progress = state.progress;

                  if (progress.value == 0 || progress.value == 1) {
                    return nothing;
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: progress.value),
                      duration: const Duration(milliseconds: 500),
                      builder: (context, value, _) {
                        return Container(
                          height: 10,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            gradient: LinearGradient(
                              colors: [Colors.green, Colors.lightGreenAccent],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.5),
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: LinearProgressIndicator(
                              value: value,
                              backgroundColor:
                                  Colors.grey.withOpacity(0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.transparent),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
