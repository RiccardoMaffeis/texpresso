// lib/views/profile_page.dart

import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:texpresso/amplifyconfiguration.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Controllers per tutti i campi, incluso nickname ed email
  final _nicknameController = TextEditingController();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _indirizzoController = TextEditingController();
  final _paeseController = TextEditingController();
  final _capController = TextEditingController();
  final _sessoController = TextEditingController();
  final _cittaController = TextEditingController();
  final _segniController = TextEditingController();
  final _compleannoController = TextEditingController();
  final _cognomeController = TextEditingController();

  // Preferenze inizialmente tutte false
  final Map<String, bool> _preferenze = {
    'Motori': false,
    'Sport': false,
    'Politica': false,
    'Politica estera': false,
    'Mondo': false,
    'Animali': false,
    'Cultura': false,
    'Finanza': false,
    'Cronaca nera': false,
    'Altro...': false,
  };

  bool _loading = true;
  String? _error;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUserAttributes();
  }

  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Amplify.addPlugin(AmplifyAuthCognito());
    await Amplify.configure(amplifyconfig);
    runApp(const ProfilePage());
  }

  Future<void> _loadUserAttributes() async {
    try {
      final attrs = await Amplify.Auth.fetchUserAttributes();
      final data = {
        for (var a in attrs) a.userAttributeKey.toString(): a.value,
      };
      setState(() {
        _nicknameController.text = data['nickname'] ?? '';
        _nomeController.text = data['name'] ?? '';
        _compleannoController.text = data['birthdate'] ?? '';
        _emailController.text = data['email'] ?? '';
        _indirizzoController.text = data['address'] ?? '';
        _paeseController.text = data['city'] ?? '';
        _capController.text = data['custom:cap'] ?? '';
        _sessoController.text = data['gender'] ?? '';
        _cittaController.text = data['custom:citta'] ?? '';
        _segniController.text = data['custom:segni'] ?? '';
        _loading = false;
      });
    } on AuthException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _loading = true);
    try {
      // Aggiorno solo campi modificabili (nickname/email non editabili)
      await Amplify.Auth.updateUserAttribute(
        userAttributeKey: CognitoUserAttributeKey.name,
        value: _nomeController.text.trim(),
      );
      await Amplify.Auth.updateUserAttribute(
        userAttributeKey: CognitoUserAttributeKey.birthdate,
        value: _compleannoController.text.trim(),
      );
      // gender è standard
      await Amplify.Auth.updateUserAttribute(
        userAttributeKey: CognitoUserAttributeKey.gender,
        value: _sessoController.text.trim(),
      );
      await Amplify.Auth.updateUserAttribute(
        userAttributeKey: CognitoUserAttributeKey.nickname,
        value: _nomeController.text.trim(),
      );
      await Amplify.Auth.updateUserAttribute(
        userAttributeKey: CognitoUserAttributeKey.address,
        value: _indirizzoController.text.trim(),
      );
      // eventualmente salvare preferenze insieme se necessario

      setState(() {
        _isEditing = false;
        _loading = false;
      });
    } on AuthException catch (e) {
      setState(() {
        _error = 'Salvataggio fallito: ${e.message}';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgBeige = Color(0xFFE6D2B0);
    const cardTeal = Color(0xFF00897B);
    const orange = Color(0xFFF15A24);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Errore: $_error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    Widget buildField(
      String label,
      TextEditingController ctl, {
      bool editable = true,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color.fromARGB(255, 249, 152, 66),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          if (!_isEditing || !editable)
            Text(
              ctl.text,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            )
          else
            TextField(
              controller: ctl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                filled: true,
                fillColor: Color(0xFF01675B),
                border: OutlineInputBorder(borderRadius: BorderRadius.zero),
              ),
            ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: bgBeige,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'Modifica profilo' : 'Profilo utente',
          style: const TextStyle(color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Align(
            alignment: Alignment.center,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                const CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: 60, color: Colors.white),
                ),
                const SizedBox(height: 16),
                // Info Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                    decoration: BoxDecoration(
                      color: cardTeal,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildField('Nome e Cognome:', _nomeController),
                        const SizedBox(height: 12),
                        buildField('Email:', _emailController),
                        const SizedBox(height: 12),
                        buildField('Compleanno:', _compleannoController),
                        const SizedBox(height: 12),
                        buildField('Indirizzo:', _indirizzoController),
                        const SizedBox(height: 12),
                        buildField('Sesso:', _sessoController),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Preferenze
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardTeal,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Preferenze:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Column(
                          spacing: 8,
                          children:
                              _preferenze.keys.map((label) {
                                return SizedBox(
                                  width:
                                      (MediaQuery.of(context).size.width - 64) /
                                      2,
                                  child: CheckboxListTile(
                                    title: Text(
                                      label,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    contentPadding: EdgeInsets.zero,
                                    activeColor: orange,
                                    checkColor: Colors.white,
                                    value: _preferenze[label],
                                    onChanged:
                                        _isEditing
                                            ? (v) => setState(
                                              () =>
                                                  _preferenze[label] =
                                                      v ?? false,
                                            )
                                            : null,
                                  ),
                                );
                              }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Bottone Modifica/Salva
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed:
                      _isEditing
                          ? _saveChanges
                          : () => setState(() => _isEditing = true),
                  child: Text(
                    _isEditing ? 'Salva' : 'Modifica profilo',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _nomeController.dispose();
    _emailController.dispose();
    _indirizzoController.dispose();
    _paeseController.dispose();
    _capController.dispose();
    _sessoController.dispose();
    _cittaController.dispose();
    _segniController.dispose();
    _compleannoController.dispose();
    _cognomeController.dispose();
    super.dispose();
  }
}
