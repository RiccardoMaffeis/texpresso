import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../models/registration_model.dart';
import '../controllers/registration_controller.dart';
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

  // Lista di prefissi (Country Codes)
  final List<String> _countryCodes = [
    '+39', // Italia
    '+1',  // USA/Canada
    '+44', // Regno Unito
    '+33', // Francia
    '+49', // Germania
    // … altri prefissi
  ];

  @override
  void initState() {
    super.initState();
    _model = RegistrationModel();
    _controller = RegistrationController(model: _model, context: context);
    _model.countryCode = _countryCodes.first; // default +39
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

  Future<void> _handleConfirmEmail() async {
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
      backgroundColor: const Color.fromARGB(255, 249, 221, 168),
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

                /// Parte di registrazione (username, email, telefono, password)
                if (!m.showConfirmationStep)
                  Form(
                    key: _formKey,
                    child: _buildSignUpForm(),
                  ),

                /// Se siamo nello step di conferma email, mostriamo il relativo campo
                if (m.showConfirmationStep) _buildConfirmationForm(),

                const SizedBox(height: 32),
                _buildFooterLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// --- FORM DI REGISTRAZIONE ---
  Widget _buildSignUpForm() {
    return Column(
      children: [
        // --- USERNAME ---
        _textField(
          hint: 'Username',
          onChanged: (v) => _model.username = v,
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Username obbligatorio' : null,
        ),
        const SizedBox(height: 16),

        // --- EMAIL ---
        _textField(
          hint: 'email@domain.com',
          keyboardType: TextInputType.emailAddress,
          onChanged: (v) => _model.email = v,
          validator: (v) =>
              v == null || !v.contains('@') ? 'Email non valida' : null,
        ),
        const SizedBox(height: 16),

        // --- TELEFONO: DROPDOWN PREFISSI + CAMPO NUMERO ---
        Row(
          children: [
            // Dropdown per i prefissi
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _model.countryCode,
                  items: _countryCodes
                      .map((code) => DropdownMenuItem(
                            value: code,
                            child: Text(code, style: const TextStyle(fontSize: 16)),
                          ))
                      .toList(),
                  onChanged: (selected) {
                    if (selected != null) {
                      setState(() {
                        _model.countryCode = selected;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: 'Numero di telefono',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (v) => _model.phoneNumber = v,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Numero di telefono obbligatorio';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // --- PASSWORD ---
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
        const Text(
          'La password deve essere di almeno 8 caratteri e contenere:\n'
          '1 maiuscola, 1 minuscola, 1 numero, 1 carattere speciale',
          style: TextStyle(color: Colors.grey, fontSize: 12),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // --- CONFERMA PASSWORD ---
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
                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
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

        // --- PULSANTE CONTINUE ---
        SizedBox(
          width: double.infinity,
          height: 48,
          child: _model.isLoading
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

        // --- LINK A LOGIN SCREEN ---
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

        // --- SOCIAL BUTTONS ---
        _socialButtons(),
      ],
    );
  }

  /// --- FORM DI CONFERMA EMAIL ---
  Widget _buildConfirmationForm() {
    final m = _model;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Controlla la tua email e inserisci il codice di conferma',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 16),

        // Codice conferma email
        TextFormField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Codice conferma email',
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
          onChanged: (v) => _model.confirmationCode = v,
        ),
        const SizedBox(height: 24),

        // Pulsante "Conferma"
        SizedBox(
          width: double.infinity,
          height: 48,
          child: m.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _handleConfirmEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF15A24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Conferma',
                    style: TextStyle(fontSize: 16, color: Colors.white),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            ),
            icon: Image.asset('lib/resources/google-logo.png', width: 25),
            label: const Text(
              ' Continue with Google',
              style: TextStyle(color: Colors.black),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _controller.socialSignUp(AuthProvider.apple),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
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
        text: m.showConfirmationStep
            ? 'Non hai ricevuto il codice email? '
            : 'By clicking sign up, you agree to our ',
        style: TextStyle(fontSize: 12, color: Colors.grey[800]),
        children: [
          TextSpan(
            text: m.showConfirmationStep ? 'Re-invia email' : 'Terms of Service',
            style: const TextStyle(
              decoration: TextDecoration.underline,
              color: Colors.blue,
            ),
            recognizer: _linkRecognizer
              ..onTap = () {
                if (m.showConfirmationStep) {
                  Amplify.Auth.resendSignUpCode(
                    username: m.email.trim(),
                  );
                  _showSnack('Codice email reinviato');
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
