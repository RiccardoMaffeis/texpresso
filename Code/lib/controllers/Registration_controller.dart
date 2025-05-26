import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import '../models/registration_model.dart';
import '../talk_repository.dart';
import '../views/home_screen.dart';
import '../views/login_screen.dart';

class RegistrationController {
  final RegistrationModel model;
  final BuildContext context;

  RegistrationController({required this.model, required this.context});

  /// Forza il rebuild della view
  void update() {
    (context as Element).markNeedsBuild();
  }

  /// Mostra uno SnackBar
  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Chiamato quando signUp o confirmSignUp vanno a buon fine
  Future<void> _afterSuccessfulSignUp() async {
  // Proviamo sempre il login automatico
  await Amplify.Auth.signIn(
    username: model.username.trim(),
    password: model.password,
  );

  // Recupera il talk e naviga in home
  final talk = await getRandomTalk();
  model.isLoading = false;
  update();
  if (talk == null) {
    _showSnack('Errore nel recupero del talk');
    return;
  }
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => HomePage(talkToShow: talk)),
  );
}


  /// Registra l’utente su Cognito
  Future<void> signUp() async {
    model.isLoading = true;
    update();

    try {
      final res = await Amplify.Auth.signUp(
        username: model.username.trim(),
        password: model.password,
        options: SignUpOptions(
          userAttributes: {
            CognitoUserAttributeKey.email: model.email.trim(),
            CognitoUserAttributeKey.nickname: model.username.trim(),
          },
        ),
      );

      if (res.isSignUpComplete) {
        await _afterSuccessfulSignUp();
      } else {
        // passo alla conferma codice
        model.showConfirmationStep = true;
        model.isLoading = false;
        update();
      }
    } on UsernameExistsException {
      // username o email già in uso
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
      if (res.isSignUpComplete) {
        await _afterSuccessfulSignUp();
      } else {
        model.isLoading = false;
        update();
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
        // come dopo il signUp normale
        final talk = await getRandomTalk();
        if (talk == null) {
          _showSnack('Errore nel recupero del talk');
          return;
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage(talkToShow: talk)),
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
