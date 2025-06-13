// lib/views/profile_page.dart

import 'package:Texpresso/controllers/UserProfile_controller.dart';
import 'package:flutter/material.dart';
import 'Login_screen.dart';
import 'home_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileController _ctrl = ProfileController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _ctrl.loadProfile(onDone: () {
      if (mounted) setState(() {});
    });
  }

  Future<void> _save() async {
    await _ctrl.saveProfile(onDone: () {
      if (mounted) setState(() => _isEditing = false);
    });
  }

  Future<void> _logout() async {
    await _ctrl.signOut();
    if (_ctrl.error == null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore logout: ${_ctrl.error}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgBeige = Color.fromARGB(255, 249, 221, 168);
    const teal = Color(0xFF00897B);
    const orange = Color(0xFFF37021);

    if (_ctrl.isLoading) {
      return const Scaffold(
        backgroundColor: bgBeige,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_ctrl.error != null) {
      return Scaffold(
        backgroundColor: bgBeige,
        body: Center(child: Text('Errore: ${_ctrl.error}', style: const TextStyle(color: Colors.red))),
      );
    }

    return Scaffold(
      backgroundColor: bgBeige,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          ),
        ),
        title: Text(
          _isEditing ? 'Modifica profilo' : (_ctrl.nicknameCtl.text.isNotEmpty ? _ctrl.nicknameCtl.text : 'Profilo utente'),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
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
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: teal,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildField('Nickname', _ctrl.nicknameCtl, orange),
                      const SizedBox(height: 12),
                      _buildField('Nome e Cognome', _ctrl.nameCtl, orange),
                      const SizedBox(height: 12),
                      _buildField('Compleanno', _ctrl.birthdateCtl, orange),
                      const SizedBox(height: 12),
                      _buildField('Email', _ctrl.emailCtl, orange, editable: false),
                      const SizedBox(height: 12),
                      _buildField('Indirizzo', _ctrl.addressCtl, orange),
                      const SizedBox(height: 12),
                      _buildField('Genere', _ctrl.genderCtl, orange),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Preferenze Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: teal,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Preferenze',
                        style: TextStyle(
                          color: Color.fromARGB(255, 249, 152, 66),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildPreferences(orange),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Bottoni Modifica/Logout
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _isEditing ? _save : () => setState(() => _isEditing = true),
                    child: Text(
                      _isEditing ? 'Salva' : 'Modifica profilo',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text('Logout', style: TextStyle(color: Colors.white, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctl, Color accent, {bool editable = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color.fromARGB(255, 249, 152, 66),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: editable && _isEditing
              ? Container(
                padding: EdgeInsets.fromLTRB(10, 2, 10, 2),
                  color: const Color.fromARGB(255, 0, 108, 97),
                  child: TextField(
                    controller: ctl,
                    style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                  ),
                )
              : Text(
                  ctl.text,
                  style: TextStyle(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    fontSize: 16,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPreferences(Color accent) {
    final keys = ProfileController.prefsKeys;
    final mid = (keys.length / 2).ceil();
    final left = keys.sublist(0, mid);
    final right = keys.sublist(mid);

    Widget buildCheckbox(String k) {
      return Row(
        children: [
          Checkbox(
            value: _ctrl.preferences[k],
            activeColor: accent,
            onChanged: _isEditing ? (v) => setState(() => _ctrl.preferences[k] = v!) : null,
          ),
          Expanded(
            child: Text(
              k,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(children: left.map(buildCheckbox).toList())),
        const SizedBox(width: 16),
        Expanded(child: Column(children: right.map(buildCheckbox).toList())),
      ],
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}
