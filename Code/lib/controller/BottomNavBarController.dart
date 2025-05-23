import 'package:flutter/material.dart';

// Importa qui tutte le tue pagine
import '../views/home_screen.dart';
import '../views/search_screen.dart';
// ...altre pagine

class BottomNavBarController extends ChangeNotifier {
  int _selectedIndex = 0;

  BottomNavBarController({int initialIndex = 0})
    : _selectedIndex = initialIndex;

  // Lista delle pagine: qui puoi passare parametri/costruttori personalizzati!
  final List<Widget> _pages = [
    HomePage(),
    SearchPage(),
    Placeholder(), // Sostituisci con la tua pagina 3
    Placeholder(), // Sostituisci con la tua pagina 4
  ];

  int get selectedIndex => _selectedIndex;
  Widget get currentPage => _pages[_selectedIndex];

  void changeTab(int newIndex, BuildContext context) {
    if (_selectedIndex == newIndex) return;
    _selectedIndex = newIndex;
    notifyListeners();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => _pages[newIndex]),
    );
  }
}
