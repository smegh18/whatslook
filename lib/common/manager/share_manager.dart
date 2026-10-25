import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shortzz/common/manager/logger.dart';
import 'package:shortzz/common/service/api/post_service.dart';
import 'package:shortzz/model/post_story/post_model.dart';
import 'package:shortzz/model/user_model/user_model.dart';
import 'package:shortzz/screen/share_sheet_widget/share_sheet_widget.dart';
import 'package:shortzz/utilities/const_res.dart';

enum ShareKeys {
  reel('reel'),
  post('post'),
  user("user");

  const ShareKeys(this.value);

  final String value;
}

class ShareManager {
  static var shared = ShareManager();
  var isListenerConfigured = false;

  void listen(Function(String key, int value) completion) {
    if (isListenerConfigured) return;
    isListenerConfigured = true;
    AppLinks().uriLinkStream.listen((uri) {
      Loggers.info('Share Link Opened: $uri ${uri.pathSegments} ${uri.path}');
      getValuesFromURL(url: uri.toString(), completion: completion);
    });
  }

  bool getValuesFromURL({
    required String url,
    required Function(String key, int value) completion,
  }) {
    try {
      final uri = Uri.parse(url.trim());
      if (uri.pathSegments.isEmpty) return false;

      final encoded = uri.pathSegments.last;
      final decoded = safeBase64Decode(encoded);
      final values = decoded.split('_');
      if (values.length != 2) return false;

      final value = int.tryParse(values.last);
      if (value == null) return false;

      completion(values.first, value);
      return true;
    } catch (e) {
      Loggers.error('Invalid share URL: $e');
      return false;
    }
  }

  void shareTheContent({required ShareKeys key, required int value}) {
    final encoded = safeBase64Encode('${key.value}_$value');
    final url = '${baseURL}s/$encoded';
    final context = Get.context!;

    final box = context.findRenderObject() as RenderBox?;
    final origin = box!.localToGlobal(Offset.zero) & box.size;

    // Share.share("$url", sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size);
    SharePlus.instance
        .share(ShareParams(uri: Uri.parse(url), sharePositionOrigin: origin));
  }

  String getLink({required ShareKeys key, required int value}) {
    final encoded = safeBase64Encode('${key.value}_$value');
    final url = '${baseURL}s/$encoded';
    return url;
  }

  String safeBase64Encode(String input) {
    // Encode normally
    String encoded = base64.encode(utf8.encode(input));

    // Remove all '=' padding at the end
    return encoded.replaceAll('=', '');
  }

  String safeBase64Decode(String input) {
    // Remove all whitespace
    input = input.trim();
    // Remove any invalid padding (> 2 '=' at end)
    input = input.replaceAll(RegExp(r'=+$'), '');

    // Add correct padding (base64 should be multiple of 4)
    while (input.length % 4 != 0) {
      input += '=';
    }

    return utf8.decode(base64.decode(input));
  }

  void showCustomShareSheet({
    User? user,
    Post? post,
    required ShareKeys keys,
    VoidCallback? onShareSuccess,
  }) {
    int? id = keys == ShareKeys.user ? user?.id : post?.id;
    String link = getLink(key: keys, value: id ?? -1);
    Get.bottomSheet(
      ShareSheetWidget(
        onMoreTap: () {
          Get.back();
          if (keys == ShareKeys.post || keys == ShareKeys.reel) {
            shareTheContent(key: keys, value: post?.id ?? -1);
            _increaseShareCount(post?.id, onShareSuccess);
          } else if (keys == ShareKeys.user) {
            shareTheContent(key: keys, value: user?.id ?? -1);
          }
        },
        post: post,
        link: link,
        isDownloadShow: keys == ShareKeys.reel,
        keys: keys,
        onCallBack: onShareSuccess,
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _increaseShareCount(int? postId, VoidCallback? onSuccess) async {
    if (postId == null) return;
    final response =
        await PostService.instance.increaseShareCount(postId: postId);
    if (response.status == true) {
      onSuccess?.call();
    }
  }
}
