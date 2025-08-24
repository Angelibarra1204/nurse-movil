import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

Future<Map<String, dynamic>> loadClientSecret() async {
  final data = await rootBundle.loadString('assets/secrets/client_secret.json');
  return jsonDecode(data);
}
