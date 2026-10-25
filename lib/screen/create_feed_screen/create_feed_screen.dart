import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shortzz/common/widget/custom_app_bar.dart';
import 'package:shortzz/common/widget/loader_widget.dart';
import 'package:shortzz/common/widget/search_result_tile.dart';
import 'package:shortzz/common/widget/text_button_custom.dart';
import 'package:shortzz/common/widget/user_list.dart';
import 'package:shortzz/languages/languages_keys.dart';
import 'package:shortzz/model/post_story/hashtag_model.dart';
import 'package:shortzz/model/post_story/post_model.dart';
import 'package:shortzz/model/user_model/user_model.dart';
import 'package:shortzz/screen/camera_screen/camera_screen_controller.dart';
import 'package:shortzz/screen/create_feed_screen/create_feed_screen_controller.dart';
import 'package:shortzz/screen/dashboard_screen/dashboard_screen_controller.dart';
import 'package:shortzz/screen/create_feed_screen/widget/create_feed_location_bar.dart';
import 'package:shortzz/screen/create_feed_screen/widget/feed_comment_toggle.dart';
import 'package:shortzz/screen/create_feed_screen/widget/feed_image_view.dart';
import 'package:shortzz/screen/create_feed_screen/widget/feed_text_field_view.dart';
import 'package:shortzz/screen/create_feed_screen/widget/feed_video_view.dart';
import 'package:shortzz/screen/create_feed_screen/widget/reel_preview_card.dart';
import 'package:shortzz/screen/create_feed_screen/widget/url_meta_data_card.dart';
import 'package:shortzz/utilities/app_res.dart';
import 'package:shortzz/utilities/asset_res.dart';
import 'package:shortzz/utilities/theme_res.dart';

enum CreateFeedType { feed, reel }

class CreateFeedScreen extends StatefulWidget {
  final CreateFeedType createType;
  final PostStoryContent? content;
  final Function({Post? post, CreateFeedType? type})? onAddPost;

  const CreateFeedScreen(
      {super.key, required this.createType, this.onAddPost, this.content});

  @override
  State<CreateFeedScreen> createState() => _CreateFeedScreenState();
}

class _CreateFeedScreenState extends State<CreateFeedScreen> {
  late final CreateFeedScreenController controller;
  late final String controllerTag;

  @override
  void initState() {
    super.initState();
    controllerTag = 'create-feed-${DateTime.now().microsecondsSinceEpoch}';
    controller = Get.put(
      CreateFeedScreenController(
          widget.onAddPost, widget.createType, widget.content.obs),
      tag: controllerTag,
    );
  }

