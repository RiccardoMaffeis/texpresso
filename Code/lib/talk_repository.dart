import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';
import '../models/talk.dart';

/// Estrae l’URL del video dalla pagina del talk
Future<String?> fetchTalkVideo(String url) async {
  final res = await http.get(Uri.parse(url));
  if (res.statusCode != 200) {
    throw Exception('Failed to load talk page: ${res.statusCode}');
  }
  final doc = parse(res.body);

  // 1) Open Graph secure video
  final ogSecure = doc.querySelector('meta[property="og:video:secure_url"]');
  if (ogSecure != null) return ogSecure.attributes['content'];

  // 2) Open Graph video
  final ogVideo = doc.querySelector('meta[property="og:video"]');
  if (ogVideo != null) return ogVideo.attributes['content'];

  // 3) Prima <video> o <source> nella pagina
  final source = doc.querySelector('video source');
  if (source != null) return source.attributes['src'];

  return null;
}

Future<Talk?> getRandomTalk() async {
  final uri = Uri.parse(
    'https://y15uqmzsbi.execute-api.us-east-1.amazonaws.com/default/Get_talk_random',
  );
  final response = await http.get(uri);

  if (response.statusCode != 200) {
    throw Exception('Failed to load random talk: ${response.statusCode}');
  }

  // Decodifica bodyBytes per preservare caratteri speciali
  final body = utf8.decode(response.bodyBytes);
  final dynamic decoded = json.decode(body);

  // Normalizza in Map<String, dynamic>
  late final Map<String, dynamic> jsonMap;
  if (decoded is List<dynamic> && decoded.isNotEmpty) {
    jsonMap = Map<String, dynamic>.from(decoded[0] as Map);
  } else if (decoded is Map<String, dynamic>) {
    jsonMap = decoded;
  } else {
    throw Exception('Unexpected JSON format: ${decoded.runtimeType}');
  }

  // Costruisci il Talk
  final talk = Talk.fromJson(jsonMap);

  // Se esiste un URL, prova a estrarre il video
  if (talk.url.isNotEmpty) {
    try {
      final vid = await fetchTalkVideo(talk.url);
      if (vid != null && vid.isNotEmpty) {
        talk.videoUrl = vid;
      }
    } catch (e) {
      // ignora errori di scraping
    }
  }

  return talk;
}
