import 'package:flutter/material.dart';


// Importa qui tutte le tue pagine
import '../views/home_screen.dart';
import '../views/Search_screen.dart';
import '../views/trends_screen.dart';
import '../views/Feed_screen.dart'; // Sostituisci con la tua quarta pagina
// ...altre pagine

class BottomNavBarController extends ChangeNotifier {
  int _selectedIndex = 0;

  BottomNavBarController({int initialIndex = 0})
    : _selectedIndex = initialIndex;

  // Lista delle pagine: qui puoi passare parametri/costruttori personalizzati!
  final List<Widget> _pages = [
    HomePage(),
    SearchPage(),
    FeedPage(), // Sostituisci con la tua pagina 4
    TrendsPage(),
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
