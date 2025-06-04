import 'package:amplify_flutter/amplify_flutter.dart';
import '../views/login_screen.dart';
import '../models/login_model.dart';
import 'package:flutter/material.dart';
import '../views/home_screen.dart';

class LoginController {
  final LoginModel model;
  final BuildContext context;

  LoginController(this.model, this.context);

  Future<void> loginWithCredentials() async {
    if (model.email.trim().isEmpty || model.password.isEmpty) {
      throw Exception('Email o password mancanti');
    }
    model.isLoading = true;
    try {
      final res = await Amplify.Auth.signIn(
        username: model.email.trim(),
        password: model.password,
      );
      if (!res.isSignedIn) {
        throw Exception('Login non completato. Controlla email/MFA.');
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
      );
    } on AuthException catch (e) {
      throw Exception('Errore di autenticazione: ${e.message}');
    } finally {
      model.isLoading = false;
    }
  }

  Future<void> loginWithProvider(AuthProvider provider) async {
    model.isLoading = true;
    try {
      final res = await Amplify.Auth.signInWithWebUI(provider: provider);
      if (!res.isSignedIn) {
        throw Exception('Login non completato');
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
      );
    } on AuthException catch (e) {
      throw Exception('Errore social login: ${e.message}');
    } finally {
      model.isLoading = false;
    }
  }
  

  Future<void> signOut() async {
    try {
      await Amplify.Auth.signOut(
        options: const SignOutOptions(globalSignOut: true),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    } on AuthException catch (e) {
      throw Exception('Errore logout: ${e.message}');
    }
  }
}