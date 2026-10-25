import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shortzz/common/extensions/string_extension.dart';
import 'package:shortzz/common/service/api/post_service.dart';
import 'package:shortzz/common/service/utils/video_source_resolver.dart';
import 'package:shortzz/common/widget/black_gradient_shadow.dart';
import 'package:shortzz/common/widget/double_tap_detector.dart';
import 'package:shortzz/model/post_story/post_by_id.dart';
import 'package:shortzz/model/post_story/post_model.dart';
import 'package:shortzz/screen/dashboard_screen/dashboard_screen_controller.dart';
import 'package:shortzz/screen/reels_screen/reel/reel_page_controller.dart';
import 'package:shortzz/screen/reels_screen/reel/widget/reel_animation_like.dart';
import 'package:shortzz/screen/reels_screen/reel/widget/reel_seek_bar.dart';
import 'package:shortzz/screen/reels_screen/reel/widget/side_bar_list.dart';
import 'package:shortzz/screen/reels_screen/reel/widget/user_information.dart';
import 'package:shortzz/screen/reels_screen/reels_screen_controller.dart';
import 'package:shortzz/utilities/asset_res.dart';
import 'package:shortzz/utilities/theme_res.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:shortzz/common/manager/logger.dart';
import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------
// REEL PAGE
// ---------------------------------------------------------------
class ReelPage extends StatefulWidget {
  final Post reelData;
  final bool autoPlay;
  final PostByIdData? postByIdData;
  final bool isFromChat;
  final GlobalKey likeKey;
  final ReelsScreenController reelsScreenController;
  final Function(Post reel) onUpdateReelData;
  final bool isHomePage;

  const ReelPage(
      {super.key,
      required this.reelData,
      this.autoPlay = false,
      this.postByIdData,
      this.isFromChat = false,
      required this.likeKey,
      required this.reelsScreenController,
      required this.onUpdateReelData,
      required this.isHomePage});

  @override
  State<ReelPage> createState() => _ReelPageState();
}

