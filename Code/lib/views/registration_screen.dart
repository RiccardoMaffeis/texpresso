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
      backgroundColor: const Color(0xFFE6D2B0),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 40),
                Image.asset('lib/resources/Logo.png', width: 120, height: 120),
                const SizedBox(height: 16),

                const SizedBox(height: 8),

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
                      backgroundColor: const Color(0xFFF15A24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
        ),
        const SizedBox(height: 16),

        GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
          child: Text(
            'Hai già un account? Accedi',
            style: TextStyle(
              color: Colors.blue,
              decoration: TextDecoration.underline,
              fontSize: 14,
            ),
          ),
        ),

        const SizedBox(height: 32),

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
          Expanded(child: Divider(color: Colors.grey.shade400)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('or', style: TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Divider(color: Colors.grey.shade400)),
        ],
      ),
      const SizedBox(height: 24),
      OutlinedButton.icon(
        onPressed: () => _controller.socialSignUp(AuthProvider.google),
        icon: Image.asset(
          'lib/resources/google-logo.png',
          width: 20,
          height: 20,
        ),
        label: const Text('Continue with Google'),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: () => _controller.socialSignUp(AuthProvider.apple),
        icon: const Icon(Icons.apple, size: 20),
        label: const Text('Continue with Apple'),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
