import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:texpresso/talk_repository.dart';
import 'package:texpresso/views/Registration_screen.dart';
import 'package:texpresso/views/home_screen.dart';
import '../models/login_model.dart';
import '../controllers/login_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final LoginModel _model;
  late final LoginController _controller;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _model = LoginModel();
    _controller = LoginController(_model, context);
    _redirectIfSignedIn();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _onSubmitCredentials() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await _controller.loginWithCredentials();
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
      setState(() => _model.isLoading = false);
    }
  }

  Future<void> _onSubmitProvider(AuthProvider p) async {
    try {
      await _controller.loginWithProvider(p);
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
      setState(() => _model.isLoading = false);
    }
  }

  Future<void> _redirectIfSignedIn() async {
    final session = await Amplify.Auth.fetchAuthSession();
    if (session.isSignedIn) {
      final talk = await getRandomTalk();
      if (!mounted) return;
      if (talk != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage(talkToShow: talk)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = _model;
    return Scaffold(
      backgroundColor: const Color(0xFFE6D2B0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Image.asset('lib/resources/Logo.png', width: 80, height: 80),
              const SizedBox(height: 16),
              const Text(
                'TEXPRESSO',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        hintText: 'email@domain.com',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (v) => m.email = v,
                      validator:
                          (v) =>
                              v == null || !v.contains('@')
                                  ? 'Email not valid'
                                  : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                        ),
                      ),
                      onChanged: (v) => _model.password = v,
                      validator:
                          (v) =>
                              v == null || v.length < 6
                                  ? 'Password too short'
                                  : null,
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child:
                          m.isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                                onPressed: _onSubmitCredentials,
                                child: const Text('Continue'),
                              ),
                    ),
                    const SizedBox(height: 16),

                    // Testo “Non hai un account? Registrati”
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegistrationScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "Don't have an account? Sign Up",
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                          fontSize: 14,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(child: Divider()),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('or'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => _onSubmitProvider(AuthProvider.google),
                icon: Image.asset('lib/resources/google-logo.png', width: 20),
                label: const Text('Continue with Google'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _onSubmitProvider(AuthProvider.apple),
                icon: const Icon(Icons.apple),
                label: const Text('Continue with Apple'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
