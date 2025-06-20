import 'package:Texpresso/models/SearchedTalk.dart';

import 'Talk.dart';
import '../models/News.dart';
import '../models/NewsAPI.dart';

class DataCache {
  DataCache._();
  static final DataCache _instance = DataCache._();
  factory DataCache() => _instance;

  List<Talk>? talks;
  List<Talk>? searchTalks;
  List<SearchedTalk>? talktag;
  List<News>? newsList;
  List<NewsAPI>? newsAPIList;

  List<List<News>>? newsCache;
  List<List<NewsAPI>>? newsAPICache;

  void clear() {
    talks = null;
    newsList = null;
    searchTalks = null;
  }
}
