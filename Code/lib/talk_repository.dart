// lib/controllers/talk_service.dart

import 'package:Texpresso/models/SearchedTalk.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:html/parser.dart' show parse;
import '../models/talk.dart';

class TalkService {
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

  /// Prende un singolo talk random dall’API, popola videoUrl e thumbnailUrl via Talk.fromJson
  Future<Talk> getRandomTalk() async {
        print ('bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb');
    final uri = Uri.parse(
      'https://4qz8izwzth.execute-api.us-east-1.amazonaws.com/default/Get_random_random',
    );
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to load random talk: ${response.statusCode}');
    }

    // Decodifica bodyBytes per preservare caratteri speciali
    final body = utf8.decode(response.bodyBytes);
    final decoded = json.decode(body);

    // Normalizza in Map<String, dynamic>
    Map<String, dynamic> jsonMap;
    if (decoded is List && decoded.isNotEmpty) {
      jsonMap = Map<String, dynamic>.from(decoded[0] as Map);
    } else if (decoded is Map<String, dynamic>) {
      jsonMap = decoded;
    } else {
      throw Exception('Unexpected JSON format: ${decoded.runtimeType}');
    }

    final talk = Talk.fromJson(jsonMap);

    // se c’è una URL, prova a catturare il video
    if (talk.url.isNotEmpty) {
      try {
        final vid = await fetchTalkVideo(talk.url);
        if (vid != null && vid.isNotEmpty) talk.videoUrl = vid;
      } catch (e) {
        // ignora
      }
    }

    return talk;
  }

  /// Prende i talk "Watch Next" basati su un talk_id, tramite POST a un'altra Lambda
  Future<List<Talk>> getWatchNextById(String talkId) async {
    final uri = Uri.parse(
      'https://do7junyvy3.execute-api.us-east-1.amazonaws.com/default/Get_watchnext_by_ID',
    );

    // Corpo della richiesta JSON {"talk_id": "568452"}
    final payload = jsonEncode({'talk_id': talkId});
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: payload,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load watch-next talks: ${response.statusCode}',
      );
    }

    // Decodifica bodyBytes per preservare caratteri speciali
    final body = utf8.decode(response.bodyBytes);
    final decoded = json.decode(body);

    // decoded è un Map<String, dynamic> con chiavi "tags" e "related_videos_details"
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected JSON format: ${decoded.runtimeType}');
    }

    // Estrazione della lista di talk correlati
    final relatedList = decoded['related_videos_details'];
    if (relatedList == null || relatedList is! List) {
      return [];
    }

    final List<Talk> talks = [];
    for (final item in relatedList) {
      if (item is Map<String, dynamic>) {
        // Ricostruisco una mappa compatibile con Talk.fromJson()
        final Map<String, dynamic> jsonMap = {
          '_id': item['id']?.toString() ?? '',
          'slug': '', // non disponibile in questa API, lascio vuoto
          'speakers': item['speaker']?.toString() ?? '',
          'title': item['title']?.toString() ?? '',
          'url': item['video_url']?.toString() ?? '',
          'description': item['description']?.toString() ?? '',
          'duration': item['duration']?.toString() ?? '',
          // La chiave "publishedAt" è già nel formato ISO 8601 o null
          'publishedAt': item['publishedAt'],
          // Se l'API restituisce "createdAt" invece di "publishedAt", usare quella
          'tags': <String>[], // non forniti per i correlati, lascio vuoto
          'related_ids': <String>[],
          // Il thumbnail è indicato da "image_url"
          'thumbnailUrl': item['image_url']?.toString() ?? '',
        };

        final talk = Talk.fromJson(jsonMap);

        // Se la URL è presente, estraggo videoUrl come nell'altro metodo
        if (talk.url.isNotEmpty) {
          try {
            final vid = await fetchTalkVideo(talk.url);
            if (vid != null && vid.isNotEmpty) talk.videoUrl = vid;
          } catch (_) {
            // ignora errori di fetchTalkVideo
          }
        }

        talks.add(talk);
      }
    }

    return talks;
  }

  Future<List<String>> fetchTalkIdsByTag(String tag) async {
    const String url =
        'https://cyjwr49z8d.execute-api.us-east-1.amazonaws.com/default/Get_Talk_by_Tag';

    // Corpo della richiesta JSON
    final Map<String, String> payload = {'tag': tag};

    // Invio della richiesta POST
    final http.Response response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      // Decodifica del JSON di risposta
      final List<dynamic> data = jsonDecode(response.body);

      // Estrazione degli _id da ogni oggetto
      return data
          .where(
            (item) => item is Map<String, dynamic> && item.containsKey('_id'),
          )
          .map<String>((item) => item['_id'].toString())
          .toList();
    } else {
      // In caso di errore HTTP, lancia un’eccezione
      throw Exception('Errore nella richiesta: ${response.statusCode}');
    }
  }

  Future<List<Searchedtalk>> fetchTalksByTag(String tag) async {
    print ('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');
    const String url =
        'https://cyjwr49z8d.execute-api.us-east-1.amazonaws.com/default/Get_Talk_by_Tag';

    // 1) Preparo il payload JSON { "tag": "<ilTag>" }
    final Map<String, String> payload = {'tag': tag};

    // 2) Invio la POST
    final http.Response response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception('Errore nella richiesta: ${response.statusCode}');
    }

    // 3) Decodifico l'array di JSON
    final List<dynamic> rawList = jsonDecode(response.body) as List<dynamic>;

    // 4) Mappo ogni elemento in un oggetto SearchedTalk
    return rawList
        .cast<Map<String, dynamic>>()
        .map((json) => Searchedtalk.fromJson(json))
        .toList();
  }

}
