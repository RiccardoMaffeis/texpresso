import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Dati di esempio
  final nome = 'Riccardo Maffeis';
  final email = 'r.maffeis4@studenti.unibg.it';
  final indirizzo = 'Via del Colletto 8/b';
  final paese = 'Paladina';
  final cap = '24030';
  final sesso = 'Maschio';
  final citta = 'Bergamo';
  final segni = 'Nessuno';

  // Stato delle checkbox
  final Map<String, bool> preferenze = {
    'Motori': true,
    'Sport': true,
    'Politica': false,
    'Politica estera': true,
    'Mondo': false,
    'Animali': false,
    'Cultura': false,
    'Finanza': true,
    'Cronaca nera': false,
    'Altro...': true,
  };

  int _selectedNav = 0;

  @override
  Widget build(BuildContext context) {
    const bgBeige = Color(0xFFE6D2B0);
    const cardTeal = Color(0xFF00897B);
    const orange = Color(0xFFF15A24);

    // Suddivisione delle preferenze in due colonne
    final col1 = [
      'Motori',
      'Sport',
      'Politica',
      'Politica estera',
      'Mondo',
    ];
    final col2 = [
      'Animali',
      'Cultura',
      'Finanza',
      'Cronaca nera',
      'Altro...',
    ];

    return Scaffold(
      backgroundColor: bgBeige,
      appBar: AppBar(
  backgroundColor: Colors.transparent,
  elevation: 0,
  leading: IconButton(
    icon: const Icon(Icons.arrow_back, color: Colors.black),
    onPressed: () {
      Navigator.pop(context);
      // oppure, se vuoi forzare la Home replacing:
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(builder: (_) => HomePage(talkToShow: /* talk */)),
      // );
    },
  ),
  title: const Text('Profile', style: TextStyle(color: Colors.black)),
  automaticallyImplyLeading: false, // ora puoi anche rimuovere questa riga
),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // — Avatar —
              const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 16),

              // — Nome & Email —
              Text(
                nome,
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 24),

              // — Info Card —
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardTeal,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      // Colonna sinistra
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoLabel('Indirizzo:', indirizzo),
                            const SizedBox(height: 12),
                            _infoLabel('Paese:', paese),
                            const SizedBox(height: 12),
                            _infoLabel('CAP:', cap),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Colonna destra
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoLabel('Sesso:', sesso),
                            const SizedBox(height: 12),
                            _infoLabel('Città:', citta),
                            const SizedBox(height: 12),
                            _infoLabel('Segni Particolari:', segni),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // — Preferenze Card con vere Checkbox —
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Prima colonna
                          Expanded(
                            child: Column(
                              children: col1.map((label) {
                                return CheckboxListTile(
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    label,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 16),
                                  ),
                                  activeColor: orange,
                                  checkColor: Colors.white,
                                  value: preferenze[label],
                                  onChanged: (val) {
                                    setState(() {
                                      preferenze[label] = val ?? false;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Seconda colonna
                          Expanded(
                            child: Column(
                              children: col2.map((label) {
                                return CheckboxListTile(
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    label,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 16),
                                  ),
                                  activeColor: orange,
                                  checkColor: Colors.white,
                                  value: preferenze[label],
                                  onChanged: (val) {
                                    setState(() {
                                      preferenze[label] = val ?? false;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // — Edit Profile Button —
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: orange,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  // Azione di edit
                },
                child: const Text('Edit profile',
                    style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Widget di supporto per label + valore
  Widget _infoLabel(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
