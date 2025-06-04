
import 'package:Texpresso/models/data_cache.dart';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

import 'amplifyconfiguration.dart';
import 'views/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DataCache().clear();
  // 1) Amplify
  final authPlugin = AmplifyAuthCognito();
  try {
    await Amplify.addPlugins([authPlugin]);
    await Amplify.configure(amplifyconfig);
    debugPrint('✅ Amplify configurato OK');
  } on Exception catch (e) {
    debugPrint('❌ Errore durante configureAmplify: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Texpresso',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: const LoginScreen(),
    );
  }
}
