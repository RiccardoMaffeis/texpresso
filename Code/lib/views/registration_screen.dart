import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

import '../talk_repository.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _linkRecognizer = TapGestureRecognizer();

  String username = '';
  String email = '';
  String password = '';
  String confirmPassword = '';
  String confirmationCode = '';
  bool isLoading = false;
  bool showConfirmationStep = false;

  @override
  void dispose() {
    _linkRecognizer.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    debugPrint('⏳ _signUp chiamato: username=$username, email=$email');
    // Validazione form
    if (!_formKey.currentState!.validate()) return;
    if (password != confirmPassword) {
      _showSnack('Le password non corrispondono');
      return;
    }

    setState(() => isLoading = true);
    try {
      final res = await Amplify.Auth.signUp(
        username: username.trim(),
        password: password,
        options: SignUpOptions(
          userAttributes: {
            CognitoUserAttributeKey.email: email.trim(),
            CognitoUserAttributeKey.nickname: username.trim(),
          },
        ),
      );
      if (res.isSignUpComplete) {
        await _afterSuccessfulSignUp();
      } else {
        // serve conferma via codice
        setState(() {
          showConfirmationStep = true;
          isLoading = false;
        });
      }
    } on AuthException catch (e) {
      setState(() => isLoading = false);
      _showSnack(e.message);
    }
  }

  Future<void> _confirmSignUp() async {
    if (confirmationCode.trim().isEmpty) {
      _showSnack('Inserisci il codice di conferma');
      return;
    }
    setState(() => isLoading = true);
    try {
      final res = await Amplify.Auth.confirmSignUp(
        username: username.trim(),
        confirmationCode: confirmationCode.trim(),
      );
      if (res.isSignUpComplete) {
        await _afterSuccessfulSignUp();
      } else {
        setState(() => isLoading = false);
        _showSnack('Conferma non completata');
      }
    } on AuthException catch (e) {
      setState(() => isLoading = false);
      _showSnack(e.message);
    }
  }

  Future<void> _afterSuccessfulSignUp() async {
    // Effettua subito il login
    try {
      await Amplify.Auth.signIn(
        username: username.trim(),
        password: password,
      );
    } on AuthException {
      // Se non riesce, torno alla LoginScreen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
      return;
    }

    // Recupera il talk e passa alla Home
    final talk = await getRandomTalk();
    setState(() => isLoading = false);
    if (!mounted) return;

    if (talk == null) {
      _showSnack('Errore nel recupero del talk');
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomePage(talkToShow: talk)),
    );
  }

  Future<void> _socialSignUp(AuthProvider provider) async {
    setState(() => isLoading = true);
    try {
      final res = await Amplify.Auth.signInWithWebUI(provider: provider);
      setState(() => isLoading = false);
      if (res.isSignedIn) {
        final talk = await getRandomTalk();
        if (!mounted) return;
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
      setState(() => isLoading = false);
      _showSnack(e.message);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _buildSignUpForm() => Column(
        children: [
          // Username
          TextFormField(
            decoration: const InputDecoration(
              hintText: 'Username',
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) => username = v,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Username obbligatorio' : null,
          ),
          const SizedBox(height: 16),

          // Email
          TextFormField(
            decoration: const InputDecoration(
              hintText: 'email@domain.com',
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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

          // Password
          TextFormField(
            decoration: const InputDecoration(
              hintText: 'Password (min 6 caratteri)',
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
          const SizedBox(height: 16),

          // Confirm Password
          TextFormField(
            decoration: const InputDecoration(
              hintText: 'Conferma password',
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide.none,
              ),
            ),
            obscureText: true,
            onChanged: (v) => confirmPassword = v,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Conferma obbligatoria';
              if (v != password) return 'Le password non corrispondono';
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Sign Up Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF15A24),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:
                        const Text('Sign Up', style: TextStyle(fontSize: 16)),
                  ),
          ),
          const SizedBox(height: 32),

          // Separator “or”
          Row(children: [
            Expanded(child: Divider(color: Colors.grey.shade400)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('or', style: TextStyle(color: Colors.grey)),
            ),
            Expanded(child: Divider(color: Colors.grey.shade400)),
          ]),
          const SizedBox(height: 24),

          // Social Sign Up
          OutlinedButton.icon(
            onPressed: () => _socialSignUp(AuthProvider.google),
            icon: Image.asset('lib/resources/google-logo.png', width: 20, height: 20),
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
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _socialSignUp(AuthProvider.apple),
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
        ],
      );

  Widget _buildConfirmationForm() => Column(
        children: [
          const Text(
            'Controlla la tua email e inserisci il codice di conferma',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(
              hintText: 'Codice di conferma',
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide.none,
              ),
            ),
            keyboardType: TextInputType.number,
            onChanged: (v) => confirmationCode = v,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _confirmSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF15A24),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Conferma', style: TextStyle(fontSize: 16)),
                  ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    // Se sei già passato a RegistrationScreen come home, questo build verrà utilizzato
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
                const Text(
                  'TEXPRESSO',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // qui avvolgiamo il form o mostriamo il form di conferma
                if (showConfirmationStep)
                  _buildConfirmationForm()
                else
                  Form(
                    key: _formKey,
                    child: _buildSignUpForm(),
                  ),

                const SizedBox(height: 32),

                // Link Terms o Re-invia codice
                Text.rich(
                  TextSpan(
                    text: showConfirmationStep
                        ? 'Non hai ricevuto il codice? '
                        : 'By clicking sign up, you agree to our ',
                    style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                    children: [
                      TextSpan(
                        text: showConfirmationStep
                            ? 'Re-invia email'
                            : 'Terms of Service',
                        style: const TextStyle(
                            decoration: TextDecoration.underline,
                            color: Colors.blue),
                        recognizer: _linkRecognizer
                          ..onTap = () {
                            if (showConfirmationStep) {
                              Amplify.Auth.resendSignUpCode(
                                  username: username.trim());
                              _showSnack('Codice reinviato');
                            } else {
                              // apri Terms di Service
                            }
                          },
                      ),
                      if (!showConfirmationStep) ...[
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: const TextStyle(
                              decoration: TextDecoration.underline,
                              color: Colors.blue),
                          // qui puoi aggiungere un secondo recognizer
                        ),
                      ],
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
