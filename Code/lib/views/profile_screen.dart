// lib/views/profile_page.dart

import 'package:Texpresso/views/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../models/data_cache.dart';
import '../views/login_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Controllers per tutti i campi
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

  // Chiavi fisse per i bit di preferenze
  static const List<String> _prefsKeys = [
    'Motori',
    'Sport',
    'Politica',
    'Politica estera',
    'Mondo',
    'Animali',
    'Cultura',
    'Finanza',
    'Cronaca nera',
    'Altro...',
  ];

  // Mappa delle preferenze
  final Map<String, bool> _preferenze = {
    for (var key in _prefsKeys) key: false,
  };

  bool _loading = true;
  String? _error;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUserAttributes();
  }

  /// Calcola il bitmask da salvare in Cognito (custom:preferences)
  int _computePreferencesMask() {
    int mask = 0;
    for (var i = 0; i < _prefsKeys.length; i++) {
      if (_preferenze[_prefsKeys[i]] == true) {
        mask |= (1 << i);
      }
    }
    return mask;
  }

  Future<void> _loadUserAttributes() async {
    try {
      final attrs = await Amplify.Auth.fetchUserAttributes();
      final data = {
        for (var a in attrs) a.userAttributeKey.toString(): a.value,
      };

      // Popola i campi standard
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

      // Decodifica custom:preferences
      final prefsStr = data['custom:preferences'];
      if (prefsStr != null && prefsStr.isNotEmpty) {
        final mask = int.tryParse(prefsStr) ?? 0;
        for (var i = 0; i < _prefsKeys.length; i++) {
          _preferenze[_prefsKeys[i]] = ((mask >> i) & 1) == 1;
        }
      }

      setState(() => _loading = false);
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
      // Aggiorno attributi Cognito
      await Amplify.Auth.updateUserAttribute(
        userAttributeKey: CognitoUserAttributeKey.name,
        value: _nomeController.text.trim(),
      );
      await Amplify.Auth.updateUserAttribute(
        userAttributeKey: CognitoUserAttributeKey.birthdate,
        value: _compleannoController.text.trim(),
      );
      await Amplify.Auth.updateUserAttribute(
        userAttributeKey: CognitoUserAttributeKey.gender,
        value: _sessoController.text.trim(),
      );
      await Amplify.Auth.updateUserAttribute(
        userAttributeKey: CognitoUserAttributeKey.nickname,
        value: _nicknameController.text.trim(),
      );
      await Amplify.Auth.updateUserAttribute(
        userAttributeKey: CognitoUserAttributeKey.address,
        value: _indirizzoController.text.trim(),
      );

      // Salvo il bitmask delle preferenze in custom:preferences
      final mask = _computePreferencesMask().toString();
      await Amplify.Auth.updateUserAttribute(
        userAttributeKey: const CognitoUserAttributeKey.custom('preferences'),
        value: mask,
      );

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

  /// Effettua il logout globale
  Future<void> _signOut() async {
    try {
      await Amplify.Auth.signOut(
        options: const SignOutOptions(globalSignOut: true),
      );
      // Dopo il logout, torna alla schermata di login
      if (mounted) {
        DataCache().clear();

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      setState(() {
        _error = 'Errore logout: ${e.message}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgBeige = Color.fromARGB(255, 249, 221, 168);
    const cardTeal = Color(0xFF00897B);
    const orange = Color(0xFFF37021);

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
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          if (!_isEditing || !editable)
            Text(
              ctl.text,
              style: const TextStyle(color: Colors.white, fontSize: 16),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                ),
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
        scrolledUnderElevation: 0,              // disabilita l’elevazione on-scroll
  surfaceTintColor: Colors.transparent, 
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed:
              () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => HomePage()),
              ),
        ),
        title: Text(
          _isEditing
              ? 'Modifica profilo'
              : (_nicknameController.text.isNotEmpty
                  ? _nicknameController.text
                  : 'Profilo utente'),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Align(
            alignment: Alignment.center,
            child: Column(
              children: [
                const SizedBox(height: 16),
                const CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: 60, color: Colors.white),
                ),
                const SizedBox(height: 12),
                // Info Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: cardTeal,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildField('Nome e Cognome:', _nomeController),
                        const SizedBox(height: 12),
                        buildField('Email:', _emailController, editable: false),
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
                            color: Color.fromARGB(255, 249, 152, 66),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        buildTwoColumnCheckboxes(cardTeal, orange),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                // Bottone Modifica/Salva
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    SizedBox(width: 15),
                    // Logout Button
                    ElevatedButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: Text(
                        'Logout',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
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
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Genera due colonne di checkbox
  Widget buildTwoColumnCheckboxes(Color cardTeal, Color orange) {
    final labels = _prefsKeys;
    final mid = (labels.length / 2).ceil();
    final leftKeys = labels.sublist(0, mid);
    final rightKeys = labels.sublist(mid);

    Widget buildCheckbox(String key) {
      return Row(
        children: [
          Checkbox(
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: _preferenze[key]! ? orange : Colors.white,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            fillColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) return orange;
              return cardTeal;
            }),
            checkColor: Colors.white,
            value: _preferenze[key],
            onChanged:
                _isEditing
                    ? (v) => setState(() => _preferenze[key] = v ?? false)
                    : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              key,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(children: leftKeys.map(buildCheckbox).toList())),
        const SizedBox(width: 16),
        Expanded(
          child: Column(children: rightKeys.map(buildCheckbox).toList()),
        ),
      ],
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
