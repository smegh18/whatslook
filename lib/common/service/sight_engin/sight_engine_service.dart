import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter_native_video_trimmer/flutter_native_video_trimmer.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shortzz/common/controller/base_controller.dart';
import 'package:shortzz/common/manager/logger.dart';
import 'package:shortzz/common/manager/session_manager.dart';
import 'package:shortzz/languages/languages_keys.dart';
import 'package:shortzz/model/sight_engine/sight_engine_media_model.dart';
import 'package:shortzz/model/sight_engine/text_moderation_model.dart';
import 'package:shortzz/utilities/app_res.dart';

class SightEngineService {
  static var shared = SightEngineService();
  static bool _videoModerationSupported = true;

  String _apiUser() =>
      (SessionManager.instance.getSettings()?.sightEngineApiUser ?? '').trim();

  String _apiSecret() =>
      (SessionManager.instance.getSettings()?.sightEngineApiSecret ?? '').trim();

  String _imageWorkflow() => (SessionManager
              .instance.getSettings()?.sightEngineImageWorkflowId ?? '')
          .trim();

  String _videoWorkflow() => (SessionManager
              .instance.getSettings()?.sightEngineVideoWorkflowId ?? '')
          .trim();

  bool _isModerationEnabled() =>
      (SessionManager.instance.getSettings()?.isContentModeration ?? 0) != 0;

  bool _shouldBypassVideoModeration(SightEngineMediaModel model) {
    final msg = (model.error?.message ?? '').toLowerCase();
    // Sightengine paid-plan limitation message.
    return msg.contains('video analysis') ||
        msg.contains('not available on the free plan') ||
        msg.contains('switch to a paid plan') ||
        msg.contains('pricing');
  }

  Future<void> checkImagesInSightEngine({
    required List<XFile> xFiles,
    required Function() completion,
  }) async {
    if (!_isModerationEnabled()) {
      completion();
      return;
    }
    final apiUser = _apiUser();
    final apiSecret = _apiSecret();
    final workflow = _imageWorkflow();
    if (apiUser.isEmpty || apiSecret.isEmpty || workflow.isEmpty) {
      // Missing config; do not block upload.
      completion();
      return;
    }
    BaseController.share.showLoader();
    var request = http.MultipartRequest('POST',
        Uri.parse('https://api.sightengine.com/1.0/check-workflow.json'));

    request.fields['workflow'] = workflow;
    request.fields['api_user'] = apiUser;
    request.fields['api_secret'] = apiSecret;

    for (XFile xFile in xFiles) {
      File file = File(xFile.path);
      request.files.add(
        http.MultipartFile(
          'media',
          file.readAsBytes().asStream(),
          file.lengthSync(),
          filename: file.path.split("/").last,
        ),
      );
    }

    var response = await request.send();
    var respStr = await response.stream.bytesToString();
    SightEngineMediaModel sightEngineMediaModel =
        SightEngineMediaModel.fromJson(jsonDecode(respStr));

    if (sightEngineMediaModel.error != null) {
      BaseController.share.stopLoader();
      Loggers.error(sightEngineMediaModel.error?.message);
      BaseController.share
          .showSnackBar(sightEngineMediaModel.error?.message ?? '');
      return;
    }

    var result = sightEngineMediaModel.summary?.action ?? '';

    BaseController.share.stopLoader();
    if (result == 'accept') {
      completion(); // All images accepted
    } else if (result == 'reject') {
      var summaryDescription = sightEngineMediaModel.summary?.rejectReason
              ?.map((e) => e.text ?? '')
              .join(', ') ??
          '';
      BaseController.share.showSnackBar(
          '${LKey.mediaRejectedAndContainsSuchThings.tr} $summaryDescription');
    }
  }

