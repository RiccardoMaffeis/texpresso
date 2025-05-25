import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

import '../talk_repository.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  bool isLoading = false;

  Future<void> _loginWithCredentials() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    try {
      // 1) Autentica con Cognito User Pool
      final res = await Amplify.Auth.signIn(
        username: email.trim(),
        password: password,
      );
      if (!res.isSignedIn) {
        // Se serve conferma email o MFA puoi gestirlo qui
        throw Exception('Login non completato. Controlla email/MFA.');
      }

      // 2) Continua con la tua logica esistente
      final talk = await getRandomTalk();
      if (!mounted) return;
      setState(() => isLoading = false);

      if (talk == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Errore nel recupero del talk')),
        );
        return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(talkToShow: talk),
        ),
      );
    } on AuthException catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore di autenticazione: ${e.message}')),
      );
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $e')),
      );
    }
  }

  Future<void> _loginWithProvider(AuthProvider provider) async {
    setState(() => isLoading = true);
    try {
      final res = await Amplify.Auth.signInWithWebUI(provider: provider);
      setState(() => isLoading = false);

      if (res.isSignedIn) {
        // Utente autenticato via Hosted UI: recupera il talk e vai a Home
        final talk = await getRandomTalk();
        if (!mounted) return;
        if (talk == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Errore nel recupero del talk')),
          );
          return;
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomePage(talkToShow: talk),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login non completato')),
        );
      }
    } on AuthException catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore social login: ${e.message}')),
      );
    }
  }

  Future<void> _signOut() async {
    try {
      await Amplify.Auth.signOut(
        options: const SignOutOptions(globalSignOut: true),
      );
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore logout: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6D2B0),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 40),
                Image.asset('lib/resources/Logo.png', width: 80, height: 80),
                const SizedBox(height: 16),
                const Text('TEXPRESSO',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  'Create an account\nEnter your email to sign up for this app',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                ),
                const SizedBox(height: 32),

                //––– FORM EMAIL/PASSWORD –––
                Form(
                  key: _formKey,
                  child: Column(children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        hintText: 'email@domain.com',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (v) => email = v,
                      validator: (v) =>
                          v == null || !v.contains('@') ? 'Email non valida' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        hintText: 'Password (min 6 caratteri)',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      obscureText: true,
                      onChanged: (v) => password = v,
                      validator: (v) =>
                          v == null || v.length < 6 ? 'Password troppo corta' : null,
                    ),
                  ]),
                ),
                const SizedBox(height: 24),

                //––– BUTTON Continue –––
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _loginWithCredentials,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF15A24),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Continue',
                              style: TextStyle(fontSize: 16)),
                        ),
                ),
                const SizedBox(height: 32),

                //––– Separator “or” –––
                Row(children: [
                  Expanded(child: Divider(color: Colors.grey.shade400)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('or', style: TextStyle(color: Colors.grey)),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade400)),
                ]),
                const SizedBox(height: 24),

                //––– Social buttons –––
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _loginWithProvider(AuthProvider.google),
                    icon: Image.asset('lib/resources/google-logo.png',
                        width: 20, height: 20),
                    label: const Text('Continue with Google'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _loginWithProvider(AuthProvider.apple),
                    icon: const Icon(Icons.apple, size: 20),
                    label: const Text('Continue with Apple'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text.rich(
                    TextSpan(
                      text: 'By clicking continue, you agree to our ',
                      style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                      children: [
                        TextSpan(
                          text: 'Terms of Service',
                          style: const TextStyle(
                              decoration: TextDecoration.underline,
                              color: Colors.blue),
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: const TextStyle(
                              decoration: TextDecoration.underline,
                              color: Colors.blue),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
