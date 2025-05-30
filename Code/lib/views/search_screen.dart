// lib/views/search_page.dart

import 'package:flutter/material.dart';
import '../controllers/BottomNavBarController.dart';
import '../views/BottomNavBar.dart';
import '../models/talk.dart';
import '../talk_repository.dart';
import '../controllers/Talk_Video_Controller.dart';
import '../models/data_cache.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final BottomNavBarController _navController = BottomNavBarController(
    initialIndex: 1,
  );

  List<Talk> _talks = [];
  String _query = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTalks();
  }

  Future<void> _loadTalks() async {
    final cache = DataCache();
    // se in cache
    if (cache.searchTalks != null && cache.searchTalks!.isNotEmpty) {
      setState(() {
        _talks = cache.searchTalks!;
        _isLoading = false;
      });
      return;
    }

    // altrimenti fetch
    setState(() => _isLoading = true);
    final talkService = TalkService();
    final fetched = await Future.wait(
      List.generate(20, (_) => talkService.getRandomTalk()),
    );
    final talks = fetched.whereType<Talk>().toList();

    cache.searchTalks = talks;
    setState(() {
      _talks = talks;
      _isLoading = false;
    });
  }

  void _onRefreshPressed() {
    DataCache().searchTalks = null;
    _loadTalks();
  }

  @override
  void dispose() {
    _navController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered =
        _query.isEmpty
            ? _talks
            : _talks
                .where(
                  (t) => t.title.toLowerCase().contains(_query.toLowerCase()),
                )
                .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9DDA8),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF00897B),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'Find talk...',
                    hintStyle: TextStyle(color: Colors.white70),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search, color: Colors.white),
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                  cursorColor: Colors.white,
                ),
              ),
            ),

            // Pulsante Refresh
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.center,
                child: ElevatedButton(
                  onPressed: _onRefreshPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF37021),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Refresh',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),

            // Loader o grid a 2 colonne
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final talk = filtered[i];
                    return GestureDetector(
                      onTap: () => _showTalkDialog(context, talk),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Thumbnail
                            if (talk.thumbnailUrl.isNotEmpty)
                              AspectRatio(
                                aspectRatio: 16 / 9,
                                child: Image.network(
                                  talk.thumbnailUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              ),
                            // Titolo + snippet
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    talk.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    talk.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
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

  void _showTalkDialog(BuildContext context, Talk talk) {
    final embedUrl = talk.url.replaceFirst(
      'www.ted.com/talks/',
      'embed.ted.com/talks/',
    );

    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 48,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 200,
                      child: TalkVideoEmbed(url: talk.videoUrl ?? embedUrl),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      talk.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0277BD),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      talk.description,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}
