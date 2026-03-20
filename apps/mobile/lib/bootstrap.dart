import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/services/logger_service.dart';
import 'firebase_options.dart';

Future<void> bootstrap({required AppEnvironment environment}) async {
  // Ensures widgets binding is initialized before anything else
  WidgetsFlutterBinding.ensureInitialized();

  // Determine env file and load dotenv BEFORE creating AppConfig
  final envFileName = switch (environment) {
    AppEnvironment.development => '.env.development',
    AppEnvironment.staging => '.env.staging',
    AppEnvironment.production => '.env.production',
  };
  await dotenv.load(fileName: envFileName);

  // Now it's safe to construct AppConfig (reads dotenv.env)
  final config = switch (environment) {
    AppEnvironment.development => AppConfig.development(),
    AppEnvironment.staging => AppConfig.staging(),
    AppEnvironment.production => AppConfig.production(),
  };

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Google Sign In (v7 requires explicit initialization)
  await GoogleSignIn.instance.initialize();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize logger
  LoggerService.init(config: config);

  // Run the app
  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
      ],
      child: const VotioApp(),
    ),
  );
}
