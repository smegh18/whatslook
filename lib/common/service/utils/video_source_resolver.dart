import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shortzz/common/extensions/string_extension.dart';
import 'package:shortzz/common/manager/logger.dart';

class VideoSourceResolver {
  VideoSourceResolver._();

  static const Map<String, String> httpHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 15) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36',
    'Accept': '*/*',
  };

  static final Map<String, Future<List<String>>> _playableUrlsCache = {};
  static final Map<String, Future<File?>> _videoPrefetchInFlight = {};

  static Future<List<String>> playableUrls(String rawVideoUrl) {
    final key = rawVideoUrl.trim();
    if (key.isEmpty) {
      return Future.value(const []);
    }

    return _playableUrlsCache.putIfAbsent(key, () async {
      final urls = <String>{};

      for (final candidate in _videoUrlCandidates(key)) {
        if (candidate.isEmpty) {
          continue;
        }
        urls.add(candidate);

        final shouldResolveRedirect = _looksLikeShortLink(candidate) ||
            _hasLeadingPublicSegment(candidate);
        if (!shouldResolveRedirect) {
          continue;
        }

        final resolved = await _resolveFinalUrl(candidate);
        if (resolved == null || resolved.isEmpty) {
          continue;
        }

        urls.add(resolved);
        urls.addAll(_videoUrlCandidates(resolved));
      }

      return urls.toList(growable: false);
    });
  }

  static Future<void> prefetchPlayableUrls(Iterable<String?> rawVideoUrls,
      {int limit = 4}) async {
    final candidates = rawVideoUrls
        .map((value) => value?.trim() ?? '')
        .where((value) => value.isNotEmpty)
        .take(limit)
        .toList(growable: false);

    if (candidates.isEmpty) {
      return;
    }

    await Future.wait(
      candidates.map(playableUrls),
      eagerError: false,
    );
  }

  static Future<File?> cachedVideoFile(String rawVideoUrl) async {
    final urls = await playableUrls(rawVideoUrl);
    for (final url in urls) {
      final cache = await DefaultCacheManager().getFileFromCache(url);
      final file = cache?.file;
      if (file != null && await file.exists()) {
        return file;
      }
    }
    return null;
  }

  static Future<File?> prefetchVideoFile(String rawVideoUrl) {
    final key = rawVideoUrl.trim();
    if (key.isEmpty) {
      return Future.value(null);
    }

    final existing = _videoPrefetchInFlight[key];
    if (existing != null) {
      return existing;
    }

    final future = _prefetchVideoFileInternal(key);
    _videoPrefetchInFlight[key] = future;
    future.whenComplete(() {
      if (identical(_videoPrefetchInFlight[key], future)) {
        _videoPrefetchInFlight.remove(key);
      }
    });
    return future;
  }

  static Future<File?> waitForPrefetchIfRunning(String rawVideoUrl,
      {Duration timeout = const Duration(milliseconds: 80)}) async {
    final key = rawVideoUrl.trim();
    if (key.isEmpty) {
      return null;
    }

    final future = _videoPrefetchInFlight[key];
    if (future == null) {
      return null;
    }

    try {
      return await future.timeout(timeout);
    } catch (_) {
      return null;
    }
  }

  static Future<File?> _prefetchVideoFileInternal(String rawVideoUrl) async {
    final urls = await playableUrls(rawVideoUrl);
    for (final url in urls) {
      try {
        final cached = await DefaultCacheManager().getFileFromCache(url);
        final cachedFile = cached?.file;
        if (cachedFile != null && await cachedFile.exists()) {
          return cachedFile;
        }

        final file = await DefaultCacheManager()
            .getSingleFile(url, headers: httpHeaders);
        if (await file.exists()) {
          return file;
        }
      } catch (e) {
        if (kDebugMode) {
          Loggers.error('VIDEO cache warm failed: $e | url="$url"');
        }
      }
    }
    return null;
  }

  static Future<void> warmVideoFiles(Iterable<String?> rawVideoUrls,
      {int limit = 2}) async {
    final candidates = rawVideoUrls
        .map((value) => value?.trim() ?? '')
        .where((value) => value.isNotEmpty)
        .take(limit)
        .toList(growable: false);

    if (candidates.isEmpty) {
      return;
    }

    await Future.wait(
      candidates.map(prefetchVideoFile),
      eagerError: false,
    );
  }

  static Uri safeUri(String url) {
    try {
      return Uri.parse(url);
    } catch (_) {
      return Uri.parse(Uri.encodeFull(url));
    }
  }

  static List<String> _videoUrlCandidates(String video) {
    final set = <String>{};
    final resolved = video.addBaseURL();
    if (resolved.isEmpty) {
      return const [];
    }

    set.add(resolved);

    try {
      final uri = safeUri(resolved);
      final segments = List<String>.from(uri.pathSegments);
      if (segments.isNotEmpty) {
        final first = segments.first.toLowerCase();
        if (first == 'public') {
          set.add(uri.replace(pathSegments: segments.sublist(1)).toString());
        } else {
          set.add(
              uri.replace(pathSegments: ['public', ...segments]).toString());
        }
      }
    } catch (_) {}

    return set.where((value) => value.isNotEmpty).toList(growable: false);
  }

  static bool _looksLikeShortLink(String url) {
    try {
      final uri = safeUri(url);
      return uri.pathSegments.isNotEmpty &&
          uri.pathSegments.first.toLowerCase() == 's';
    } catch (_) {
      return url.contains('/s/');
    }
  }

  static bool _hasLeadingPublicSegment(String url) {
    try {
      final uri = safeUri(url);
      return uri.pathSegments.isNotEmpty &&
          uri.pathSegments.first.toLowerCase() == 'public';
    } catch (_) {
      return url.toLowerCase().contains('/public/');
    }
  }

  static Future<String?> _resolveFinalUrl(String url) async {
    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 6);

      Uri current = safeUri(url);
      for (int i = 0; i < 6; i++) {
        final request = await client.getUrl(current);
        request.followRedirects = false;
        request.maxRedirects = 0;
        request.headers.set('User-Agent', httpHeaders['User-Agent'] ?? '');

        final response = await request.close();
        final statusCode = response.statusCode;
        await response.drain();

        if (statusCode >= 300 && statusCode < 400) {
          final location = response.headers.value(HttpHeaders.locationHeader);
          if (location == null || location.trim().isEmpty) {
            return current.toString();
          }
          current = current.resolve(location.trim());
          continue;
        }

        return current.toString();
      }

      return current.toString();
    } catch (e) {
      if (kDebugMode) {
        Loggers.error('VIDEO resolve redirect failed: $e | url="$url"');
      }
      return null;
    } finally {
      client?.close(force: true);
    }
  }
}
