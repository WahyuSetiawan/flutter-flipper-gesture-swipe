import 'package:http/http.dart' as http;
import 'api.dart';
import 'dart:convert';
import 'model/everything.dart';
import 'model/headlines.dart';

Future<Everything> getEverything() async {
  final response = await http.get(
      "https://newsapi.org/v2/everything?q=bitcoin&from=2019-05-17&sortBy=publishedAt&apiKey=b1e54ee361ca41e3a4692bfe39b1b9ae");

  if (response.statusCode == 200) {
    return Everything.fromJson(json.decode(response.body));
  } else {
    return null;
  }
}

Future<Headlines> getHeadlines() async {
  final response = await http.get("https://newsapi.org/v2/top-headlines?country=us&category=business&apiKey=b1e54ee361ca41e3a4692bfe39b1b9ae");

  if (response.statusCode == 200) {
    return Headlines.fromJson(json.decode(response.body));
  } else {
    return null;
  }
}
