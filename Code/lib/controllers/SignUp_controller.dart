// registration_controller.dart

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/Signup_model.dart';
import '../views/SelectTalk_Screen.dart';

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

  /// Eseguito subito dopo la conferma email
  Future<void> _afterSuccessfulConfirmation() async {
    try {
      await Amplify.Auth.signIn(
        username: model.email.trim(),
        password: model.password,
      );
    } on AuthException catch (e) {
      _showSnack('Login automatico fallito: ${e.message}');
      return;
    }

    // Salva credenziali in secure storage
    await _secureStorage.write(key: 'email', value: model.email.trim());
    await _secureStorage.write(key: 'password', value: model.password);

    model.isLoading = false;
    update();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SelectTalkPage()),
    );
  }

  /// Registra l’utente (inviando anche phone_number) e poi mostra la conferma email
  Future<void> signUp() async {
    model.isLoading = true;
    update();

    // Componi il telefono in formato E.164
    final fullPhoneNumber = '${model.countryCode}${model.phoneNumber.trim()}';

    try {
      await Amplify.Auth.signUp(
        username: model.email.trim(),
        password: model.password,
        options: SignUpOptions(
          userAttributes: {
            AuthUserAttributeKey.nickname: model.nickname.trim(),
            AuthUserAttributeKey.email: model.email.trim(),
            AuthUserAttributeKey.phoneNumber: fullPhoneNumber,
          },
        ),
      );

      // Mostra lo step di conferma email
      model.showConfirmationStep = true;
      model.isLoading = false;
      update();
    } on UsernameExistsException {
      model.isLoading = false;
      update();
      _showSnack('Email già in uso');
    } on AuthException catch (e) {
      model.isLoading = false;
      update();
      _showSnack(e.message);
    }
  }

  /// Conferma il codice inviato via email, quindi effettua login
  Future<void> confirmSignUp() async {
    if (model.confirmationCode.trim().isEmpty) {
      _showSnack('Inserisci il codice di conferma email');
      return;
    }

    model.isLoading = true;
    update();

    try {
      final SignUpResult res = await Amplify.Auth.confirmSignUp(
        username: model.email.trim(),
        confirmationCode: model.confirmationCode.trim(),
      );
      model.isLoading = false;
      update();

      if (res.isSignUpComplete) {
        // Salto la verifica telefono, vado direttamente al login
        await _afterSuccessfulConfirmation();
      } else {
        _showSnack('Conferma email non completata');
      }
    } on AuthException catch (e) {
      model.isLoading = false;
      update();
      _showSnack(e.message);
    }
  }

  /// Login/signup via Google/Apple (invariato)
  Future<void> socialSignUp(AuthProvider provider) async {
    model.isLoading = true;
    update();

    try {
      final res = await Amplify.Auth.signInWithWebUI(provider: provider);
      model.isLoading = false;
      update();

      if (res.isSignedIn) {
        // Prelevo l'email dai userAttributes per salvarla
        try {
          final List<AuthUserAttribute> attrs = await Amplify.Auth.fetchUserAttributes();
          final emailAttr = attrs.firstWhere(
            (attr) => attr.userAttributeKey == AuthUserAttributeKey.email,
            orElse: () => throw Exception('Email non trovata'),
          );
          await _secureStorage.write(
            key: 'email',
            value: emailAttr.value.trim(),
          );
        } catch (_) {
          // se non c'è email, proseguo comunque
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SelectTalkPage()),
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
