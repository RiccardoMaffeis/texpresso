import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../views/Registration_screen.dart';
import '../views/home_screen.dart';
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
      
      if (!mounted) return;
     
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage()),
        );

    }
  }

  @override
  Widget build(BuildContext context) {
    final m = _model;
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 249, 221, 168),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Image.asset('lib/resources/Logo.png', width: 130, height: 130),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: InputDecoration(
                        hintText: 'email@domain.com',
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
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (v) => m.email = v,
                      validator: (v) =>
                          v == null || !v.contains('@') ? 'Email non valida' : null,
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
                      child: m.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _onSubmitCredentials,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF37021),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Continue',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
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
                      child: const Text(
                        "Don't have an account? Sign Up",
                        style: TextStyle(
                          color: Color(0xFF007AFF),
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
                  const Expanded(
                    child: Divider(
                      thickness: 1,
                      color: Color.fromARGB(255, 148, 148, 148),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'or',
                      style: TextStyle(
                        color: Color.fromARGB(255, 93, 93, 93),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Divider(
                      thickness: 1,
                      color: Color.fromARGB(255, 148, 148, 148),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
               OutlinedButton.icon(
                onPressed: () => _onSubmitProvider(AuthProvider.google),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                ),
                icon: Image.asset('lib/resources/google-logo.png', width: 25),
                label: const Text(
                  ' Continue with Google',
                  style: TextStyle(color: Colors.black),
                ),
              ),
              const SizedBox(height: 12),

              // Apple button
              OutlinedButton.icon(
                onPressed: () => _onSubmitProvider(AuthProvider.apple),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 22),
                ),
                icon: const Icon(Icons.apple, size: 30, color: Colors.black),
                label: const Text(
                  ' Continue with Apple',
                  style: TextStyle(color: Colors.black),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
