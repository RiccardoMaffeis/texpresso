// lib/views/talk_swipe_page.dart

import 'package:Texpresso/controllers/SelectTalk_controller.dart';
import 'package:Texpresso/controllers/Talk_Video_Controller.dart';
import 'package:flutter/material.dart';
// Removed duplicate/conflicting import: '../controllers/Selecttalk_controller.dart';
import '../models/talk.dart';
import '../views/home_screen.dart';
import '../controllers/TimerConverter.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:fl_chart/fl_chart.dart'; // se ti serve per il video embed

class SelectTalkPage extends StatefulWidget {
  const SelectTalkPage({Key? key}) : super(key: key);

  @override
  State<SelectTalkPage> createState() => _SelectTalkPageState();
}

class _SelectTalkPageState extends State<SelectTalkPage> {
  final SelectTalkController _ctrl = SelectTalkController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await _ctrl.loadNextTalk();
      setState(() {});
    } catch (_) {
      setState(() {});
    }
  }

  void _onDislike() async {
    await _ctrl.dislike();
    setState(() {});
  }

  void _onLike() async {
    try {
      await _ctrl.like();
      if (_ctrl.likeCount >= 5) {
        // una volta salvati, torno alla home
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      } else {
        setState(() {}); // nuovo talk
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore salvataggio tag: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9DDA8),
      body: SafeArea(
        child: Column(
          children: [
            // header con logo e counter
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Image.asset('lib/resources/Logo.png', width: 120, height: 120),
                  const SizedBox(height: 8),
                  Text(
                    'Seleziona 5 Talk: ${_ctrl.likeCount} / 5',
                    style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _ctrl.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : (_ctrl.currentTalk == null
                      ? const Center(child: Text('Errore nel caricamento.'))
                      : _talkCard(_ctrl.currentTalk!)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _talkCard(Talk talk) {
    final embedUrl = talk.url.replaceFirst(
      'www.ted.com/talks/',
      'embed.ted.com/talks/',
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
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
                  Text(talk.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      )),
                  const SizedBox(height: 8),
                  Text(talk.description,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      )),
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
                    _ctrl.formatElapsed(talk.createdAt),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
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
                child: const Icon(Icons.close, color: Colors.white, size: 32),
              ),
              ElevatedButton(
                onPressed: _onLike,
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(20),
                  backgroundColor: Colors.green,
                ),
                child:
                    const Icon(Icons.thumb_up, color: Colors.white, size: 32),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
