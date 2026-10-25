import 'package:detectable_text_field/detectable_text_field.dart';
import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shortzz/languages/languages_keys.dart';
import 'package:shortzz/screen/comment_sheet/helper/comment_helper.dart';
import 'package:shortzz/screen/create_feed_screen/create_feed_screen_controller.dart';
import 'package:shortzz/screen/create_feed_screen/widget/hash_tag_sheet.dart';
import 'package:shortzz/screen/create_feed_screen/widget/location_sheet.dart';
import 'package:shortzz/screen/create_feed_screen/widget/mention_sheet.dart';
import 'package:shortzz/utilities/text_style_custom.dart';
import 'package:shortzz/utilities/theme_res.dart';

class FeedTextFieldView extends StatelessWidget {
  final CreateFeedScreenController controller;

  const FeedTextFieldView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    CommentHelper helper = controller.commentHelper;
    GlobalKey globalKey = GlobalKey();
    return Obx(() {
      final hasMedia =
          controller.images.isNotEmpty || controller.video.value != null;
      final minLines = hasMedia ? 3 : 4;
      final maxLines = hasMedia ? 5 : 7;

      return AnimatedContainer(
        key: globalKey,
        duration: const Duration(milliseconds: 180),
        constraints: BoxConstraints(minHeight: hasMedia ? 124 : 144),
        color: bgLightGrey(context),
        margin: const EdgeInsets.symmetric(vertical: 5),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: DetectableTextField(
                onTap: () async {
                  await Future.delayed(const Duration(milliseconds: 350));
                  Scrollable.ensureVisible(globalKey.currentContext!,
                      duration: const Duration(milliseconds: 350));
                },
                keyboardType: TextInputType.twitter,
                textInputAction: TextInputAction.newline,
                minLines: minLines,
                maxLines: maxLines,
                focusNode: helper.detectableTextFocusNode,
                controller: helper.detectableTextController,
                decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 10),
                    hintText: LKey.writeSomethingHere.tr,
                    hintStyle: TextStyleCustom.outFitLight300(
                        color: textLightGrey(context), fontSize: 16)),
                style: TextStyleCustom.outFitRegular400(
                    color: whitePure(context), fontSize: 16),
                onChanged: helper.onChanged,
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(
                  FeedTagType.values.length,
                  (index) {
                    FeedTagType data = FeedTagType.values[index];
                    return IconWithText(
                      icon: data.image,
                      text: data.title,
                      onTap: () {
                        helper.detectableTextFocusNode.unfocus();
                        switch (index) {
                          case 0:
                            Get.bottomSheet(MentionSheet(controller: controller),
                                    isScrollControlled: true)
                                .then((value) {
                              if (helper.detectableTextController
                                      .typingDetection ==
                                  null) {
                                return;
                              }
                              helper.onChanged(helper
                                      .detectableTextController.typingDetection
                                      ?.split('@')[1] ??
                                  '');
                            });
                          case 1:
                            Get.bottomSheet(HashTagSheet(controller: controller),
                                    isScrollControlled: true)
                                .then((value) {
                              if (helper.detectableTextController
                                      .typingDetection ==
                                  null) {
                                return;
                              }
                              helper.onChanged(helper
                                      .detectableTextController.typingDetection
                                      ?.split('#')[1] ??
                                  '');
                            });
                          case 2:
                            Get.bottomSheet(
                                LocationSheet(
                                    onLocationTap: controller.onLocationTap),
                                isScrollControlled: true);
                        }
                      },
                    );
                  },
                ),
              ),
            )
          ],
        ),
      );
    });
  }
}

class IconWithText extends StatelessWidget {
  final String icon;
  final String text;
  final VoidCallback? onTap;

  const IconWithText(
      {super.key, required this.icon, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    final chipColor = resolveButtonBackground(
      context,
      preferred: bgGrey(context),
      fallback: buttonSecondary(context),
    );

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
          decoration: ShapeDecoration(
            color: chipColor,
            shape: SmoothRectangleBorder(
                borderRadius:
                    SmoothBorderRadius(cornerRadius: 8, cornerSmoothing: 1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(icon,
                  color: whitePure(context), height: 19, width: 19),
              const SizedBox(width: 5),
              Text(text,
                  style: TextStyleCustom.outFitLight300(
                      color: whitePure(context)))
            ],
          ),
        ),
      ),
    );
  }
}
