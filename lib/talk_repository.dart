import 'package:http/http.dart' as http;
import 'dart:convert';
import 'models/talk.dart';

Future<Talk?> getRandomTalk() async {
  var url = Uri.parse('https://y15uqmzsbi.execute-api.us-east-1.amazonaws.com/default/Get_talk_random');
  final http.Response response = await http.get(url);

  if (response.statusCode == 200) {
    final body = utf8.decode(response.bodyBytes);
    final Map<String, dynamic> jsonMap = json.decode(body);
    return Talk.fromJSON(jsonMap);
  } else {
    throw Exception('Failed to load random talk');
  }
}