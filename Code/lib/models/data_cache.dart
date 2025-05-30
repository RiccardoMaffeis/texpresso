import '../models/talk.dart';
import '../models/news.dart';

class DataCache {
  DataCache._();
  static final DataCache _instance = DataCache._();
  factory DataCache() => _instance;

  List<Talk>? talks;
  List<Talk>? searchTalks;
  News? news;

  void clear() {
    talks = null;
    news = null;
    searchTalks = null;
  }
}
