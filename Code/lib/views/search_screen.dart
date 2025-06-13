// lib/views/search_page.dart

import 'package:Texpresso/controllers/Talk_Video_Controller.dart';
import 'package:flutter/material.dart';
import '../controllers/Search_controller.dart' as mysearch;
import '../models/Talk.dart';
import '../models/SearchedTalk.dart';
import '../views/BottomNavBar.dart';
import '../controllers/BottomNavBarController.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final BottomNavBarController _navController =
      BottomNavBarController(initialIndex: 1);
  final mysearch.SearchController _ctrl = mysearch.SearchController();
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _initLoad();
  }

  Future<void> _initLoad() async {
    await _ctrl.loadTalks();
    setState(() {});
  }

  void _onRefresh() async {
    await _ctrl.refresh();
    setState(() {});
  }

  void _onSearch() async {
    final rawTag = _query.trim().replaceFirst('#', '');
    if (rawTag.isEmpty) return;
    await _ctrl.searchByTag(rawTag);
    setState(() {
      _query = '';
      _searchController.clear();
    });
  }

  @override
  void dispose() {
    _navController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTagSearch = _ctrl.talksByTag.isNotEmpty;
    final items = isTagSearch ? _ctrl.talksByTag : _ctrl.talks;

    return Scaffold(
      backgroundColor: const Color(0xFFF9DDA8),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Bar di ricerca ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF00897B),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _query = v),
                        decoration: const InputDecoration(
                          hintText: 'Find hashtag...',
                          hintStyle: TextStyle(color: Colors.white70),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16
                          ),
                        ),
                        style: const TextStyle(fontSize: 18, color: Colors.white),
                        cursorColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 44, height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF37021), shape: BoxShape.circle
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.search, color: Colors.white),
                      onPressed: _onSearch,
                      splashRadius: 22,
                      tooltip: 'Cerca hashtag',
                    ),
                  ),
                ],
              ),
            ),

            // ─── Refresh ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: _onRefresh,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF37021),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Refresh', style: TextStyle(color: Colors.white)),
              ),
            ),

            // ─── Contenuto ───
            if (_ctrl.isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (items.isEmpty)
              const Expanded(
                child: Center(child: Text('Nessun risultato', style: TextStyle(fontSize: 18, color: Colors.grey))),
              )
            else
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.75
                  ),
                  itemCount: items.length,
                  itemBuilder: (ctx, i) {
                    if (isTagSearch) {
                      final st = items[i] as SearchedTalk;
                      return _buildCard(
                        title: st.title,
                        url: st.url,
                        description: st.description,
                        videoUrl: null
                      );
                    } else {
                      final t = items[i] as Talk;
                      return _buildCard(
                        title: t.title,
                        url: t.url,
                        description: t.description,
                        videoUrl: t.videoUrl
                      );
                    }
                  },
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _navController.selectedIndex,
        onTap: (idx) => _navController.changeTab(idx, context),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String url,
    required String description,
    String? videoUrl,
  }) {
    final embedUrl = (videoUrl ?? url)
        .replaceFirst('www.ted.com/talks/', 'embed.ted.com/talks/');
    return GestureDetector(
      onTap: () => _showDialog(title, description, embedUrl),
      child: Card(
        color: const Color(0xFF0277BD),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.hardEdge,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                title, maxLines: 3, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            FutureBuilder<String?>(
              future: _ctrl.fetchArticleImage(url),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 120, child: Center(child: CircularProgressIndicator())
                  );
                }
                if (snap.hasError || snap.data == null) {
                  return const SizedBox(
                    height: 120,
                    child: Center(child: Icon(Icons.broken_image, size: 48, color: Colors.grey)),
                  );
                }
                return Image.network(
                  snap.data!, height: 120, width: 180, fit: BoxFit.contain
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDialog(String title, String desc, String embedUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20)
          ),
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 200, child: TalkVideoEmbed(url: embedUrl)),
                const SizedBox(height: 12),
                Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0277BD))),
                const SizedBox(height: 8),
                Text(desc, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
