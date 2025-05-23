import 'package:flutter/material.dart';
import 'package:texpresso/views/home_screen.dart';
import 'package:texpresso/views/login_screen.dart';
import 'package:texpresso/views/search_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyTEDx',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: const LoginScreen(),
    );
  }
}