import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/config/development_api_base_url.dart';
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

  final config = switch (environment) {
    AppEnvironment.development => AppConfig.development(
        apiBaseUrl: await resolveDevelopmentApiBaseUrlAsync(),
      ),
    AppEnvironment.staging => AppConfig.staging(),
    AppEnvironment.production => AppConfig.production(),
  };

  // Initialize Firebase
  final webFirebase = _firebaseWebOptionsFromEnvOrDotenv();
  await Firebase.initializeApp(
    options: kIsWeb ? webFirebase : DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Google Sign In (v7 requires explicit initialization).
  // serverClientId is the Web OAuth client ID — required so that
  // authenticate() returns a non-null idToken for Firebase Auth.
  await GoogleSignIn.instance.initialize(
    clientId: _fromDefineOrDotenv('GOOGLE_WEB_CLIENT_ID'),
    serverClientId: _fromDefineOrDotenv(
      'GOOGLE_SERVER_CLIENT_ID',
      defaultValue:
          '1067712342300-ded0vjfiublg9h7c9gkhr645sfutgsuc.apps.googleusercontent.com',
    ),
  );

  // Set preferred orientations
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

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

String _fromDefineOrDotenv(
  String key, {
  String defaultValue = '',
}) {
  final fromEnv = dotenv.env[key]?.trim();
  if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;

  // Must keep these keys as const to be tree-shakeable.
  return switch (key) {
    'GOOGLE_WEB_CLIENT_ID' =>
      const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: ''),
    'GOOGLE_SERVER_CLIENT_ID' => const String.fromEnvironment(
        'GOOGLE_SERVER_CLIENT_ID',
        defaultValue: '',
      ),
    'FIREBASE_WEB_API_KEY' =>
      const String.fromEnvironment('FIREBASE_WEB_API_KEY', defaultValue: ''),
    'FIREBASE_WEB_APP_ID' =>
      const String.fromEnvironment('FIREBASE_WEB_APP_ID', defaultValue: ''),
    'FIREBASE_WEB_MESSAGING_SENDER_ID' => const String.fromEnvironment(
        'FIREBASE_WEB_MESSAGING_SENDER_ID',
        defaultValue: '',
      ),
    'FIREBASE_WEB_PROJECT_ID' =>
      const String.fromEnvironment('FIREBASE_WEB_PROJECT_ID', defaultValue: ''),
    'FIREBASE_WEB_AUTH_DOMAIN' => const String.fromEnvironment(
        'FIREBASE_WEB_AUTH_DOMAIN',
        defaultValue: ''),
    'FIREBASE_WEB_STORAGE_BUCKET' => const String.fromEnvironment(
        'FIREBASE_WEB_STORAGE_BUCKET',
        defaultValue: '',
      ),
    'FIREBASE_WEB_MEASUREMENT_ID' => const String.fromEnvironment(
        'FIREBASE_WEB_MEASUREMENT_ID',
        defaultValue: '',
      ),
    _ => defaultValue,
  }
          .trim()
          .isNotEmpty
      ? switch (key) {
          'GOOGLE_WEB_CLIENT_ID' => const String.fromEnvironment(
              'GOOGLE_WEB_CLIENT_ID',
              defaultValue: '',
            ),
          'GOOGLE_SERVER_CLIENT_ID' => const String.fromEnvironment(
              'GOOGLE_SERVER_CLIENT_ID',
              defaultValue: '',
            ),
          'FIREBASE_WEB_API_KEY' => const String.fromEnvironment(
              'FIREBASE_WEB_API_KEY',
              defaultValue: '',
            ),
          'FIREBASE_WEB_APP_ID' => const String.fromEnvironment(
              'FIREBASE_WEB_APP_ID',
              defaultValue: '',
            ),
          'FIREBASE_WEB_MESSAGING_SENDER_ID' => const String.fromEnvironment(
              'FIREBASE_WEB_MESSAGING_SENDER_ID',
              defaultValue: '',
            ),
          'FIREBASE_WEB_PROJECT_ID' => const String.fromEnvironment(
              'FIREBASE_WEB_PROJECT_ID',
              defaultValue: '',
            ),
          'FIREBASE_WEB_AUTH_DOMAIN' => const String.fromEnvironment(
              'FIREBASE_WEB_AUTH_DOMAIN',
              defaultValue: '',
            ),
          'FIREBASE_WEB_STORAGE_BUCKET' => const String.fromEnvironment(
              'FIREBASE_WEB_STORAGE_BUCKET',
              defaultValue: '',
            ),
          'FIREBASE_WEB_MEASUREMENT_ID' => const String.fromEnvironment(
              'FIREBASE_WEB_MEASUREMENT_ID',
              defaultValue: '',
            ),
          _ => defaultValue,
        }
      : defaultValue;
}

FirebaseOptions _firebaseWebOptionsFromEnvOrDotenv() {
  final apiKey = _fromDefineOrDotenv('FIREBASE_WEB_API_KEY');
  final appId = _fromDefineOrDotenv('FIREBASE_WEB_APP_ID');
  final messagingSenderId =
      _fromDefineOrDotenv('FIREBASE_WEB_MESSAGING_SENDER_ID');
  final projectId = _fromDefineOrDotenv('FIREBASE_WEB_PROJECT_ID');
  final authDomain = _fromDefineOrDotenv('FIREBASE_WEB_AUTH_DOMAIN');
  final storageBucket = _fromDefineOrDotenv('FIREBASE_WEB_STORAGE_BUCKET');
  final measurementId = _fromDefineOrDotenv('FIREBASE_WEB_MEASUREMENT_ID');

  if (apiKey.isEmpty ||
      appId.isEmpty ||
      messagingSenderId.isEmpty ||
      projectId.isEmpty) {
    throw UnsupportedError(
      'Faltan variables para Firebase Web. Define en `.env.*` o por `--dart-define`: '
      'FIREBASE_WEB_API_KEY, FIREBASE_WEB_APP_ID, '
      'FIREBASE_WEB_MESSAGING_SENDER_ID y FIREBASE_WEB_PROJECT_ID.',
    );
  }

  return FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    authDomain: authDomain.isEmpty ? null : authDomain,
    storageBucket: storageBucket.isEmpty ? null : storageBucket,
    measurementId: measurementId.isEmpty ? null : measurementId,
  );
}
