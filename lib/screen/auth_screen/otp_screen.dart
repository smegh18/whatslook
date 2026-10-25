import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:shortzz/common/widget/custom_back_button.dart';
import 'package:shortzz/common/widget/gradient_text.dart';
import 'package:shortzz/common/widget/text_button_custom.dart';
import 'package:shortzz/languages/languages_keys.dart';
import 'package:shortzz/screen/auth_screen/auth_screen_controller.dart';
import 'package:shortzz/utilities/style_res.dart';
import 'package:shortzz/utilities/text_style_custom.dart';
import 'package:shortzz/utilities/theme_res.dart';

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthScreenController>();
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const CustomBackButton(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5)),
            const SizedBox(height: 10),
            Expanded(
                child: SingleChildScrollView(
              dragStartBehavior: DragStartBehavior.down,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 20.0, right: 20, top: 40, bottom: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(LKey.verifyPhone.tr.toUpperCase(),
                            style: TextStyleCustom.unboundedBlack900(
                              fontSize: 25,
                              color: textDarkGrey(context),
                            ).copyWith(letterSpacing: -.2)),
                        const SizedBox(height: 10),
                        GradientText(LKey.enterOTP.tr.toUpperCase(),
                            gradient: StyleRes.themeGradient,
                            style: TextStyleCustom.unboundedBlack900(
                              fontSize: 20,
                              color: textDarkGrey(context),
                            ).copyWith(letterSpacing: -.2)),
                        const SizedBox(height: 20),
                        Text(
                          '${LKey.sentTo.tr} ${controller.getFullPhoneNumber()}',
                          style: TextStyleCustom.unboundedBlack900(
                            fontSize: 16,
                            color: textDarkGrey(context).withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: PinCodeTextField(
                      appContext: context,
                      controller: controller.otpController,
                      length: 6,
                      animationType: AnimationType.fade,
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(12),
                        fieldHeight: 56,
                        fieldWidth: 56,
                        activeFillColor: Colors.transparent,
                        inactiveFillColor: Colors.transparent,
                        selectedFillColor: Colors.transparent,
                        activeColor: StyleRes.themeGradient.colors.first,
                        inactiveColor:
                            textDarkGrey(context).withValues(alpha: 0.3),
                        selectedColor: StyleRes.themeGradient.colors.first,
                        borderWidth: 1,
                      ),
                      cursorColor: textDarkGrey(context),
                      textStyle: TextStyleCustom.unboundedBlack900(
                        fontSize: 20,
                        color: textDarkGrey(context),
                      ),
                      onChanged: (value) {
                        // Optional: handle on change
                      },
                      onCompleted: (pin) {
                        controller.verifyOtp();
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                  Obx(() => TextButtonCustom(
                      onTap: () {
                        if (controller.canResendOtp.value) {
                          controller.resendOtp();
                        }
                      },
                      title: controller.canResendOtp.value
                          ? LKey.resendOTP.tr
                          : '${LKey.resendOTP.tr} (${controller.otpResendTimer.value}s)',
                      backgroundColor: controller.canResendOtp.value
                          ? textDarkGrey(context)
                          : textDarkGrey(context).withValues(alpha: 0.5),
                      titleColor: whitePure(context),
                      horizontalMargin: 20)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
