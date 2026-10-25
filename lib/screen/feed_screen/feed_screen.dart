import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shortzz/common/widget/loader_widget.dart';
import 'package:shortzz/common/widget/my_refresh_indicator.dart';
import 'package:shortzz/common/widget/no_data_widget.dart';
import 'package:shortzz/languages/languages_keys.dart';
import 'package:shortzz/model/user_model/user_model.dart';
import 'package:shortzz/screen/feed_screen/feed_screen_controller.dart';
import 'package:shortzz/screen/feed_screen/widget/feed_top_view.dart';
import 'package:shortzz/screen/feed_screen/widget/story_view.dart';
import 'package:shortzz/screen/post_screen/post_card.dart';

class FeedScreen extends StatelessWidget {
  final User? myUser;

  const FeedScreen({super.key, this.myUser});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FeedScreenController(myUser.obs));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FeedTopView(controller: controller),
        Expanded(
            child: MyRefreshIndicator(
          refreshKey: controller.refreshKey,
          onRefresh: controller.onRefresh,
          shouldRefresh: true,
          child: Stack(
            children: [
              Obx(() {
                if (!controller.isLoading.value && controller.posts.isEmpty) {
                  return Stack(
                    children: [
                      NoDataView(
                          safeAreaTop: false,
                          title: LKey.noUserPostsTitle.tr,
                          description: LKey.noUserPostsDescription.tr),
                      SingleChildScrollView(
                        child: SizedBox(
                            width: double.infinity, height: Get.height),
                      ),
                    ],
                  );
                }
                if (controller.isLoading.value && controller.posts.isEmpty) {
                  return const LoaderWidget();
                }
                return const SizedBox();
              }),
              CustomScrollView(
                controller: controller.postScrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: StoryView(controller: controller)),
                  Obx(
                    () => SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final post = controller.posts[index];
                          return PostCard(
                            key: ValueKey(post.id ?? index),
                            post: post,
                            shouldShowPinOption: false,
                            likeKey: GlobalKey(),
                          );
                        },
                        childCount: controller.posts.length,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(height: AppBar().preferredSize.height / 2),
                  ),
                ],
              ),
            ],
          ),
        ))
      ],
    );
  }
}
