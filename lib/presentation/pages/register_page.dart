import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:pinging/data/storage/settings.dart';
import 'package:pinging/logic/blocs/app_bloc/app_bloc.dart';
import 'package:pinging/presentation/pages/home_page.dart';

class RegisterPage extends HookWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AppBloc>();
    final authKey = Settings().authKey;
    final controller = useTextEditingController(text: authKey);

    useEffect(() {
      if (authKey.isNotEmpty) {
        _onSubmitted(
          context: context,
          bloc: bloc,
          value: Settings().authKey,
        );
      }

      return;
    }, []);

    return BlocListener<AppBloc, AppState>(
      listenWhen: (_, state) => state is AppStateUnlock,
      listener: (context, state) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const HomePage(),
          ),
        );
      },
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Auth Key"),
            centerTitle: true,
            backgroundColor: Colors.blueAccent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () {
                  _showInfoDialog(context);
                },
              ),
            ],
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueAccent, Colors.lightBlue],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Enter your Auth Key",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: 300,
                        child: TextFormField(
                          onFieldSubmitted: (value) => _onSubmitted(
                            context: context,
                            bloc: bloc,
                            value: controller.text,
                          ),
                          decoration: InputDecoration(
                            hintText: "Enter your key",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          controller: controller,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          primary: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 100,
                            vertical: 15,
                          ),
                        ),
                        onPressed: () => _onSubmitted(
                          context: context,
                          bloc: bloc,
                          value: controller.text,
                        ),
                        child: const Text(
                          "Submit",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          bottomNavigationBar: Container(
            height: kBottomNavigationBarHeight,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueAccent, Colors.lightBlue],
              ),
            ),
            child: Center(
              child: TextButton(
                onPressed: () => _onSubmitted(
                  context: context,
                  bloc: bloc,
                  value: controller.text,
                ),
                child: const Text(
                  "Try",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onSubmitted({
    required BuildContext context,
    required AppBloc bloc,
    required String value,
  }) {
    Settings().authKey = value;
    bloc.add(AppEventAuth(value));
  }

  // Всплывающее окно информации
  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("App Information"),
          content: const Text(
            "This app is a modification by KOTBCTAKAHE.\n"
            "The original app is developed by Atasan Bratan.",
            textAlign: TextAlign.center,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
