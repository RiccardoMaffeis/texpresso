// lib/views/home_page.dart

import 'package:Texpresso/controllers/TagReceiver.dart';
import 'package:Texpresso/controllers/Talk_Video_Controller.dart';
import 'package:flutter/material.dart';
import 'package:Texpresso/controllers/home_controller.dart';
import 'package:Texpresso/views/UserProfile_screen.dart';
import '../models/Talk.dart';
import '../models/News.dart';
import '../models/NewsAPI.dart';
import '../views/BottomNavBar.dart';
import '../controllers/BottomNavBarController.dart';
import '../controllers/TimerConverter.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeController _ctrl = HomeController();
  final BottomNavBarController _navController =
      BottomNavBarController(initialIndex: 0);
  late Future<List<String>> _availableTags;

  @override
  void initState() {
    super.initState();
    _availableTags = TagReceiver.fetchAvailableTags();
    _ctrl.maybeLoadFromCache().then((_) => setState(() {}));
  }

  Future<void> _onRefreshPressed() async {
    await _ctrl.onRefresh();
    setState(() {});
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
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            ),
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
            child: _ctrl.isLoadingTalk
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: (_ctrl.talks?.length ?? 0),
                    itemBuilder: (ctx, index) {
                      final talk = _ctrl.talks![index];
                      final mins = DateTime.now()
                          .difference(talk.createdAt)
                          .inMinutes;
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildTalkCard(talk, mins),
                          ),
                          if (_ctrl.newsListFutures != null)
                            FutureBuilder<List<News>>(
                              future: _ctrl.newsListFutures![index],
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
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child:
                                        Center(child: Text('Nessuna news disponibile.')),
                                  );
                                }
                                return _buildNewsCard(snap.data!.first);
                              },
                            ),
                          const SizedBox(height: 16),
                          if (_ctrl.newsAPIListFutures != null)
                            FutureBuilder<List<NewsAPI>>(
                              future: _ctrl.newsAPIListFutures![index],
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
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child:
                                        Center(child: Text('Nessuna news disponibile.')),
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
    final sel = _ctrl.selectedTab == idx;
    return GestureDetector(
      onTap: () => setState(() {
        _ctrl.selectedTab = idx;
        _ctrl.isDescriptionExpanded = false;
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
              () => _ctrl.isDescriptionExpanded = !_ctrl.isDescriptionExpanded,
            ),
            child: Text(
              talk.description,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: _ctrl.isDescriptionExpanded ? null : 3,
              overflow: _ctrl.isDescriptionExpanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(
                () => _ctrl.isDescriptionExpanded = !_ctrl.isDescriptionExpanded,
              ),
              child: Text(
                _ctrl.isDescriptionExpanded ? 'Mostra meno' : 'Leggi altro',
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
            onPressed: () async => await _ctrl.launchUrlExternal(news.url),
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
            onPressed: () async => await _ctrl.launchUrlExternal(news.url),
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
