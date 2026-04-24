import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:feature_discovery/feature_discovery.dart';

import 'firebase_options.dart';
import 'core/presentation/home_screen.dart' as core;
import 'features/auth/presentation/login.dart';
import 'core/models/user_data.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (!kIsWeb) {
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
      );
    } catch (_) {
      // Ignore potential errors during AppCheck activation.
    }
  }

  runApp(
    ChangeNotifierProvider<UserData>(
      create: (_) => UserData(),
      child: const StyleSyncApp(),
    ),
  );
}

class StyleSyncApp extends StatelessWidget {
  const StyleSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    // CORRECT: Wrap your MaterialApp with FeatureDiscovery
    return FeatureDiscovery(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'StyleSync',
        theme: ThemeData(
          primarySwatch: Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        debugPrint('AuthWrapper: connectionState=${snapshot.connectionState}, hasData=${snapshot.hasData}');
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          debugPrint('AuthWrapper: user signed in');
          return const core.HomeScreen();
        }

        debugPrint('AuthWrapper: showing LoginScreen');
        // Wrap LoginScreen so build-time errors are obvious in logs/UI
        try {
          return const LoginScreen();
        } catch (e, st) {
          debugPrint('AuthWrapper: LoginScreen build error: $e\n$st');
          return Scaffold(body: Center(child: Text('Login build error: $e')));
        }
      },
    );
  }
}