  @override
  void dispose() {
    if (Get.isRegistered<CreateFeedScreenController>(tag: controllerTag)) {
      Get.delete<CreateFeedScreenController>(tag: controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBackgroundColor(context),
      body: Column(
        children: [
          CustomAppBar(
            title: LKey.createFeed.tr,
            bgColor: scaffoldBackgroundColor(context),
            iconColor: whitePure(context),
            titleStyle: TextStyle(
              color: whitePure(context),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () =>
                  controller.commentHelper.detectableTextFocusNode.unfocus(),
              child: widget.createType == CreateFeedType.reel
                  ? _reelComposerView(controller, context)
                  : Stack(
                      children: [
                        Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    ReelPreviewCard(controller: controller),
                                    CreateFeedLocationBar(
                                        controller: controller),
                                    FeedTextFieldView(controller: controller),
                                    UrlMetaDataCard(controller: controller),
                                    mediaSelectionView(controller),
                                    const SizedBox(height: 5),
                                    Obx(
                                      () => switch (
                                            controller.feedPostType.value) {
                                        FeedPostType.text => const SizedBox(),
                                        FeedPostType.image => FeedImageView(
                                            files: controller.images,
                                            controller: controller),
                                        FeedPostType.video =>
                                          FeedVideoView(controller: controller),
                                      },
                                    ),
                                    FeedCommentToggle(controller: controller),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              ),
                            ),
                            SafeArea(
                              top: false,
                              child: Container(
                                color: scaffoldBackgroundColor(context),
                                padding:
                                    const EdgeInsets.fromLTRB(20, 12, 20, 12),
                                child: _uploadButton(controller, context),
                              ),
                            ),
                          ],
                        ),
                        Obx(() => mentionOrHashtagView(controller, context)),
                        _postUploadOverlay(controller, context),
                      ],
                    ),
            ),
          )
        ],
      ),
    );
  }

  Widget _reelComposerView(
      CreateFeedScreenController controller, BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _basicReelPreview(context, controller),
                    const SizedBox(height: 16),
                    Obx(() {
                      final place = controller.selectedLocation.value;
                      if (place == null) return const SizedBox();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: resolveButtonBackground(
                            context,
                            preferred: bgLightGrey(context),
                            fallback: buttonSecondary(context),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                place.placeTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: textDarkGrey(context),
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  controller.selectedLocation.value = null,
                              icon: Icon(Icons.close,
                                  color: textLightGrey(context), size: 18),
                            )
                          ],
                        ),
                      );
                    }),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: resolveButtonBackground(
                          context,
                          preferred: bgLightGrey(context),
                          fallback: buttonSecondary(context),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller:
                            controller.commentHelper.detectableTextController,
                        focusNode:
                            controller.commentHelper.detectableTextFocusNode,
                        minLines: 4,
                        maxLines: 8,
                        style: TextStyle(
                          color: textDarkGrey(context),
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: LKey.writeSomethingHere.tr,
                          hintStyle: TextStyle(
                            color: textLightGrey(context),
                            fontSize: 16,
                          ),
                        ),
                        onChanged: controller.commentHelper.onChanged,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Obx(() => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: resolveButtonBackground(
                              context,
                              preferred: bgLightGrey(context),
                              fallback: buttonSecondary(context),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  LKey.allowComments.tr,
                                  style: TextStyle(
                                    color: textDarkGrey(context),
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Switch(
                                value: controller.canComment.value,
                                onChanged: (value) =>
                                    controller.canComment.value = value,
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                color: scaffoldBackgroundColor(context),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: _uploadButton(controller, context),
              ),
            ),
          ],
        ),
        _reelUploadOverlay(controller, context),
      ],
    );
  }

  Widget _basicReelPreview(
      BuildContext context, CreateFeedScreenController controller) {
    return Obx(() {
      final reelContent = controller.content.value;
      final thumbnailBytes = reelContent?.thumbnailBytes;
      final thumbnailPath = reelContent?.thumbNail ?? '';

      Widget child;
      if (thumbnailBytes != null && thumbnailBytes.isNotEmpty) {
        child = Image.memory(thumbnailBytes, fit: BoxFit.cover);
      } else if (thumbnailPath.isNotEmpty &&
          File(thumbnailPath).existsSync()) {
        child = Image.file(File(thumbnailPath), fit: BoxFit.cover);
      } else {
        child = Container(
          color: Colors.grey.shade700,
          alignment: Alignment.center,
          child: Icon(Icons.video_library_outlined,
              color: whitePure(context), size: 42),
        );
      }

      return Center(
        child: Container(
          width: 180,
          height: 280,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(16),
          ),
          child: child,
        ),
      );
    });
  }

  Widget mediaSelectionView(CreateFeedScreenController controller) {
    return Obx(
        () => controller.images.isNotEmpty || controller.video.value != null
            ? const SizedBox()
            : Row(
                children: [
                  BuildImageContainer(
                      image: AssetRes.icImage,
                      onTap: () => controller.onMediaTap(FeedPostType.image)),
                  const SizedBox(width: 5),
                  BuildImageContainer(
                      image: AssetRes.icVideo,
                      onTap: () => controller.onMediaTap(FeedPostType.video)),
                ],
              ));
  }

  Widget _uploadButton(
      CreateFeedScreenController controller, BuildContext context) {
    if (widget.createType == CreateFeedType.reel) {
      return Obx(() {
        final isUploading =
            controller.uploadType.value == UploadType.uploading;
        final progress = controller.progress.value.clamp(0, 100).toInt();

        return TextButtonCustom(
          onTap: controller.handleUpload,
          title: LKey.uploadNow.tr,
          backgroundColor:
              _resolveUploadButtonBackgroundColor(context, isUploading),
          titleColor: whitePure(context),
          margin: EdgeInsets.zero,
          child: isUploading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          whitePure(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$progress% ${LKey.postIsBeginUploading.tr}',
                      style: TextStyle(
                        color: whitePure(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : null,
        );
      });
    }

    return Obx(() {
      final isUploading =
          controller.uploadType.value == UploadType.uploading;
      final isEmpty = controller.commentHelper.isDetectableTextEmpty.value &&
          controller.feedPostType.value == FeedPostType.text;
      final backgroundColor =
          _resolveUploadButtonBackgroundColor(context, isEmpty || isUploading);
      final titleColor = whitePure(context)
          .withValues(alpha: (isEmpty || isUploading) ? .7 : 1);

      return TextButtonCustom(
        onTap: controller.handleUpload,
        title: LKey.uploadNow.tr,
        backgroundColor: backgroundColor,
        titleColor: titleColor,
        margin: EdgeInsets.zero,
        child: isUploading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        whitePure(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${controller.progress.value.clamp(0, 100).toInt()}% ${LKey.postIsBeginUploading.tr}',
                    style: TextStyle(
                      color: whitePure(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : null,
      );
    });
  }

  Widget _postUploadOverlay(
      CreateFeedScreenController controller, BuildContext context) {
    return Obx(() {
      if (controller.uploadType.value != UploadType.uploading) {
        return const SizedBox();
      }

      final progress = controller.progress.value.clamp(0, 100);

      return Positioned.fill(
        child: AbsorbPointer(
          child: Container(
            color: Colors.black.withValues(alpha: .18),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 320),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: blackPure(context).withValues(alpha: .92),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LoaderWidget(),
                  const SizedBox(height: 16),
                  Text(
                    LKey.postIsBeginUploading.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: whitePure(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: progress <= 0 ? null : progress / 100,
                      backgroundColor: Colors.white.withValues(alpha: .18),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        themeAccentSolid(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${progress.toInt()}%',
                    style: TextStyle(
                      color: whitePure(context),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _reelUploadOverlay(
      CreateFeedScreenController controller, BuildContext context) {
    return Obx(() {
      if (controller.uploadType.value != UploadType.uploading) {
        return const SizedBox();
      }

      final progress = controller.progress.value.clamp(0, 100);

      return Positioned.fill(
        child: AbsorbPointer(
          child: Container(
            color: Colors.black.withValues(alpha: .28),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 320),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: blackPure(context).withValues(alpha: .92),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LoaderWidget(),
                  const SizedBox(height: 16),
                  Text(
                    LKey.postIsBeginUploading.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: whitePure(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: progress <= 0 ? null : progress / 100,
                      backgroundColor: Colors.white.withValues(alpha: .18),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        themeAccentSolid(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${progress.toInt()}%',
                    style: TextStyle(
                      color: whitePure(context),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Color _resolveUploadButtonBackgroundColor(
      BuildContext context, bool isDisabled) {
    final fallbackColor = green(context);
    final configuredColor = textDarkGrey(context);
    final shouldUseFallback = configuredColor.alpha == 0 ||
        configuredColor.computeLuminance() > 0.55;
    final effectiveColor =
        shouldUseFallback ? fallbackColor : configuredColor;

    return effectiveColor.withValues(alpha: isDisabled ? .55 : 1);
  }

  Widget mentionOrHashtagView(
      CreateFeedScreenController controller, BuildContext context) {
    if (!controller.commentHelper.isMentionUserView.value &&
        !controller.commentHelper.isHashTagView.value) {
      return const SizedBox();
    }
    final bool isMentionView = controller.commentHelper.isMentionUserView.value;
    final items = isMentionView
        ? controller.commentHelper.searchUsers
        : controller.commentHelper.hashTags;

    itemBuilder(context, index) {
      final item = items[index];
      if (isMentionView) {
        User user = item as User;
        return UserCard(
          onTap: () => controller.commentHelper
              .appendDetection(user, DetectType.atSign, type: 1),
          fullName: user.fullname,
          profilePhoto: user.profilePhoto,
          userName: user.username,
        );
      }
      Hashtag hashtag = item as Hashtag;
      return SearchResultTile(
        description: '${hashtag.postCount} ${LKey.posts.tr}',
        title: '${AppRes.hash}${hashtag.hashtag ?? ' '}',
        onTap: () => controller.commentHelper
            .appendDetection(hashtag, DetectType.hashTag, type: 1),
        image: AssetRes.icHashtag,
      );
    }

    return Container(
      color: (!controller.commentHelper.isLoading.value && items.isEmpty)
          ? null
          : bgLightGrey(context),
      height: double.infinity,
      width: double.infinity,
      margin: const EdgeInsets.only(top: 180),
      child: controller.commentHelper.isLoading.value
          ? const LoaderWidget()
          : items.isEmpty
              ? const SizedBox()
              : ListView.builder(
                  itemCount: items.length,
                  padding: const EdgeInsets.only(top: 5, left: 13, right: 13),
                  itemBuilder: itemBuilder),
    );
  }
}

class BuildImageContainer extends StatelessWidget {
  final String image;
  final VoidCallback onTap;

  const BuildImageContainer(
      {super.key, required this.image, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final buttonColor = resolveButtonBackground(
      context,
      preferred: bgLightGrey(context),
      fallback: buttonSecondary(context),
    );

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 59,
          decoration: BoxDecoration(color: buttonColor),
          child: Center(
            child: Image.asset(image,
                color: whitePure(context), height: 29, width: 29),
          ),
        ),
      ),
    );
  }
}