  Future<void> checkVideoInSightEngine({required XFile xFile,
    required int duration,
    required Function() completion}) async {
    if (!_isModerationEnabled()) {
      completion();
      return;
    }
    if (!_videoModerationSupported) {
      completion();
      return;
    }
    final apiUser = _apiUser();
    final apiSecret = _apiSecret();
    final workflow = _videoWorkflow();
    if (apiUser.isEmpty || apiSecret.isEmpty || workflow.isEmpty) {
      // Missing config; do not block upload.
      completion();
      return;
    }

    File file = File(xFile.path);
    BaseController.share.showLoader();
    if (duration > AppRes.sightEngineCropSec) {
      final videoTrimmer = VideoTrimmer();
      try {
        await videoTrimmer.loadVideo(file.path);
      } catch (e) {
        Loggers.error(e);
      }
      final trimmedPath = await videoTrimmer.trimVideo(
        startTimeMs: 0,
        endTimeMs: AppRes.sightEngineCropSec * 1000,
        includeAudio: false,
      );
      if (trimmedPath != null && trimmedPath.trim().isNotEmpty) {
        file = File(trimmedPath);
      }
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse(
          'https://api.sightengine.com/1.0/video/check-workflow-sync.json'),
    );
    request.fields['workflow'] = workflow;
    request.fields['api_user'] = apiUser;
    request.fields['api_secret'] = apiSecret;

    request.files.add(
      http.MultipartFile(
          'media', file.readAsBytes().asStream(), file.lengthSync(),
          filename: file.path.split("/").last),
    );

    var response = await request.send();
    var respStr = await response.stream.bytesToString();
    SightEngineMediaModel sightEngineMediaModel;
    try {
      sightEngineMediaModel =
          SightEngineMediaModel.fromJson(jsonDecode(respStr));
    } catch (e) {
      BaseController.share.stopLoader();
      Loggers.error('SightEngine video moderation invalid response: $e');
      // Do not block upload on moderation parsing failures.
      completion();
      return;
    }

    if (sightEngineMediaModel.error != null) {
      BaseController.share.stopLoader();
      if (_shouldBypassVideoModeration(sightEngineMediaModel)) {
        _videoModerationSupported = false;
        Loggers.info(
            'SightEngine video moderation skipped: ${sightEngineMediaModel.error?.message}');
        completion();
        return;
      }
      BaseController.share
          .showSnackBar(sightEngineMediaModel.error?.message ?? '');
      return;
    }
    var result = sightEngineMediaModel.summary?.action ?? '';
    BaseController.share.stopLoader();
    if (result == 'accept') {
      completion();
    } else if (result == 'reject') {
      var summaryDescription = sightEngineMediaModel.summary?.rejectReason
              ?.map((e) => e.text ?? '')
              .join(', ') ??
          '';
      BaseController.share.showSnackBar(
          '${LKey.mediaRejectedAndContainsSuchThings.tr} $summaryDescription');
    }
  }

  Future<void> chooseTextModeration(
      {required String text, required Function() completion}) async {
    if (!_isModerationEnabled()) {
      completion();
      return;
    }
    if (text.isEmpty) {
      completion();
      return;
    }
    final apiUser = _apiUser();
    final apiSecret = _apiSecret();
    if (apiUser.isEmpty || apiSecret.isEmpty) {
      completion();
      return;
    }
    BaseController.share.showLoader();
    var request = http.MultipartRequest(
        'POST', Uri.parse('https://api.sightengine.com/1.0/text/check.json'));
    request.fields.addAll({
      'text': text,
      'lang': 'en,zh,da,nl,fi,fr,de,it,no,pl,pt,es,sv,tl,tr',
      'categories': 'profanity',
      'mode': 'rules',
      'api_user': apiUser,
      'api_secret': apiSecret,
    });

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      var respStr = await response.stream.bytesToString();
      TextModerationModel textModerationModel =
          TextModerationModel.fromJson(jsonDecode(respStr));
      List<Matches> matches = textModerationModel.profanity?.matches ?? [];
      print(jsonDecode(respStr));
      if (textModerationModel.error != null) {
        BaseController.share.stopLoader();
        BaseController.share
            .showSnackBar(textModerationModel.error?.message ?? '');
        return;
      }
      List<String> words = [];

      for (var element in matches) {
        if (element.intensity == 'high' || element.intensity == 'medium') {
          words.add(element.match ?? '');
        }
      }

      BaseController.share.stopLoader();
      if (words.isEmpty) {
        completion();
      } else {
        log('${LKey.textRejectedAndContainsSuchThings.tr} ${words.join(', ')}');
        BaseController.share.showSnackBar(
            '${LKey.textRejectedAndContainsSuchThings.tr} ${words.join(', ')}');
      }
    } else {
      log(response.reasonPhrase ?? '');
    }
  }
}
