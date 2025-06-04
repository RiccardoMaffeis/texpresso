import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/registration_model.dart';
import '../views/Swipe_Talk_Screen.dart';

class RegistrationController {
  final RegistrationModel model;
  final BuildContext context;
  final _secureStorage = const FlutterSecureStorage();

  RegistrationController({required this.model, required this.context});

  /// Forza il rebuild della view
  void update() => (context as Element).markNeedsBuild();

  /// Mostra uno SnackBar
  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Eseguito solo dopo la conferma del codice o login social
  Future<void> _afterSuccessfulConfirmation() async {
    // Login automatico
    try {
      await Amplify.Auth.signIn(
        username: model.username.trim(),
        password: model.password,
      );
    } catch (e) {
      _showSnack('Login automatico fallito: $e');
    }

    // Salva credenziali in secure storage
    await _secureStorage.write(key: 'email', value: model.email.trim());
    await _secureStorage.write(key: 'password', value: model.password);

    // Naviga allo Swipe dei talk
    model.isLoading = false;
    update();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const TalkSwipePage()),
    );
  }

  /// Registra l’utente e mostra il form di conferma
  Future<void> signUp() async {
    model.isLoading = true;
    update();

    try {
      await Amplify.Auth.signUp(
        username: model.username.trim(),
        password: model.password,
        options: SignUpOptions(
          userAttributes: {
            CognitoUserAttributeKey.email: model.email.trim(),
            CognitoUserAttributeKey.nickname: model.username.trim(),
          },
        ),
      );

      // Mostra sempre step di conferma codice
      model.showConfirmationStep = true;
      model.isLoading = false;
      update();
    } on UsernameExistsException {
      model.isLoading = false;
      update();
      _showSnack('Username o email già in uso');
    } on AuthException catch (e) {
      model.isLoading = false;
      update();
      _showSnack(e.message);
    }
  }

  /// Conferma il codice inviato via email
  Future<void> confirmSignUp() async {
    if (model.confirmationCode.trim().isEmpty) {
      _showSnack('Inserisci il codice di conferma');
      return;
    }

    model.isLoading = true;
    update();

    try {
      final res = await Amplify.Auth.confirmSignUp(
        username: model.username.trim(),
        confirmationCode: model.confirmationCode.trim(),
      );
      model.isLoading = false;
      update();

      if (res.isSignUpComplete) {
        await _afterSuccessfulConfirmation();
      } else {
        _showSnack('Conferma non completata');
      }
    } on AuthException catch (e) {
      model.isLoading = false;
      update();
      _showSnack(e.message);
    }
  }

  /// Login/signup via Google/Apple
  Future<void> socialSignUp(AuthProvider provider) async {
    model.isLoading = true;
    update();

    try {
      final res = await Amplify.Auth.signInWithWebUI(provider: provider);
      model.isLoading = false;
      update();

      if (res.isSignedIn) {
        // Non abbiamo password, salviamo solo email
        await _secureStorage.write(key: 'email', value: model.username.trim());
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TalkSwipePage()),
        );
      } else {
        _showSnack('Registrazione social non completata');
      }
    } on AuthException catch (e) {
      model.isLoading = false;
      update();
      _showSnack(e.message);
    }
  }
}
