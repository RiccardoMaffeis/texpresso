import '../models/talk.dart';
import '../models/news.dart';

class DataCache {
  DataCache._();
  static final DataCache _instance = DataCache._();
  factory DataCache() => _instance;

  Talk? talk;
  News? news;

  void clear() {
    talk = null;
    news = null;
  }
}
