import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/talk.dart';

class News {
  final String title;
  final String description;
  final String url;
  final String? imageUrl;

  News({
    required this.title,
    required this.description,
    required this.url,
    this.imageUrl,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      url: json['url'] as String? ?? '',
      imageUrl: json['urlToImage'] as String? ?? json['imageUrl'] as String?,
    );
  }
}

class HomePage extends StatefulWidget {
  final Talk? talkToShow;
  const HomePage({Key? key, this.talkToShow}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<News?>? _newsFuture;
  int _selectedTab = 1;
  int _selectedNav = 0;

  @override
  void initState() {
    super.initState();
    final tags = widget.talkToShow?.tags;
    if (tags != null && tags.isNotEmpty) {
      _newsFuture = fetchNews(tags.first);
    } else {
      _newsFuture = Future.value(null);
    }
  }

  Future<News?> fetchNews(String tag) async {
    final uri = Uri.parse(
      'https://w8mtzslj7l.execute-api.us-east-1.amazonaws.com/default/Get_newsapi_by_tag',
    );
    final payload = jsonEncode({'query': tag, 'pages': 1});
    debugPrint('[fetchNews] POST $uri → $payload');

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: payload,
    );
    debugPrint('[fetchNews] status: ${res.statusCode}');
    debugPrint('[fetchNews] body: ${res.body}');

    if (res.statusCode == 200) {
      try {
        final data = jsonDecode(res.body);
        if (data is List && data.isNotEmpty) {
          return News.fromJson(data[0] as Map<String, dynamic>);
        }
      } catch (e) {
        debugPrint('[fetchNews] JSON parse error: $e');
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final talk = widget.talkToShow;
    return Scaffold(
      backgroundColor: const Color(0xFFE6D2B0),
      body: SafeArea(
        child: Column(
          children: [
            // — Header —
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
                  const Spacer(),
                  Image.asset('lib/resources/Logo.png', width: 32, height: 32),
                  const Spacer(),
                  const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 18)),
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
                  // Talk Card
                  if (talk != null) _buildTalkCard(talk) else
                    const Center(child: Text('Nessun talk trovato.')),

                  const SizedBox(height: 16),

                  // News Card
                  FutureBuilder<News?>(
                    future: _newsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Text('Errore: ${snapshot.error}');
                      }
                      final news = snapshot.data;
                      if (news == null) {
                        return const Text('Nessuna news disponibile per questo tag.');
                      }
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0277BD),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (news.imageUrl != null && news.imageUrl!.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  news.imageUrl!,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            if (news.imageUrl != null && news.imageUrl!.isNotEmpty)
                              const SizedBox(height: 12),

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
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () {
                                // apri news.url con url_launcher
                              },
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
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // — Bottom Navigation Bar —
      bottomNavigationBar: Container(
        height: 60,
        decoration: const BoxDecoration(
          color: Color(0xFFF15A24),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home),
            _buildNavItem(1, Icons.search),
            _buildNavItem(2, Icons.swap_horiz),
            _buildNavItem(3, Icons.show_chart),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(int idx, String label) {
    final selected = _selectedTab == idx;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = idx),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? Colors.black : Colors.grey[700],
              )),
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

  Widget _buildTalkCard(Talk talk) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF00897B),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
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
                      Text('3 min ago',
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                    ],
                  ),
                ],
              ),
              const Icon(Icons.more_vert, color: Colors.white),
            ],
          ),

          const SizedBox(height: 12),

          // titolo e descrizione
          Text(talk.title,
              style: const TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(talk.description,
              style: const TextStyle(color: Colors.white, fontSize: 14)),

          const SizedBox(height: 12),

          // footer likes/comments
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

  Widget _buildNavItem(int idx, IconData icon) {
    final selected = _selectedNav == idx;
    return GestureDetector(
      onTap: () => setState(() => _selectedNav = idx),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: selected
            ? BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
