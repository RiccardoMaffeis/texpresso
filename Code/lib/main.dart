import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:texpresso/views/registration_screen.dart';

import 'amplifyconfiguration.dart';
import 'views/login_screen.dart';

Future<void> main() async {
  // Assicura che il binding sia inizializzato prima di chiamare API native
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializza Amplify prima di runApp
  final authPlugin = AmplifyAuthCognito();
  try {
    await Amplify.addPlugins([authPlugin]);
    await Amplify.configure(amplifyconfig);
    debugPrint('✅ Amplify configurato OK');
  } on Exception catch (e) {
    debugPrint('❌ Errore durante configureAmplify: $e');
    // Anche in caso di errore, facciamo partire l’app per vedere la LoginScreen
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyTEDx',
      theme: ThemeData(primarySwatch: Colors.red),
      home: const RegistrationScreen(),
    );
  }
}
