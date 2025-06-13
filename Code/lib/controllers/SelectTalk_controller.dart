// lib/controllers/talk_swipe_controller.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:amplify_flutter/amplify_flutter.dart';
import '../models/talk.dart';

class SelectTalkController {
  Talk? currentTalk;
  bool isLoading = false;
  int likeCount = 0;
  final Set<String> selectedTags = {};

  /// Carica un talk casuale da API
  Future<void> loadNextTalk() async {
    isLoading = true;
    final talk = await _fetchRandomTalk();
    currentTalk = talk;
    isLoading = false;
  }

  Future<Talk?> _fetchRandomTalk() async {
    final uri = Uri.parse(
      'https://2ep0s4jj1d.execute-api.us-east-1.amazonaws.com/default/Get_talk_random',
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Failed to load talk: ${res.statusCode}');
    }
    final body = utf8.decode(res.bodyBytes);
    final decoded = json.decode(body);
    final Map<String, dynamic> jsonMap = (decoded is List && decoded.isNotEmpty)
      ? Map<String, dynamic>.from(decoded[0])
      : Map<String, dynamic>.from(decoded as Map);
    return Talk.fromJson(jsonMap);
  }

  /// Scarto il talk e ne carico un altro
  Future<void> dislike() async {
    await loadNextTalk();
  }

  /// "Mi piace": accumulo i tag, salvo se ho raggiunto 5 like
  Future<void> like() async {
    if (currentTalk != null) {
      selectedTags.addAll(currentTalk!.tags);
      likeCount++;
      if (likeCount >= 5) {
        await _saveTagsToCognito();
      } else {
        await loadNextTalk();
      }
    }
  }

  String get formattedTags {
    if (selectedTags.isEmpty) return '';
    return selectedTags.map((t) => '#$t').join(',') + ',';
  }

  Future<void> _saveTagsToCognito() async {
    final formatted = formattedTags;
    final user = await Amplify.Auth.getCurrentUser();
    final res = await Amplify.Auth.updateUserAttribute(
      userAttributeKey: const CognitoUserAttributeKey.custom('tags'),
      value: formatted,
    );
    if (!res.isUpdated) {
      throw Exception('Aggiornamento attributo non riuscito');
    }
  }

  /// Ritorna la stringa tipo "5m fa" grazie a TimerConverter
  String formatElapsed(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    final minutes = diff.inMinutes;
    if (minutes < 1) return 'ora';
    if (minutes < 60) return '${minutes}m fa';
    final hours = minutes ~/ 60;
    if (hours < 24) return '${hours}h fa';
    final days = hours ~/ 24;
    return '${days}g fa';
  }
}
