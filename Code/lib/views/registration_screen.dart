import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import '../models/registration_model.dart';
import '../controllers/Registration_controller.dart';
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

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late final RegistrationModel _model;
  late final RegistrationController _controller;

  @override
  void initState() {
    super.initState();
    _model = RegistrationModel();
    _controller = RegistrationController(model: _model, context: context);
  }

  @override
  void dispose() {
    _linkRecognizer.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await _controller.signUp();
    } catch (e) {
      _showSnack(e.toString().replaceAll('Exception: ', ''));
      setState(() => _model.isLoading = false);
    }
  }

  Future<void> _handleConfirm() async {
    try {
      await _controller.confirmSignUp();
    } catch (e) {
      _showSnack(e.toString().replaceAll('Exception: ', ''));
      setState(() => _model.isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = _model;
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 249, 221, 168),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 25),
                Image.asset('lib/resources/Logo.png', width: 130, height: 130),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child:
                      m.showConfirmationStep
                          ? _buildConfirmationForm()
                          : _buildSignUpForm(),
                ),

                const SizedBox(height: 32),
                _buildFooterLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpForm() {
    return Column(
      children: [
        _textField(
          hint: 'Username',
          onChanged: (v) => _model.username = v,
          validator:
              (v) =>
                  v == null || v.trim().isEmpty
                      ? 'Username obbligatorio'
                      : null,
        ),
        const SizedBox(height: 16),
        _textField(
          hint: 'email@domain.com',
          keyboardType: TextInputType.emailAddress,
          onChanged: (v) => _model.email = v,
          validator:
              (v) => v == null || !v.contains('@') ? 'Email non valida' : null,
        ),
        const SizedBox(height: 16),
        // Campo Password
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
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
          ),
          onChanged: (v) => _model.password = v,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Password obbligatoria';
            final pattern =
                r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$';
            if (!RegExp(pattern).hasMatch(v)) {
              return 'La password deve contenere almeno 8 caratteri, una maiuscola, '
                  'una minuscola, un numero e un carattere speciale';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),
        Text(
          'La password deve essere di almeno 8 caratteri e contenere: \n1 maiuscola, 1 minuscola, 1 numero, 1 speciale',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        const SizedBox(height: 16),
        // Campo Conferma Password
        TextFormField(
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            hintText: 'Conferma password',
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
                _obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: () {
                setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                );
              },
            ),
          ),
          onChanged: (v) => _model.confirmPassword = v,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Conferma obbligatoria';
            if (v != _model.password) return 'Le password non corrispondono';
            return null;
          },
        ),

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child:
              _model.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                    onPressed: _handleSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF37021),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
        ),
        const SizedBox(height: 16),

        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
          child: const Text(
            "Already have an account? Sign In",
            style: TextStyle(
              color: Color(0xFF007AFF),
              decoration: TextDecoration.underline,
              fontSize: 14,
            ),
          ),
        ),

        const SizedBox(height: 20),

        _socialButtons(),
      ],
    );
  }

  Widget _buildConfirmationForm() {
    return Column(
      children: [
        const Text(
          'Controlla la tua email e inserisci il codice di conferma',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        _textField(
          hint: 'Codice di conferma',
          keyboardType: TextInputType.number,
          onChanged: (v) => _model.confirmationCode = v,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child:
              _model.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                    onPressed: _handleConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF15A24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Conferma',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
        ),
      ],
    );
  }

  Widget _socialButtons() => Column(
    children: [
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
        onPressed: () => _controller.socialSignUp(AuthProvider.google),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        onPressed: () => _controller.socialSignUp(AuthProvider.apple),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 22),
        ),
        icon: const Icon(Icons.apple, size: 30, color: Colors.black),
        label: const Text(
          ' Continue with Apple',
          style: TextStyle(color: Colors.black),
        ),
      ),
    ],
  );

  Widget _buildFooterLink() {
    final m = _model;
    return Text.rich(
      TextSpan(
        text:
            m.showConfirmationStep
                ? 'Non hai ricevuto il codice? '
                : 'By clicking sign up, you agree to our ',
        style: TextStyle(fontSize: 12, color: Colors.grey[800]),
        children: [
          TextSpan(
            text:
                m.showConfirmationStep ? 'Re-invia email' : 'Terms of Service',
            style: const TextStyle(
              decoration: TextDecoration.underline,
              color: Colors.blue,
            ),
            recognizer:
                _linkRecognizer
                  ..onTap = () {
                    if (m.showConfirmationStep) {
                      Amplify.Auth.resendSignUpCode(
                        username: m.username.trim(),
                      );
                      _showSnack('Codice reinviato');
                    } else {
                      // apri Terms di Service
                    }
                  },
          ),
          if (!m.showConfirmationStep) ...[
            const TextSpan(text: ' and '),
            const TextSpan(
              text: 'Privacy Policy',
              style: TextStyle(
                decoration: TextDecoration.underline,
                color: Colors.blue,
              ),
            ),
          ],
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _textField({
    required String hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    required Function(String) onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        hintText: hint,
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
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
    );
  }
}
