import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pinging/data/storage/index.dart';
import 'package:pinging/presentation/app.dart';
import 'package:pinging/presentation/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initStorage();

  // Убрано использование Firebase

  runApp(
    App(
      appRouter: AppRouter(),
    ),
  );
}
