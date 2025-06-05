// lib/views/home_page.dart

import 'dart:convert';
import 'dart:math';

import 'package:Texpresso/models/News.dart';
import 'package:Texpresso/models/NewsAPI.dart';
import 'package:Texpresso/views/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../models/talk.dart';
import '../models/data_cache.dart';
import '../views/BottomNavBar.dart';
import '../controllers/BottomNavBarController.dart';
import '../controllers/Talk_Video_Controller.dart';
import '../talk_repository.dart'; // per fetchTalkVideo

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 1) Lista di Talk (eventualmente presa da cache)
  List<Talk>? _talks;
  bool _isLoadingTalk = true;

  // 2) Per ogni talk, avrò una Future che restituisce List<News> per il tag assegnato
  List<Future<List<News>>>? _newsListFutures;
  // 3) Per ogni talk, una Future che restituisce List<NewsAPI>
  List<Future<List<NewsAPI>>>? _newsAPIListFutures;

  // 4) Controller per la Bottom Navigation
  final BottomNavBarController _navController = BottomNavBarController(
    initialIndex: 0,
  );
  int _selectedTab = 1;
  bool _isDescriptionExpanded = false;

  // --------------------------------------------------------------------------
  // 5) Stringa di tag: a questo punto puoi espandere con altri tag separati da virgola
  final String tagString =
      "#culture, #ai, #education, #science, #technology, #health";

  // 6) Lista dei singoli tag (senza '#'), ricavata da tagString e “shufflata”
  late List<String> _availableTags;

  @override
  void initState() {
    super.initState();
    // Divido tagString in lista di tag (rimuovendo il simbolo '#')
    _availableTags =
        tagString
            .split(',')
            .map((t) => t.trim().replaceFirst('#', ''))
            .toList();
    _maybeLoadFromCache();
  }

  void _maybeLoadFromCache() {
    final cache = DataCache();

    if (cache.talks != null && cache.talks!.isNotEmpty) {
      // Se i Talks sono in cache:
      _talks = cache.talks;
      _isLoadingTalk = false;

      // Preparo le Future per le News:
      // - Mescolo i tag (_availableTags)
      // - Prendo tanti tag quanti sono i talk (o ripeto ciclicamente se i tag sono meno)
      final shuffledTags = List<String>.from(_availableTags)..shuffle();
      _newsListFutures = [];
      _newsAPIListFutures = [];

      for (int i = 0; i < _talks!.length; i++) {
        final chosenTag = shuffledTags[i % shuffledTags.length];
        _newsListFutures!.add(fetchNewsList(chosenTag));
        _newsAPIListFutures!.add(fetchNewsAPIList(chosenTag));
      }

      setState(() {});
    } else {
      // Primo avvio: carico i talk (e poi le news associate)
      _loadContent();
    }
  }

  Future<void> _loadContent() async {
    setState(() => _isLoadingTalk = true);
    try {
      const String fixedTalkId = '563142';
      final uri = Uri.parse(
        'https://h18wuxhuy1.execute-api.us-east-1.amazonaws.com/default/Get_Watch_Next_By_Idx',
      );
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'talk_id': fixedTalkId}),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to load related talks: ${response.statusCode}');
      }

      final body = utf8.decode(response.bodyBytes);
      final decoded = json.decode(body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected JSON format: ${decoded.runtimeType}');
      }

      // 1) Estraggo la lista di talk correlati da "related_videos_details"
      final relatedRaw = decoded['related_videos_details'];
      final List<Talk> allRelated = [];
      if (relatedRaw is List<dynamic>) {
        final service = TalkService();
        for (var item in relatedRaw) {
          if (item is Map<String, dynamic>) {
            // Mappo il JSON esterno in un formato compatibile con Talk.fromJson()
            final Map<String, dynamic> jsonMap = {
              '_id': item['id']?.toString() ?? '',
              'slug': '',
              'speakers': item['speaker']?.toString() ?? '',
              'title': item['title']?.toString() ?? '',
              'url': item['video_url']?.toString() ?? '',
              'description': item['description']?.toString() ?? '',
              'duration': item['duration']?.toString() ?? '',
              'publishedAt': item['publishedAt'],
              'tags': <String>[], // l'endpoint non fornisce tags in questo JSON
              'related_ids': <String>[],
              'thumbnailUrl': item['image_url']?.toString() ?? '',
            };

            final talk = Talk.fromJson(jsonMap);

            // Provo a recuperare la “videoUrl” vera tramite fetchTalkVideo()
            if (talk.url.isNotEmpty) {
              try {
                final vid = await service.fetchTalkVideo(talk.url);
                if (vid != null && vid.isNotEmpty) {
                  talk.videoUrl = vid;
                }
              } catch (_) {
                // ignore
              }
            }

            allRelated.add(talk);
          }
        }
      }

      // Prendo al massimo i primi 5 talk
      final valid = allRelated.take(5).toList();

      // Salvo i talk in cache
      final cache = DataCache();
      cache.talks = valid;

      // 2) Preparo le Future per le News:
      //    - Mescolo i tag disponibili
      //    - Per ogni talk assegno un tag diverso (o se i tag finiscono, riciclo ciclicamente)
      final shuffledTags = List<String>.from(_availableTags)..shuffle();
      _newsListFutures = [];
      _newsAPIListFutures = [];
      for (int i = 0; i < valid.length; i++) {
        final chosenTag = shuffledTags[i % shuffledTags.length];
        _newsListFutures!.add(fetchNewsList(chosenTag));
        _newsAPIListFutures!.add(fetchNewsAPIList(chosenTag));
      }

      setState(() {
        _talks = valid;
        _isLoadingTalk = false;
      });
    } catch (e) {
      setState(() => _isLoadingTalk = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Errore caricamento talk: $e')));
    }
  }

  Future<void> _onRefreshPressed() async {
    // Resetto la cache (solo dei talk) e ricarico
    DataCache().clear();
    await _loadContent();
  }

  /// Metodo che chiama l’endpoint “NEWS” (c5palmnsv9…)
  /// Usa il parametro `tag` (stringa, senza '#')
  Future<List<News>> fetchNewsList(String tag) async {
    final uri = Uri.parse(
      'https://2qu4468ttb.execute-api.us-east-1.amazonaws.com/default/Get_newsapi_by_tag',
    );
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'query': tag, 'pages': 1}),
    );
    if (res.statusCode != 200) return [];

    final data = jsonDecode(res.body);
    final List<News> result = [];

    if (data is List && data.isNotEmpty) {
      // Prendo al massimo il primo elemento (puoi cambiare “take(1)” se vuoi più articoli)
      final limitedData = data.take(1).toList();

      for (var item in limitedData) {
        if (item is Map<String, dynamic>) {
          final news = News.fromJson(item);

          // Se non ho immagine, provo a ricavarla dal sito
          if (news.url.isNotEmpty &&
              (news.imageUrl == null || news.imageUrl!.isEmpty)) {
            final img = await _fetchArticleImage(news.url);
            if (img != null) news.imageUrl = img;
          }
          result.add(news);
        }
      }
    }

    return result;
  }

  /// Metodo che chiama l’endpoint “NEWSAPI” (w8mtzslj7l…)
  /// Usa il parametro `tag` (stringa, senza '#')
  Future<List<NewsAPI>> fetchNewsAPIList(String tag) async {
    final uri = Uri.parse(
      'https://ikzrooef8c.execute-api.us-east-1.amazonaws.com/default/Get_news_by_tag',
    );
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'tags': tag}),
    );
    if (res.statusCode != 200) return [];

    final decoded = jsonDecode(res.body);
    final List<NewsAPI> result = [];

    if (decoded is Map<String, dynamic> && decoded['articles'] is List) {
      for (var item in decoded['articles'] as List<dynamic>) {
        if (item is Map<String, dynamic>) {
          final news = NewsAPI.fromJson(item);

          // Se non ho immagini, cerco nel sito
          if ((news.imageUrl == null || news.imageUrl!.isEmpty) &&
              news.url.isNotEmpty) {
            final img = await _fetchArticleImage(news.url);
            if (img != null) news.imageUrl = img;
          }
          result.add(news);
        }
      }
    }
    return result;
  }

  /// Helper per estrarre un’immagine di anteprima da un articolo HTML
  Future<String?> _fetchArticleImage(String url) async {
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

  String _formatElapsed(int mins) {
    if (mins < 60) return '$mins minutes ago';
    final h = mins ~/ 60;
    if (h < 24) return '$h hours ago';
    final d = h ~/ 24;
    if (d < 7) return '$d days ago';
    final w = d ~/ 7;
    if (w < 4) return '$w weeks ago';
    final m = d ~/ 30;
    if (m < 12) return '$m months ago';
    return '${d ~/ 365} years ago';
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _navController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9DDA8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9DDA8),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _onRefreshPressed,
        ),
        title: Image.asset('lib/resources/Logo.png', width: 55, height: 55),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Tabs
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTab(0, 'Friends'),
              const SizedBox(width: 32),
              _buildTab(1, 'For you'),
            ],
          ),
          const SizedBox(height: 16),

          // Contenuto principale
          Expanded(
            child:
                _isLoadingTalk
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: (_talks?.length ?? 0),
                      itemBuilder: (ctx, index) {
                        final talk = _talks![index];
                        final mins =
                            DateTime.now().difference(talk.createdAt).inMinutes;

                        return Column(
                          children: [
                            // 1) Card del Talk
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildTalkCard(talk, mins),
                            ),

                            // 2) Card della prima News per il tag assegnato
                            if (_newsListFutures != null)
                              FutureBuilder<List<News>>(
                                future: _newsListFutures![index],
                                builder: (ctx, snap) {
                                  if (snap.connectionState !=
                                      ConnectionState.done) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  if (snap.hasError ||
                                      snap.data == null ||
                                      snap.data!.isEmpty) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Nessuna news disponibile.',
                                        ),
                                      ),
                                    );
                                  }
                                  // Mostro la prima News
                                  return _buildNewsCard(snap.data!.first);
                                },
                              ),
                            const SizedBox(height: 16),

                            // 3) Card della prima NewsAPI per lo stesso tag
                            if (_newsAPIListFutures != null)
                              FutureBuilder<List<NewsAPI>>(
                                future: _newsAPIListFutures![index],
                                builder: (ctx, snap) {
                                  if (snap.connectionState !=
                                      ConnectionState.done) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  if (snap.hasError ||
                                      snap.data == null ||
                                      snap.data!.isEmpty) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Nessuna news disponibile.',
                                        ),
                                      ),
                                    );
                                  }
                                  // Mostro la prima NewsAPI
                                  return _buildNewsAPICard(snap.data!.first);
                                },
                              ),

                            const SizedBox(height: 24),
                          ],
                        );
                      },
                    ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _navController.selectedIndex,
        onTap: (idx) {
          if (idx == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          } else {
            _navController.changeTab(idx, context);
          }
        },
      ),
    );
  }

  Widget _buildTab(int idx, String label) {
    final sel = _selectedTab == idx;
    return GestureDetector(
      onTap:
          () => setState(() {
            _selectedTab = idx;
            _isDescriptionExpanded = false;
          }),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: sel ? FontWeight.bold : FontWeight.normal,
              color: sel ? Colors.black : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 24,
            height: 2,
            color: sel ? Colors.black : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(News news) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0277BD),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (news.imageUrl?.isNotEmpty == true) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                news.imageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            news.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            news.description,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () async => await _launchUrl(news.url),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: const Text(
              'Leggi di più',
              style: TextStyle(
                decoration: TextDecoration.underline,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsAPICard(NewsAPI news) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0277BD),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (news.imageUrl?.isNotEmpty == true) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                news.imageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            news.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            news.description,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () async => await _launchUrl(news.url),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: const Text(
              'Leggi di più',
              style: TextStyle(
                decoration: TextDecoration.underline,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTalkCard(Talk talk, int minutesAgo) {
    // Sostituisco “www.ted.com/talks/” con “embed.ted.com/talks/” per ottenere l’embed
    final embedUrl = talk.url.replaceFirst(
      'www.ted.com/talks/',
      'embed.ted.com/talks/',
    );

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF00897B),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: avatar + nome speaker + tempo trascorso
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    child: Icon(Icons.person, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        talk.speakers,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatElapsed(minutesAgo),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Icon(Icons.more_vert, color: Colors.white),
            ],
          ),

          const SizedBox(height: 12),
          Text(
            talk.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Descrizione espandibile
          GestureDetector(
            onTap:
                () => setState(
                  () => _isDescriptionExpanded = !_isDescriptionExpanded,
                ),
            child: Text(
              talk.description,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: _isDescriptionExpanded ? null : 3,
              overflow:
                  _isDescriptionExpanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
            ),
          ),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed:
                  () => setState(
                    () => _isDescriptionExpanded = !_isDescriptionExpanded,
                  ),
              child: Text(
                _isDescriptionExpanded ? 'Mostra meno' : 'Leggi altro',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ),

          const SizedBox(height: 12),
          SizedBox(height: 200, child: TalkVideoEmbed(url: embedUrl)),
          const SizedBox(height: 12),

          // Footer: like/comment (dummy)
          Row(
            children: [
              const Icon(Icons.favorite_border, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                '${talk.duration} likes',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.comment, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                '${talk.tags.length} comments',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
