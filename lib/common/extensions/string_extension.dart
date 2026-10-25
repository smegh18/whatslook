import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shortzz/common/controller/base_controller.dart';
import 'package:shortzz/common/manager/haptic_manager.dart';
import 'package:shortzz/common/manager/logger.dart';
import 'package:shortzz/common/manager/session_manager.dart';
import 'package:shortzz/common/widget/dominant_color.dart';
import 'package:shortzz/languages/languages_keys.dart';
import 'package:shortzz/model/general/status_model.dart';
import 'package:shortzz/utilities/const_res.dart';
import 'package:url_launcher/url_launcher.dart';

extension StringExtention on String {

  /// ✅ ADD BASE URL
  String addBaseURL() {
    final value = trim();
    if (value.isEmpty) return value;

    final lower = value.toLowerCase();
    if (lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        lower.startsWith('file://') ||
        lower.startsWith('data:')) {
      return value;
    }
    if (lower.startsWith('//')) {
      return 'https:$value';
    }

    final settingsBaseUrl =
        (SessionManager.instance.getSettings()?.itemBaseUrl ?? '').trim();

    String base;
    if (settingsBaseUrl.isNotEmpty) {
      base = settingsBaseUrl.contains('://')
          ? settingsBaseUrl
          : 'https://$settingsBaseUrl';
    } else {
      // Default to server base URL (most hosts already point docroot at Laravel `public/`).
      base = baseURL;
    }

    if (!base.endsWith('/')) base += '/';

    // If backend returns URLs containing `/public/` on a host whose docroot is already `public/`,
    // those URLs 404 (e.g. `/public/storage/...`). Normalize to avoid that.
    try {
      final defaultBase = Uri.parse(baseURL);
      final baseUri = Uri.parse(base);
      if (baseUri.host == defaultBase.host &&
          baseUri.path.toLowerCase().contains('/public/')) {
        base = baseUri
            .replace(path: baseUri.path.replaceAll('/public/', '/'))
            .toString();
        if (!base.endsWith('/')) base += '/';
      }
    } catch (_) {}

    String path = value.startsWith('/') ? value.substring(1) : value;

    // Common backend output: `public/...` (Laravel file paths). Web URLs usually don't include `public/`.
    final pathLower = path.toLowerCase();
    if (pathLower.startsWith('public/')) {
      path = path.substring('public/'.length);
    }

    // Avoid double segments like `/public/public/...` when the backend sends `public/...`
    // and the base already points to the Laravel public directory.
    final basePath = Uri.parse(base).path.toLowerCase();
    if (basePath.endsWith('/public/') && pathLower.startsWith('public/')) {
      path = path.substring('public/'.length);
    }
    if (basePath.endsWith('/storage/') && pathLower.startsWith('storage/')) {
      path = path.substring('storage/'.length);
    }

    // Some deployments store media in `public/uploads/...`, but backend settings may still
    // advertise an `item_base_url` ending in `/storage/` (Laravel storage symlink).
    // That creates wrong URLs like `/storage/uploads/...` (or `/public/storage/uploads/...`).
    // If we see an uploads path, prefer the site root.
    if (basePath.endsWith('/storage/') && pathLower.startsWith('uploads/')) {
      String root = baseURL;
      if (!root.endsWith('/')) root += '/';
      return Uri.parse(root).resolve(path).toString();
    }

    return Uri.parse(base).resolve(path).toString();
  }

  /// ✅ LAUNCH URL WITH HTTPS
  Future<StatusModel> get lunchUrlWithHttps async {
    String url = this;

    if (!startsWith('http')) {
      url = 'https://$this';
    }

    try {
      bool result = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      return StatusModel(status: result, message: 'Success');
    } on PlatformException catch (e) {
      Loggers.error(e);
      return StatusModel(status: false, message: e.code);
    }
  }

  /// ✅ LAUNCH URL
  Future<StatusModel> get lunchUrl async {
    String url = this;

    try {
      bool result = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      return StatusModel(status: result, message: 'Success');
    } on PlatformException catch (e) {
      Loggers.error(e);
      return StatusModel(status: false, message: e.code);
    }
  }

  /// ✅ COPY TEXT
  Future get copyText async {
    try {
      HapticManager.shared.light();
      await Clipboard.setData(ClipboardData(text: this));
      BaseController.share.showSnackBar(LKey.copiedToClipboard.tr);
    } catch (e) {
      BaseController.share.showSnackBar('Failed to copy to clipboard');
    }
  }

