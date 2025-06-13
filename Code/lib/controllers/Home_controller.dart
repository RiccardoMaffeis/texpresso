// lib/controllers/home_controller.dart

import 'dart:convert';
import 'dart:math';
import 'package:Texpresso/controllers/TagReceiver.dart';
import 'package:Texpresso/models/News.dart';
import 'package:Texpresso/models/NewsAPI.dart';
import 'package:Texpresso/models/Talk.dart';
import 'package:Texpresso/models/DataCache.dart';
import 'package:Texpresso/talk_repository.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class HomeController {
  List<Talk>? talks;
  bool isLoadingTalk = true;

  List<Future<List<News>>>? newsListFutures;
  List<Future<List<NewsAPI>>>? newsAPIListFutures;

  int selectedTab = 1;
  bool isDescriptionExpanded = false;

  Future<void> maybeLoadFromCache() async {
    final cache = DataCache();
    if (cache.talks != null &&
        cache.talks!.isNotEmpty &&
        cache.newsCache != null &&
        cache.newsAPICache != null) {
      talks = cache.talks;
      isLoadingTalk = false;
      newsListFutures = cache.newsCache!
          .map((list) => Future<List<News>>.value(list))
          .toList();
      newsAPIListFutures = cache.newsAPICache!
          .map((list) => Future<List<NewsAPI>>.value(list))
          .toList();
    } else {
      await loadContent();
    }
  }

  Future<void> loadContent() async {
    isLoadingTalk = true;

    // 1) Fetch talk correlati
    final tags = await TagReceiver.fetchAvailableTags();
    final randomTag = tags.isNotEmpty ? (tags..shuffle()).first : '';
    final talkService = TalkService();
    final List<String> talkIds =
        await talkService.fetchTalkIdsByTag(randomTag);
    final casual = Random().nextInt(talkIds.length);
    final fixedTalkId = talkIds[casual == 0 ? 0 : casual - 1];

    final uri = Uri.parse(
      'https://jlguvdeu70.execute-api.us-east-1.amazonaws.com/default/Get_watchnext_by_ID',
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

    talks = allRelated.take(5).toList();

    // 2) Cache dei talks
    final cache = DataCache();
    cache.talks = talks!;

    // 3) Fetch news per ogni talk
    final shuffledTags = List<String>.from(tags)..shuffle();
    newsListFutures = [];
    newsAPIListFutures = [];
    for (int i = 0; i < talks!.length; i++) {
      final tag = shuffledTags[i % shuffledTags.length];
      newsListFutures!.add(fetchNewsList(tag));
      newsAPIListFutures!.add(fetchNewsAPIList(tag));
    }

    // 4) Salvo news in cache quando pronte
    final fetchedNews = await Future.wait(newsListFutures!);
    final fetchedNewsAPI = await Future.wait(newsAPIListFutures!);
    cache.newsCache = fetchedNews;
    cache.newsAPICache = fetchedNewsAPI;

    isLoadingTalk = false;
  }

  Future<void> onRefresh() async {
    DataCache().clear();
    await loadContent();
  }

  Future<List<News>> fetchNewsList(String tag) async {
    final uri = Uri.parse(
      'https://xswfiwecq5.execute-api.us-east-1.amazonaws.com/default/Get_newsapi_by_tag',
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
          final img = await fetchArticleImage(news.url);
          if (img != null) news.imageUrl = img;
        }
        result.add(news);
      }
    }
    return result;
  }

  Future<List<NewsAPI>> fetchNewsAPIList(String tag) async {
    final uri = Uri.parse(
      'https://24serv73x4.execute-api.us-east-1.amazonaws.com/default/Get_news_by_tag',
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

  Future<void> launchUrlExternal(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
