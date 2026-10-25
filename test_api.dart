import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  var url = Uri.parse('https://login.whatslook.com/api/settings/fetchSettings');
  var response = await http.post(url, headers: {'API-KEY': 'retry123'});
  print(response.body);
}
