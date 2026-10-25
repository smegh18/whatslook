import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shortzz/common/widget/custom_shimmer_fill_text.dart';
import 'package:shortzz/screen/splash_screen/splash_screen_controller.dart';
import 'package:shortzz/utilities/app_res.dart';
import 'package:shortzz/utilities/text_style_custom.dart';
import 'package:shortzz/utilities/theme_res.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<SplashScreenController>()) {
      Get.put(SplashScreenController());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          //const ThemeBlurBg(),
          Align(
            alignment: Alignment.center,
            child: CustomShimmerFillText(
              text: AppRes.appName.toUpperCase(),
              baseColor: Colors.black, // main visible text
              textStyle: TextStyleCustom.unboundedBlack900(
                color: Colors.black,
                fontSize: 30,
              ),// final fill color
              shimmerColor:
                  themeAccentSolid(context), // moving shimmer highlight
            ),
          )
        ],
      ),
    );
  }
}
