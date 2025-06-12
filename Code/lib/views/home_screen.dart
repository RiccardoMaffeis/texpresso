// lib/views/home_page.dart

import 'dart:convert';
import 'dart:math';

import 'package:Texpresso/controllers/TagReceiver.dart';
import 'package:Texpresso/models/News.dart';
import 'package:Texpresso/models/NewsAPI.dart';
import 'package:Texpresso/views/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../models/talk.dart';
import '../models/data_cache.dart';
import '../views/BottomNavBar.dart';
import '../controllers/BottomNavBarController.dart';
import '../controllers/TimerConverter.dart';
import '../controllers/TagReceiver.dart';
import '../controllers/Talk_Video_Controller.dart';
import '../talk_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Talk>? _talks;
  bool _isLoadingTalk = true;

  List<Future<List<News>>>? _newsListFutures;
  List<Future<List<NewsAPI>>>? _newsAPIListFutures;

  final BottomNavBarController _navController = BottomNavBarController(
    initialIndex: 0,
  );
  int _selectedTab = 1;
  bool _isDescriptionExpanded = false;

  late Future<List<String>> _availableTags = TagReceiver.fetchAvailableTags();

  @override
  void initState() {
    super.initState();
    _maybeLoadFromCache();
  }

  Future<void> _maybeLoadFromCache() async {
    final cache = DataCache();
    if (cache.talks != null &&
        cache.talks!.isNotEmpty &&
        cache.newsCache != null &&
        cache.newsAPICache != null) {
      // Carico talks e news da cache
      _talks = cache.talks;
      _isLoadingTalk = false;

      _newsListFutures = cache.newsCache!
          .map((list) => Future<List<News>>.value(list))
          .toList();
      _newsAPIListFutures = cache.newsAPICache!
          .map((list) => Future<List<NewsAPI>>.value(list))
          .toList();

      setState(() {});
    } else {
      _loadContent();
    }
  }

  Future<void> _loadContent() async {
    setState(() => _isLoadingTalk = true);
    try {
      // 1) Fetch talk correlati
      final tags = await TagReceiver.fetchAvailableTags();
      final randomTag = tags.isNotEmpty ? (tags..shuffle()).first : '';
      final talkService = TalkService();
      final List<String> talkIds =
          await talkService.fetchTalkIdsByTag(randomTag);
      final casual = Random().nextInt(talkIds.length);
      final fixedTalkId = talkIds[casual == 0 ? 0 : casual - 1];

      final uri = Uri.parse(
        'https://6kspim0kkh.execute-api.us-east-1.amazonaws.com/default/Get_watchnext_by_ID',
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
      final decoded = json.decode(body) as Map<String, dynamic>;

      final relatedRaw = decoded['related_videos_details'] as List<dynamic>;
      final List<Talk> allRelated = [];
      for (var item in relatedRaw) {
        if (item is Map<String, dynamic>) {
          final jsonMap = {
            '_id': item['id']?.toString() ?? '',
            'slug': '',
            'speakers': item['speaker']?.toString() ?? '',
            'title': item['title']?.toString() ?? '',
            'url': item['video_url']?.toString() ?? '',
            'description': item['description']?.toString() ?? '',
            'duration': item['duration']?.toString() ?? '',
            'publishedAt': item['publishedAt'],
            'tags': <String>[],
            'related_ids': <String>[],
            'thumbnailUrl': item['image_url']?.toString() ?? '',
          };
          final talk = Talk.fromJson(jsonMap);
          if (talk.url.isNotEmpty) {
            try {
              final vid = await talkService.fetchTalkVideo(talk.url);
              if (vid != null && vid.isNotEmpty) {
                talk.videoUrl = vid;
              }
            } catch (_) {}
          }
          allRelated.add(talk);
        }
      }

      final valid = allRelated.take(5).toList();

      // 2) Cache dei talks
      final cache = DataCache();
      cache.talks = valid;

      // 3) Fetch news per ogni talk
      final shuffledTags = List<String>.from(await _availableTags)..shuffle();
      _newsListFutures = [];
      _newsAPIListFutures = [];
      for (int i = 0; i < valid.length; i++) {
        final tag = shuffledTags[i % shuffledTags.length];
        _newsListFutures!.add(fetchNewsList(tag));
        _newsAPIListFutures!.add(fetchNewsAPIList(tag));
      }

      // 4) Salvo news in cache quando pronte
      final fetchedNews = await Future.wait(_newsListFutures!);
      final fetchedNewsAPI = await Future.wait(_newsAPIListFutures!);
      cache.newsCache = fetchedNews;
      cache.newsAPICache = fetchedNewsAPI;

      setState(() {
        _talks = valid;
        _isLoadingTalk = false;
      });
    } catch (e) {
      setState(() => _isLoadingTalk = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore caricamento talk: $e')),
      );
    }
  }

  Future<void> _onRefreshPressed() async {
    DataCache().clear();
    await _loadContent();
  }

  Future<List<News>> fetchNewsList(String tag) async {
    print("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa newsapi");
    final uri = Uri.parse(
      'https://njcdkbrrzi.execute-api.us-east-1.amazonaws.com/default/Get_newsapi_by_tag',
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
      for (var item in data.take(1)) {
        final news = News.fromJson(item as Map<String, dynamic>);
        if (news.url.isNotEmpty &&
            (news.imageUrl == null || news.imageUrl!.isEmpty)) {
          final img = await _fetchArticleImage(news.url);
          if (img != null) news.imageUrl = img;
        }
        result.add(news);
      }
    }
    return result;
  }

  Future<List<NewsAPI>> fetchNewsAPIList(String tag) async {
    print("bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb news");
    final uri = Uri.parse(
      'https://c0axez1xvh.execute-api.us-east-1.amazonaws.com/default/Get_news_by_tag',
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
        final news = NewsAPI.fromJson(item as Map<String, dynamic>);
        if ((news.imageUrl == null || news.imageUrl!.isEmpty) &&
            news.url.isNotEmpty) {
          final img = await fetchFirstBodyImage(news.url);
          if (img != null) news.imageUrl = img;
        }
        result.add(news);
      }
    }
    return result;
  }

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

  Future<String?> fetchFirstBodyImage(String pageUrl) async {
    final resp = await http.get(Uri.parse(pageUrl));
    if (resp.statusCode != 200) return null;
    final dom.Document doc = parse(resp.body);
    final dom.Element? imgEl = doc.querySelector('body img');
    if (imgEl == null) return null;
    final rawSrc = imgEl.attributes['src'];
    if (rawSrc == null || rawSrc.trim().isEmpty) return null;
    final Uri uriPage = Uri.parse(pageUrl);
    final Uri uriImg = Uri.parse(rawSrc.trim());
    return uriImg.hasScheme ? uriImg.toString() : uriPage.resolveUri(uriImg).toString();
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
          Expanded(
            child: _isLoadingTalk
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: (_talks?.length ?? 0),
                    itemBuilder: (ctx, index) {
                      final talk = _talks![index];
                      final mins = DateTime.now()
                          .difference(talk.createdAt)
                          .inMinutes;
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildTalkCard(talk, mins),
                          ),
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
                                      child:
                                          Text('Nessuna news disponibile.'),
                                    ),
                                  );
                                }
                                return _buildNewsCard(snap.data!.first);
                              },
                            ),
                          const SizedBox(height: 16),
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
                                      child:
                                          Text('Nessuna news disponibile.'),
                                    ),
                                  );
                                }
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
      onTap: () => setState(() {
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

  Widget _buildTalkCard(Talk talk, int minutesAgo) {
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
          // Header
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
                        formatElapsed(minutesAgo),
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
          GestureDetector(
            onTap: () => setState(
              () => _isDescriptionExpanded = !_isDescriptionExpanded,
            ),
            child: Text(
              talk.description,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: _isDescriptionExpanded ? null : 3,
              overflow: _isDescriptionExpanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(
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
                height: 230,
                width: double.infinity,
                fit: BoxFit.contain,
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
}
