// lib/views/search_page.dart

import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import '../controllers/BottomNavBarController.dart';
import '../views/BottomNavBar.dart';
import '../models/talk.dart';
import '../models/SearchedTalk.dart'; // <— import del modello
// import '../models/SearchedTalk.dart';    // REMOVE or COMMENT OUT any import with different casing
import '../talk_repository.dart'; // TalkService con fetchTalksByTag
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
  List<Searchedtalk> _talkstag =
      []; // <— qui conserveremo i risultati dalla ricerca per tag
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTalks();
  }

  Future<void> _loadTalks() async {
    final cache = DataCache();
    if (cache.searchTalks != null && cache.searchTalks!.isNotEmpty) {
      setState(() {
        _talks = cache.searchTalks!;
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    final talkService = TalkService();
    final fetched = await Future.wait(
      List.generate(20, (_) => talkService.getRandomTalk()),
    );
    final talks = fetched.whereType<Talk>().toList();

    cache.searchTalks = talks;
    if (!mounted) return;
    setState(() {
      _talks = talks;
      _isLoading = false;
    });
  }

  void _onRefreshPressed() {
    DataCache().searchTalks = null;
    _loadTalks();
  }

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

  @override
  void dispose() {
    _navController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showTalkDialogGeneric({
    required String title,
    required String description,
    required String url,
    String? videoUrl,
  }) {
    final embedUrl = (videoUrl ?? url).replaceFirst(
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
                    SizedBox(height: 200, child: TalkVideoEmbed(url: embedUrl)),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0277BD),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(description, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  /// Questa funzione viene invocata dal tasto CERCA (icona arancione)
  Future<void> _handleSearchByTag() async {
    // Estraiamo il tag senza il "#"

    final rawTag;
    if (_query.trim().startsWith('#'))
      rawTag = _query.trim().replaceFirst('#', '');
    else
      rawTag = _query;

    if (rawTag.isEmpty) {
      // Se l'utente non ha scritto nulla dopo '#', non faremo nulla
      return;
    }

    setState(() {
      _isLoading = true;
      _talkstag = []; // puliamo la lista precedente
    });

    try {
      final talkService = TalkService();
      final List<Searchedtalk> talksByTag = await talkService.fetchTalksByTag(
        rawTag,
      );

      DataCache().talktag = talksByTag;
      if (!mounted) return;
      setState(() {
        _talkstag = talksByTag;
        _isLoading = false;
        _query = ''; // resetto la stringa di query
        _searchController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      log('Errore in _handleSearchByTag: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante la ricerca per tag: $rawTag')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1) Ricerca locale sul titolo (solo se non c'è "#")
    final filteredLocal =
        _query.isEmpty || _query.trim().startsWith('#')
            ? _talks
            : _talks
                .where(
                  (t) => t.title.toLowerCase().contains(_query.toLowerCase()),
                )
                .toList();

    // 2) Se abbiamo già popolato _talkstag (cioè la ricerca per tag), mostriamo quelli;
    //    altrimenti mostriamo filteredLocal.
    final bool isTagSearchActive = _talkstag.isNotEmpty;
    final List<dynamic> displayItems =
        isTagSearchActive ? _talkstag : filteredLocal;

    return Scaffold(
      backgroundColor: const Color(0xFFF9DDA8),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Search bar + pulsante cerchiato “Cerca” ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  // 1) TextField
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF00897B),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) {
                          setState(() {
                            _query = v;
                            if (!v.trim().startsWith('#')) {
                              // se l'utente sta digitando testo “normale”,
                              // resettiamo la lista di risultati per tag
                              _talkstag = [];
                            }
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: 'Find hashtag...',
                          hintStyle: TextStyle(color: Colors.white70),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                        cursorColor: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 2) Pulsante cerchiato arancione con icona “search”
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF37021),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.search, color: Colors.white),
                      onPressed: () {
                        _handleSearchByTag();
                      },
                      splashRadius: 22,
                      tooltip: 'Cerca hashtag',
                    ),
                  ),
                ],
              ),
            ),

            // ─── Pulsante Refresh (sotto la barra) ───
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

            // ─── Loader o griglia 2-colonne ───
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (displayItems.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'Nessun risultato',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ),
              )
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
                  itemCount: displayItems.length,
                  itemBuilder: (ctx, i) {
                    if (isTagSearchActive) {
                      final Searchedtalk st = displayItems[i] as Searchedtalk;
                      return _buildCardFromSearchedTalk(st);
                    } else {
                      final Talk t = displayItems[i] as Talk;
                      return _buildCardFromTalk(t);
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

  Widget _buildCardFromTalk(Talk talk) {
    return GestureDetector(
      onTap:
          () => _showTalkDialogGeneric(
            title: talk.title,
            description: talk.description,
            url: talk.url,
            videoUrl: talk.videoUrl,
          ),
      child: Card(
        color: const Color(0xFF0277BD),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.hardEdge,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                talk.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FutureBuilder<String?>(
                  future: fetchArticleImage(talk.url),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 120,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data == null) {
                      return const SizedBox(
                        height: 120,
                        child: Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    }
                    return Image.network(
                      snapshot.data!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.fitHeight,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardFromSearchedTalk(Searchedtalk talk) {
    return GestureDetector(
      onTap:
          () => _showTalkDialogGeneric(
            title: talk.title,
            description: talk.description,
            url: talk.url,
            videoUrl: null, // se SearchedTalk ha un campo videoUrl, usalo qui
          ),
      child: Card(
        color: const Color(0xFF0277BD),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.hardEdge,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                talk.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FutureBuilder<String?>(
                  future: fetchArticleImage(talk.url),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 120,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data == null) {
                      return const SizedBox(
                        height: 120,
                        child: Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    }
                    return Image.network(
                      snapshot.data!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.fitHeight,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
