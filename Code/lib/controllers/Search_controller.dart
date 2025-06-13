// lib/controllers/search_controller.dart

import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import '../models/Talk.dart';
import '../models/SearchedTalk.dart';
import '../models/DataCache.dart';
import '../talk_repository.dart';  // TalkService

class SearchController {
  final TalkService _service = TalkService();
  final DataCache _cache = DataCache();

  List<Talk> talks = [];
  List<SearchedTalk> talksByTag = [];
  bool isLoading = false;

  /// Carica 20 talk casuali (o dal cache)
  Future<void> loadTalks() async {
    isLoading = true;
    if (_cache.searchTalks != null && _cache.searchTalks!.isNotEmpty) {
      talks = _cache.searchTalks!;
    } else {
      final fetched = await Future.wait(
        List.generate(20, (_) => _service.getRandomTalk()),
      );
      talks = fetched.whereType<Talk>().toList();
      _cache.searchTalks = talks;
    }
    isLoading = false;
  }

  /// Cancella cache e ricarica
  Future<void> refresh() async {
    _cache.searchTalks = null;
    await loadTalks();
  }

  /// Cerca per hashtag (senza il '#') e aggiorna talksByTag
 Future<void> searchByTag(String rawTag) async {
  if (rawTag.isEmpty) return;
  isLoading = true;
  talksByTag = await _service.fetchTalksByTag(rawTag);
  _cache.talktag = talksByTag;
  isLoading = false;
}



  /// Estrae l’immagine di preview da una pagina web
  Future<String?> fetchArticleImage(String url) async {
    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode != 200) return null;
    final doc = parse(resp.body);
    final og = doc.querySelector('meta[property="og:image"]');
    if (og != null) return og.attributes['content'];
    final link = doc.querySelector('link[rel="image_src"]');
    if (link != null) return link.attributes['href'];
    final img = doc.querySelector('main img') ?? doc.querySelector('body img');
    return img?.attributes['src'];
  }
}