class _ReelPageState extends State<ReelPage> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _isDisposed = false;
  bool _initStarted = false;
  bool _hasCountedView = false;
  bool isPlaying = true;
  String? _videoInitError;
  String? _resolvedVideoUrl;
  Timer? _deferredInitTimer;
  late ReelController reelController;
  Rx<TapDownDetails?> details = Rx(null);
  final dashboardController = Get.find<DashboardScreenController>();

  @override
  void initState() {
    super.initState();

    // ✅ Setup Reel Controller
    if (Get.isRegistered<ReelController>(tag: '${widget.reelData.id}')) {
      reelController = Get.find<ReelController>(tag: '${widget.reelData.id}');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!widget.isFromChat) {
          reelController.updateReelData(reel: widget.reelData);
        }
        reelController.notifyCommentSheet(widget.postByIdData);
      });
    } else {
      reelController = Get.put(
        ReelController(widget.reelData.obs, widget.onUpdateReelData),
        tag: '${widget.reelData.id}',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        reelController.notifyCommentSheet(widget.postByIdData);
      });
    }

    _queueVideoInitialization(priority: widget.autoPlay);
  }

  @override
  void didUpdateWidget(covariant ReelPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.autoPlay && !oldWidget.autoPlay) {
      _queueVideoInitialization(priority: true);
      if (_initialized && _controller?.value.isInitialized == true) {
        unawaited(_playVideo());
      }
    } else if (!widget.autoPlay &&
        oldWidget.autoPlay &&
        _controller?.value.isPlaying == true) {
      unawaited(_controller?.pause());
      isPlaying = false;
    }
  }

  void _queueVideoInitialization({required bool priority}) {
    if (_isDisposed || _initStarted) {
      return;
    }

    _deferredInitTimer?.cancel();
    if (priority) {
      _initStarted = true;
      unawaited(_initializeAndPlayVideo());
      return;
    }

    _deferredInitTimer = Timer(const Duration(milliseconds: 350), () {
      if (_isDisposed || _initStarted) {
        return;
      }
      _initStarted = true;
      unawaited(_initializeAndPlayVideo());
    });
  }

  Future<void> _initializeAndPlayVideo({int retryCount = 0}) async {
    if (_isDisposed) return;

    try {
      final prefetchedFile = await VideoSourceResolver.waitForPrefetchIfRunning(
        widget.reelData.video ?? '',
      );
      final cachedFile = prefetchedFile ??
          await VideoSourceResolver.cachedVideoFile(
              widget.reelData.video ?? '');
      VideoPlayerController? controller;
      Object? lastError;

      if (cachedFile != null && await cachedFile.exists()) {
        try {
          controller = VideoPlayerController.file(cachedFile);
          _resolvedVideoUrl = cachedFile.path;
          controller.addListener(() {
            final err = controller?.value.errorDescription;
            if (err != null && err.isNotEmpty) {
              Loggers.error('VIDEO_PLAYER error: $err');
              if (_videoInitError == null) {
                _videoInitError = err;
                if (mounted) setState(() {});
              }
            }
          });
          await controller.initialize();
          _controller = controller;
        } catch (e) {
          lastError = e;
          controller?.dispose();
          controller = null;
        }
      }

      final candidates =
          await VideoSourceResolver.playableUrls(widget.reelData.video ?? '');

      for (final candidate in candidates) {
        if (_controller != null) {
          break;
        }
        if (_isDisposed) return;
        try {
          if (kDebugMode) {
            Loggers.info('VIDEO try -> $candidate');
          }

          controller?.dispose();
          controller = VideoPlayerController.networkUrl(
            VideoSourceResolver.safeUri(candidate),
            httpHeaders: VideoSourceResolver.httpHeaders,
          );
          _resolvedVideoUrl = candidate;
          controller.addListener(() {
            final err = controller?.value.errorDescription;
            if (err != null && err.isNotEmpty) {
              Loggers.error('VIDEO_PLAYER error: $err');
              if (_videoInitError == null) {
                _videoInitError = err;
                if (mounted) setState(() {});
              }
            }
          });
          await controller.initialize();
          _controller = controller;
          break;
        } catch (e) {
          lastError = e;
          continue;
        }
      }

      if (_controller == null) {
        throw lastError ?? Exception('Video failed to initialize');
      }

      if (_isDisposed) return;
      _controller!.setLooping(true);
      _initialized = true;
      _videoInitError = null;

      if (dashboardController.selectedPageIndex.value != 0 &&
          widget.isHomePage) {
        return;
      }
      // ✅ Auto play only when visible and autoplay flag true
      if (widget.autoPlay &&
          widget.reelsScreenController.isCurrentPageVisible) {
        await _playVideo();
      }

      setState(() {});
    } catch (e) {
      Loggers.error(
          'Video init error: $e | video="${widget.reelData.video}" | resolved="${widget.reelData.video?.addBaseURL()}"');
      _videoInitError = e.toString();

      // 🔁 Retry if failed (max 3 retries with small delay)
      if (retryCount < 3 && !_isDisposed) {
        await Future.delayed(const Duration(milliseconds: 500));
        _initializeAndPlayVideo(retryCount: retryCount + 1);
      } else {
        if (mounted) setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _deferredInitTimer?.cancel();
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  void _handleVisibilityChanged(VisibilityInfo info) {
    if (!_initialized ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return;
    }

    if ((info.visibleFraction * 100) > 90) {
      if (!_controller!.value.isPlaying) {
        unawaited(_playVideo());
      }
    } else {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        isPlaying = false;
      }
    }
    setState(() {});
  }

  Future<void> _playVideo() async {
    final controller = _controller;
    if (_isDisposed ||
        controller == null ||
        !controller.value.isInitialized ||
        controller.value.isPlaying) {
      return;
    }

    await controller.play();
    if (_isDisposed) {
      return;
    }

    isPlaying = true;
    if (!_hasCountedView) {
      _hasCountedView = true;
      _increaseViewsCount(widget.reelData);
    }
  }

  void onPlayPause() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
      isPlaying = false;
    } else {
      _controller!.play();
      isPlaying = true;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DoubleTapDetector(
      onDoubleTap: (value) {
        if (details.value != null) return;
        details.value = value;
      },
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          /// 🎬 Video / Placeholder
          buildContent(),

          /// 🕹 Tap Overlay (pause/play)
          InkWell(onTap: onPlayPause, child: const BlackGradientShadow()),

          /// ▶ Play/Pause Icon overlay
          if (_controller != null && _controller!.value.isInitialized)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: isPlaying ? 0.0 : 1.0,
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  height: 60,
                  width: 60,
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  alignment: const Alignment(0.25, 0),
                  child: Image.asset(
                      isPlaying ? AssetRes.icPause : AssetRes.icPlay,
                      width: 45,
                      height: 45,
                      color: bgGrey(context)),
                ),
              ),
            ),

          /// ℹ️ Reel Info Section
          ReelInfoSection(
            controller: reelController,
            likeKey: widget.likeKey,
            videoPlayerPlusController: _controller,
          ),

          /// 💖 Like Animation
          Obx(() {
            if (details.value == null) return const SizedBox();
            return ReelAnimationLike(
              likeKey: widget.likeKey,
              position: details.value!.globalPosition,
              size: const Size(50, 50),
              leftRightPosition: 8,
              onLikeCall: () {
                if (reelController.reelData.value.isLiked == true) return;
                reelController.onLikeTap();
              },
              onCompleteAnimation: () => details.value = null,
            );
          }),
        ],
      ),
    );
  }

  Widget buildContent() {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        !_initialized) {
      final thumb = widget.reelData.getThumbnail;
      final thumbUrl = thumb.isNotEmpty ? thumb.addBaseURL() : '';

      return Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (thumbUrl.isNotEmpty)
              Image.network(
                thumbUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            Center(
              child: _videoInitError == null
                  ? const CircularProgressIndicator(color: Colors.white70)
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.white70),
                        const SizedBox(height: 8),
                        const Text('Video failed to load',
                            style: TextStyle(color: Colors.white70)),
                        if (kDebugMode) ...[
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              _resolvedVideoUrl ?? '',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 11),
                            ),
                          ),
                          if ((_videoInitError ?? '').isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                _videoInitError ?? '',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 10),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
            ),
          ],
        ),
      );
    }

    Size size = _controller!.value.size;
    return VisibilityDetector(
      key: Key('reel_${widget.reelData.id}'),
      onVisibilityChanged: _handleVisibilityChanged,
      child: InkWell(
        onTap: onPlayPause,
        child: ClipRRect(
          child: SizedBox.expand(
            child: FittedBox(
              fit: (size.width < size.height) ? BoxFit.cover : BoxFit.fitWidth,
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: VideoPlayer(_controller!),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _increaseViewsCount(Post reelData) {
    PostService.instance.increaseViewsCount(postId: reelData.id).then((value) {
      if (value.status == true) {
        reelController.updateReelData(reel: reelData, isIncreaseCoin: true);
      }
    });
  }
}

class ReelInfoSection extends StatelessWidget {
  final ReelController controller;
  final GlobalKey likeKey;
  final VideoPlayerController? videoPlayerPlusController;

  const ReelInfoSection(
      {super.key,
      required this.controller,
      required this.likeKey,
      required this.videoPlayerPlusController});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ReelInfoRow(controller: controller, likeKey: likeKey),
        ReelSeekBar(
            videoController: videoPlayerPlusController, controller: controller),
      ],
    );
  }
}

class ReelInfoRow extends StatelessWidget {
  final ReelController controller;
  final GlobalKey likeKey;

  const ReelInfoRow(
      {super.key, required this.controller, required this.likeKey});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: UserInformation(controller: controller)),
        SideBarList(controller: controller, likeKey: likeKey),
      ],
    );
  }
}