  /// ✅ FILE SIZE
  Future<String> get getFileSize async {
    var file = File(this);
    int bytes = await file.length();

    if (bytes <= 0) return "0 B";

    const suffixes = [
      "B","KB","MB","GB","TB","PB","EB","ZB","YB"
    ];

    var i = (log(bytes) / log(1024)).floor();

    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  /// ✅ TIME AGO
  String get timeAgo {
    DateTime time = DateTime.parse(this);
    DateTime now = DateTime.now();

    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime messageDate =
        DateTime(time.year, time.month, time.day);

    Duration diff = now.difference(time);
    int dayDiff = today.difference(messageDate).inDays;

    if (dayDiff == 0) {
      if (diff.inHours > 0) {
        return "${diff.inHours} ${diff.inHours == 1 ? "hour" : "hours"} ago";
      }
      if (diff.inMinutes > 0) {
        return "${diff.inMinutes} ${diff.inMinutes == 1 ? "min" : "mins"} ago";
      }
      return "Now";
    } else if (dayDiff == 1) {
      return "Yesterday";
    } else {
      return DateFormat('dd MMM yyyy').format(time);
    }
  }

  /// ✅ CHAT TIME FORMAT
  String get chatTimeFormat {
    DateTime time =
        DateTime.fromMillisecondsSinceEpoch(int.parse(this));

    DateTime now = DateTime.now();

    DateTime today =
        DateTime(now.year, now.month, now.day);

    DateTime messageDate =
        DateTime(time.year, time.month, time.day);

    Duration dateDiff = today.difference(messageDate);

    if (dateDiff.inDays == 0) {
      return "Today, ${DateFormat('hh:mm a').format(time)}";
    } else if (dateDiff.inDays == 1) {
      return "Yesterday, ${DateFormat('hh:mm a').format(time)}";
    } else {
      return DateFormat('dd MMM, yyyy hh:mm a').format(time);
    }
  }

  String get formatDate =>
      DateFormat('dd MMM, yyyy')
          .format(DateTime.parse(this));

  String get formatDate1 =>
      DateFormat('dd MMMM yyyy')
          .format(DateTime.parse(this));

  String get addHash => '#${replaceAll('#', '')}';

  String get removeHash => replaceAll('#', '');

  /// ✅ IMAGE GRADIENT
  Future<LinearGradient> get getGradientFromImage async {
    List<Color> colors = [];

    Uint8List imageBytes =
        await File(this).readAsBytes();

    try {
      DominantColors extractor =
          DominantColors(
            bytes: imageBytes,
            dominantColorsCount: 5,
          );

      colors = extractor.extractDominantColors();
    } catch (e) {
      colors.clear();
      print(e);
    }

    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: const [0.1, 1],
      colors: [colors.first, colors.last],
    );
  }
}


// import 'dart:io';
// import 'dart:math';

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import 'package:shortzz/common/controller/base_controller.dart';
// import 'package:shortzz/common/manager/haptic_manager.dart';
// import 'package:shortzz/common/manager/logger.dart';
// import 'package:shortzz/common/manager/session_manager.dart';
// import 'package:shortzz/common/widget/dominant_color.dart';
// import 'package:shortzz/languages/languages_keys.dart';
// import 'package:shortzz/model/general/status_model.dart';
// import 'package:url_launcher/url_launcher.dart';

// extension StringExtention on String {
//   String addBaseURL() {
//     final settingsBaseUrl = SessionManager.instance.getSettings()?.itemBaseUrl ?? '';
//     String baseUrl;

//     // More robust fallback logic
//     if (settingsBaseUrl.isNotEmpty && (settingsBaseUrl.startsWith('http://') || settingsBaseUrl.startsWith('https://'))) {
//       // Settings has a valid full URL
//       baseUrl = settingsBaseUrl;
//     } else if (settingsBaseUrl.isNotEmpty && !settingsBaseUrl.contains('://')) {
//       // Settings has a partial URL, prepend https://
//       baseUrl = 'https://$settingsBaseUrl';
//     } else {
//       // Fallback to hardcoded URL
//       baseUrl = 'https://www.whatslook.com/';
//     }

//     // Ensure baseUrl ends with /
//     if (!baseUrl.endsWith('/')) {
//       baseUrl += '/';
//     }

