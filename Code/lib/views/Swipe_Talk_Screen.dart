// lib/views/talk_swipe_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import '../views/home_screen.dart';
import '../models/talk.dart';
import '../controllers/Talk_Video_Controller.dart';

// Import necessari per Cognito tramite Amplify
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

/// Pagina indipendente per swipe dei Talk in stile Tinder,
/// con integrazione per salvare in Cognito i tag dei 5 talk selezionati.
class TalkSwipePage extends StatefulWidget {
  const TalkSwipePage({Key? key}) : super(key: key);

  @override
  State<TalkSwipePage> createState() => _TalkSwipePageState();
}

class _TalkSwipePageState extends State<TalkSwipePage> {
  Talk? _currentTalk;
  bool _isLoading = true;
  int _likeCount = 0;

  /// Lista che raccoglie tutti i tag dei talk a cui l'utente ha messo 'Like'
  final List<String> _selectedTags = [];

  @override
  void initState() {
    super.initState();
    _loadNextTalk();
  }

  Future<void> _loadNextTalk() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final talk = await _fetchRandomTalk();
      setState(() {
        _currentTalk = talk;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  /// Richiama l'API per ottenere un Talk casuale
  Future<Talk?> _fetchRandomTalk() async {
    final uri = Uri.parse(
      'https://y15uqmzsbi.execute-api.us-east-1.amazonaws.com/default/Get_talk_random',
    );
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to load random talk: ${response.statusCode}');
    }

    final body = utf8.decode(response.bodyBytes);
    final dynamic decoded = json.decode(body);
    late final Map<String, dynamic> jsonMap;
    if (decoded is List<dynamic> && decoded.isNotEmpty) {
      jsonMap = Map<String, dynamic>.from(decoded[0] as Map);
    } else if (decoded is Map<String, dynamic>) {
      jsonMap = decoded;
    } else {
      throw Exception('Unexpected JSON format: ${decoded.runtimeType}');
    }
    return Talk.fromJson(jsonMap);
  }

  /// Chiamata quando l'utente preme il pulsante 'Dislike'
  void _onDislike() {
    _loadNextTalk();
  }

  /// Chiamata quando l'utente preme il pulsante 'Like'
  void _onLike() {
    if (_currentTalk != null) {
      // Aggiungo tutti i tag del talk corrente nella lista di selezionati
      for (final tag in _currentTalk!.tags) {
        _selectedTags.add(tag);
      }
    }

    setState(() {
      _likeCount += 1;
    });

    if (_likeCount >= 5) {
      _saveTagsToCognito().then((_) {
        // Dopo aver salvato i tag in Cognito, torno alla HomePage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }).catchError((e) {
        // Se c'è un errore durante il salvataggio in Cognito, mostro un messaggio
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore salvataggio tag: $e')),
        );
      });
    } else {
      _loadNextTalk();
    }
  }

  /// Costruisce la stringa formattata con # e , per ogni tag,
  /// quindi aggiorna l'attributo personalizzato 'custom:tags' in Cognito.
  Future<void> _saveTagsToCognito() async {
    // Creo la stringa: ogni tag diventa "#tag,"
    final buffer = StringBuffer();
    for (final tag in _selectedTags) {
      buffer.write('#$tag,');
    }
    final formatted = buffer.toString(); // es. "#tag1,#tag2,#tag3,"

    try {
      // Verifico che l'utente sia autenticato e recupero i suoi attributi
      final user = await Amplify.Auth.getCurrentUser();
      // Aggiorno l'attributo personalizzato 'custom:tags'
      final result = await Amplify.Auth.updateUserAttribute(
        userAttributeKey: const CognitoUserAttributeKey.custom('tags'),
        value: formatted,
      );
      if (result.isUpdated) {
        // Attributo aggiornato correttamente
        // (Non serve fare nulla in più, la navigazione avverrà a _onLike)
      } else {
        throw Exception('Aggiornamento attributo non riuscito');
      }
    } on AuthException catch (e) {
      throw Exception('AuthException: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6D2B0),
      body: SafeArea(
        child: Column(
          children: [
            // Logo grande e counter
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Image.asset(
                    'lib/resources/Logo.png',
                    width: 120,
                    height: 120,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Seleziona 5 Talk che ti interessano: $_likeCount / 5',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _currentTalk == null
                      ? const Center(
                          child: Text('Errore nel caricamento del talk.'),
                        )
                      : _buildTalkCard(context, _currentTalk!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTalkCard(BuildContext context, Talk talk) {
    final minutesAgo =
        DateTime.now().difference(talk.createdAt).inMinutes;
    final embedUrl = talk.url.replaceFirst(
      'www.ted.com/talks/',
      'embed.ted.com/talks/',
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Card del talk
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF00897B),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    talk.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Descrizione sempre estesa
                  Text(
                    talk.description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 200,
                      child: TalkVideoEmbed(url: embedUrl),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${talk.speakers} • $minutesAgo min ago',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Pulsanti di swipe
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _onDislike,
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(20),
                  backgroundColor: Colors.red,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              ElevatedButton(
                onPressed: _onLike,
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(20),
                  backgroundColor: Colors.green,
                ),
                child: const Icon(
                  Icons.thumb_up,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
