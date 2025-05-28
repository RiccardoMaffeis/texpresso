// lib/views/home_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../models/talk.dart';
import '../models/news.dart';
import '../views/login_screen.dart';
import '../views/profile_screen.dart';
import '../views/BottomNavBar.dart';
import '../controllers/BottomNavBarController.dart';
import '../controllers/Talk_Video_Controller.dart';

class HomePage extends StatefulWidget {
  final Talk? talkToShow;
  const HomePage({Key? key, this.talkToShow}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<News?>? _newsFuture;
  final BottomNavBarController _navController = BottomNavBarController(
    initialIndex: 0,
  );
  int _selectedTab = 1;
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    final tags = widget.talkToShow?.tags;
    _newsFuture = (tags != null && tags.isNotEmpty)
        ? fetchNews(tags.first)
        : Future.value(null);
  }

  @override
  void dispose() {
    _navController.dispose();
    super.dispose();
  }

  Future<News?> fetchNews(String tag) async {
    final uri = Uri.parse(
      'https://w8mtzslj7l.execute-api.us-east-1.amazonaws.com/default/Get_newsapi_by_tag',
    );
    final res = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': tag, 'pages': 1}));
    if (res.statusCode != 200) return null;

    try {
      final data = jsonDecode(res.body);
      if (data is List && data.isNotEmpty) {
        final news = News.fromJson(data[0] as Map<String, dynamic>);
        if (news.url.isNotEmpty) {
          final img = await fetchArticleImage(news.url);
          if (img != null && img.isNotEmpty) {
            news.imageUrl = img;
          }
        }
        return news;
      }
    } catch (_) {}
    return null;
  }

  Future<String?> fetchArticleImage(String url) async {
    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode != 200) return null;
    final doc = parse(resp.body);

    final og = doc.querySelector('meta[property="og:image"]');
    if (og != null) return og.attributes['content'];

    final linkImg = doc.querySelector('link[rel="image_src"]');
    if (linkImg != null) return linkImg.attributes['href'];

    final img = doc.querySelector('main img') ?? doc.querySelector('body img');
    return img?.attributes['src'];
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final talk = widget.talkToShow;
    final minutesAgo =
        talk != null ? DateTime.now().difference(talk.createdAt).inMinutes : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFE6D2B0),
      body: SafeArea(
        child: Column(
          children: [
            // — Header —
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  const SizedBox(width: 55),
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        'lib/resources/Logo.png',
                        width: 50,
                        height: 50,
                      ),
                    ),
                  ),
                  const SizedBox(width: 19),
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfilePage()),
                    ),
                    child: const CircleAvatar(
                      radius: 16,
                      child: Icon(Icons.person, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            // — Tabs —
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTabItem(0, 'Friends'),
                const SizedBox(width: 32),
                _buildTabItem(1, 'For you'),
              ],
            ),
            const SizedBox(height: 16),

            // — Content —
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (talk != null)
                    _buildTalkCard(talk, minutesAgo)
                  else
                    const Center(child: Text('Nessun talk trovato.')),
                  const SizedBox(height: 16),
                  FutureBuilder<News?>(
                    future: _newsFuture,
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError) {
                        return Text('Errore: ${snap.error}');
                      }
                      final news = snap.data;
                      if (news == null) {
                        return const Text(
                          'Nessuna news disponibile per questo tag.',
                        );
                      }
                      return _buildNewsCard(news);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // — Bottom Navigation Bar —
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _navController.selectedIndex,
        onTap: (idx) {
          if (idx == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => HomePage(talkToShow: talk)),
            );
          } else {
            _navController.changeTab(idx, context);
          }
        },
      ),
    );
  }

  Widget _buildTabItem(int idx, String label) {
    final selected = _selectedTab == idx;
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
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? Colors.black : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 24,
            height: 2,
            color: selected ? Colors.black : Colors.transparent,
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
            onPressed: () => _launchUrl(news.url),
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
    // costruisci l’URL di embed TED
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 16)),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(talk.speakers,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('$minutesAgo min ago',
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
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
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          // Descrizione espandibile
          GestureDetector(
            onTap: () => setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
            child: Text(
              talk.description,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: _isDescriptionExpanded ? null : 3,
              overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
              child: Text(
                _isDescriptionExpanded ? 'Mostra meno' : 'Leggi altro',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Embed ufficiale TED
          SizedBox(
            height: 200,
            child: TalkVideoEmbed(url: embedUrl),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.favorite_border, color: Colors.white),
              const SizedBox(width: 6),
              Text('${talk.duration} likes',
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
              const SizedBox(width: 16),
              const Icon(Icons.comment, color: Colors.white),
              const SizedBox(width: 6),
              Text('${talk.tags.length} comments',
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