//     // Debug logging
//     print('🔍 addBaseURL - Original: $this');
//     print('🔍 addBaseURL - Settings BaseURL: "$settingsBaseUrl"');
//     print('🔍 addBaseURL - Using BaseURL: "$baseUrl"');
//     print('🔍 addBaseURL - Final URL: ${baseUrl + this}');

//     return baseUrl + this;
//   }

//   Future<StatusModel> get lunchUrlWithHttps async {
//     String url = this;
//     if (!startsWith('http')) {
//       url = 'https://$this';
//     }

//     try {
//       bool result =
//           await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
//       return StatusModel(status: result, message: 'Success');
//     } on PlatformException catch (e) {
//       Loggers.error(e);
//       return StatusModel(status: false, message: e.code);
//     }
//   }

//   Future<StatusModel> get lunchUrl async {
//     String url = this;

//     try {
//       bool result =
//           await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
//       return StatusModel(status: result, message: 'Success');
//     } on PlatformException catch (e) {
//       Loggers.error(e);
//       return StatusModel(status: false, message: e.code);
//     }
//   }

//   Future get copyText async {
//     try {
//       HapticManager.shared.light();
//       await Clipboard.setData(ClipboardData(text: this));
//       BaseController.share.showSnackBar(LKey.copiedToClipboard.tr);
//     } catch (e) {
//       BaseController.share.showSnackBar('Failed to copy to clipboard');
//     }
//   }

//   Future<String> get getFileSize async {
//     var file = File(this);
//     int bytes = await file.length();
//     if (bytes <= 0) return "0 B";
//     const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
//     var i = (log(bytes) / log(1024)).floor();
//     return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
//   }

//   String get timeAgo {
//     DateTime time = DateTime.parse(this);
//     DateTime now = DateTime.now();

//     DateTime today = DateTime(now.year, now.month, now.day);
//     DateTime messageDate = DateTime(time.year, time.month, time.day);

//     Duration diff = now.difference(time);
//     int dayDiff = today.difference(messageDate).inDays;

//     if (dayDiff == 0) {
//       if (diff.inHours > 0) {
//         return "${diff.inHours} ${diff.inHours == 1 ? "hour" : "hours"} ago";
//       }
//       if (diff.inMinutes > 0) {
//         return "${diff.inMinutes} ${diff.inMinutes == 1 ? "min" : "mins"} ago";
//       }
//       return "Now";
//     } else if (dayDiff == 1) {
//       return "Yesterday";
//     } else {
//       return DateFormat('dd MMM yyyy').format(time);
//     }
//   }

//   String get chatTimeFormat {
//     DateTime time = DateTime.fromMillisecondsSinceEpoch(int.parse(this));
//     DateTime now = DateTime.now();

//     // Remove time part for accurate day comparison
//     DateTime today = DateTime(now.year, now.month, now.day);
//     DateTime messageDate = DateTime(time.year, time.month, time.day);

//     Duration dateDiff = today.difference(messageDate);

//     if (dateDiff.inDays == 0) {
//       return "Today, ${DateFormat('hh:mm a').format(time)}";
//     } else if (dateDiff.inDays == 1) {
//       return "Yesterday, ${DateFormat('hh:mm a').format(time)}";
//     } else {
//       return DateFormat('dd MMM, yyyy hh:mm a').format(time);
//     }
//   }

//   String get formatDate =>
//       DateFormat('dd MMM, yyyy').format(DateTime.parse(this));

//   String get formatDate1 =>
//       DateFormat('dd MMMM yyyy').format(DateTime.parse(this));

//   String get addHash {
//     return '#${replaceAll('#', '')}';
//   }

//   String get removeHash {
//     return replaceAll('#', '');
//   }

//   Future<LinearGradient> get getGradientFromImage async {
//     List<Color> colors = [];
//     Uint8List imageBytes = await File(this).readAsBytes();
//     print(imageBytes);
//     try {
//       DominantColors extractor =
//           DominantColors(bytes: imageBytes, dominantColorsCount: 5);

//       List<Color> dominantColors = extractor.extractDominantColors();
//       colors = dominantColors;
//     } catch (e) {
//       colors.clear();
//       print(e);
//     }

//     return LinearGradient(
//       begin: Alignment.topCenter,
//       end: Alignment.bottomCenter,
//       stops: const [0.1, 1],
//       colors: [colors.first, colors.last],
//     );
//   }
// }
