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
    final alwaysSkip = useState(Settings().alwaysSkipRegistration);

    useEffect(() {
      if (alwaysSkip.value) {
        _navigateToHome(context);
      } else if (authKey.isNotEmpty) {
        _onSubmitted(context: context, bloc: bloc, value: authKey);
      }
      return;
    }, []);

    return BlocListener<AppBloc, AppState>(
      listenWhen: (_, state) => state is AppStateUnlock,
      listener: (context, state) {
        _navigateToHome(context);
      },
      child: SafeArea(
        child: Scaffold(
          appBar: _buildAppBar(context),
          body: Container(
            decoration: _buildGradientBackground(),
            child: Center(
              child: _buildCard(context, controller, bloc, alwaysSkip),
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text("Auth Key"),
      centerTitle: true,
      backgroundColor: Colors.indigo,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () => _showInfoDialog(context),
        ),
      ],
    );
  }

  BoxDecoration _buildGradientBackground() {
    return const BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.indigo, Colors.blueAccent],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
  }

  Widget _buildCard(BuildContext context, TextEditingController controller, AppBloc bloc, ValueNotifier<bool> alwaysSkip) {
    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
      shadowColor: Colors.black.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Enter your Auth Key",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 24),
            _buildAuthKeyField(controller),
            const SizedBox(height: 30),
            _buildSubmitButton(context, controller, bloc),
            const SizedBox(height: 20),
            _buildSkipButton(context),
            const SizedBox(height: 20),
            _buildAlwaysSkipCheckbox(alwaysSkip),
          ],
        ),
      ),
    );
  }

  TextFormField _buildAuthKeyField(TextEditingController controller) {
    return SizedBox(
      width: 300,
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          hintText: "Enter your key",
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: Colors.indigo.shade200,
              width: 2,
            ),
          ),
        ),
        onFieldSubmitted: (value) {
          _onSubmitted(context: context, bloc: context.read<AppBloc>(), value: controller.text);
        },
      ),
    );
  }

  ElevatedButton _buildSubmitButton(BuildContext context, TextEditingController controller, AppBloc bloc) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.indigo,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 110, vertical: 18),
      ),
      onPressed: () => _onSubmitted(context: context, bloc: bloc, value: controller.text),
      child: const Text(
        "Submit",
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  ElevatedButton _buildSkipButton(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade300,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 90, vertical: 18),
      ),
      onPressed: () => _navigateToHome(context),
      child: const Text(
        "Skip Registration",
        style: TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.bold),
      ),
    );
  }

  Row _buildAlwaysSkipCheckbox(ValueNotifier<bool> alwaysSkip) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Checkbox(
          value: alwaysSkip.value,
          onChanged: (value) {
            alwaysSkip.value = value ?? false;
            Settings().alwaysSkipRegistration = alwaysSkip.value;
          },
          activeColor: Colors.indigo,
        ),
        const Text(
          "Always skip registration",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.indigo),
        ),
      ],
    );
  }

  void _navigateToHome(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomePage()),
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

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "App Information",
            style: TextStyle(
              color: Colors.indigo,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            "This app is a modification by KOTBCTAKAHE.\n"
            "The original app is developed by Atasan Bratan.",
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              child: const Text("OK", style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}
