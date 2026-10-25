import 'dart:async';
import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:http/http.dart' as http;
import 'package:shortzz/common/extensions/string_extension.dart';
import 'package:shortzz/common/manager/logger.dart';
import 'package:shortzz/model/general/settings_model.dart';

class LanguageLoader {
  LanguageLoader._();

  static final LanguageLoader instance = LanguageLoader._();

  Future<Map<String, Map<String, String>>> downloadAndParseLanguages(
    List<Language> languages, {
    int maxConcurrentDownloads = 3,
  }) async {
    final enabled = languages
        .where(
            (l) => (l.status ?? 0) == 1 && l.code != null && l.csvFile != null)
        .toList();

    final languageData = <String, Map<String, String>>{};
    final active = <Future<void>>{};

    for (final language in enabled) {
      late final Future<void> task;
      task = _downloadAndProcessLanguage(language, languageData)
          .whenComplete(() => active.remove(task));
      active.add(task);

      if (active.length >= maxConcurrentDownloads) {
        await Future.any(active);
      }
    }

    await Future.wait(active);
    return languageData;
  }

  Future<void> _downloadAndProcessLanguage(
    Language language,
    Map<String, Map<String, String>> languageData,
  ) async {
    try {
      final url = language.csvFile?.addBaseURL() ?? '';
      if (url.isEmpty || language.code == null) return;

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        Loggers.error(
            'Failed to download ${language.code}: ${response.statusCode}');
        return;
      }

      final csvContent = utf8.decode(response.bodyBytes);
      languageData[language.code!] = _parseCsvToMap(csvContent);
    } catch (e) {
      Loggers.error('Error downloading ${language.code}: $e');
    }
  }

  Map<String, String> _parseCsvToMap(String csvContent) {
    final rows = const CsvToListConverter().convert(csvContent);
    final map = <String, String>{};

    for (final row in rows) {
      if (row.length >= 2) {
        map[row[0].toString()] = row[1].toString();
      }
    }
    return map;
  }
}

