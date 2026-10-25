import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shortzz/common/widget/privacy_policy_text.dart';
import 'package:shortzz/common/widget/text_button_custom.dart';
import 'package:shortzz/languages/languages_keys.dart';
import 'package:shortzz/screen/auth_screen/auth_screen_controller.dart';
import 'package:shortzz/screen/auth_screen/registration_screen.dart';
import 'package:shortzz/screen/edit_profile_screen/widget/phone_codes_screen.dart';
import 'package:shortzz/screen/edit_profile_screen/widget/phone_codes_screen_controller.dart';
import 'package:shortzz/utilities/asset_res.dart';
import 'package:shortzz/utilities/color_res.dart';
import 'package:shortzz/utilities/text_style_custom.dart';
import 'package:shortzz/utilities/theme_res.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AuthScreenController());
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        height: Get.height,
        decoration: const ShapeDecoration(
            shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius.vertical(
              top: SmoothRadius(cornerRadius: 0, cornerSmoothing: 1)),
        )),
        child: Stack(
          children: [
            //const ThemeBlurBg(),
            SingleChildScrollView(
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 20, right: 20, top: 30),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 30.0),
                            child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  text: LKey.signIn.tr.toUpperCase(),
                                  style: TextStyleCustom.unboundedBlack900(
                                    fontSize: 25,
                                    color: whitePure(context),
                                  ).copyWith(letterSpacing: -.2),
                                  children: [
                                    TextSpan(
                                        text: '\n${LKey.toContinue.tr}'
                                            .toUpperCase(),
                                        style:
                                            TextStyleCustom.unboundedBlack900(
                                                fontSize: 25,
                                                color: whitePure(context)
                                                    .withValues(alpha: .5),
                                                opacity: .5))
                                  ],
                                )),
                          ),
                          const SizedBox(height: 50 * 1.5),
                          LoginPhoneTextField(
                            controller: controller.phoneNumberController,
                          ),
                          const SizedBox(height: 18),
                          TextButtonCustom(
                              titleColor: ColorRes.blackPure,
                              onTap: controller.onLogin,
                              title: LKey.verifyPhone.tr,
                              btnHeight: 50,
                              horizontalMargin: 0),
                          const SizedBox(height: 14),
                          GmailLoginButton(onTap: controller.onGoogleTap)
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        controller.fullNameController.clear();
                        controller.emailController.clear();
                        controller.phoneNumberController.clear();
                        controller.passwordController.clear();
                        controller.confirmPassController.clear();
                        controller.otpController.clear();
                        Get.to(() => const RegistrationScreen());
                      },
                      child: Container(
                        height: 48,
                        margin: const EdgeInsets.symmetric(vertical: 25),
                        alignment: Alignment.center,
                        color: whitePure(context).withValues(alpha: .2),
                        child: Text(
                          LKey.createAccountHere.tr,
                          style: TextStyleCustom.outFitRegular400(
                              color: whitePure(context), fontSize: 16),
                        ),
                      ),
                    ),
                    PrivacyPolicyText(
                      boldTextColor: whitePure(context),
                      regularTextColor:
                          whitePure(context).withValues(alpha: .8),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GmailLoginButton extends StatelessWidget {
  final VoidCallback onTap;

  const GmailLoginButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 50,
        decoration: ShapeDecoration(
          color: whitePure(context),
          shape: SmoothRectangleBorder(
            borderRadius:
                SmoothBorderRadius(cornerRadius: 10, cornerSmoothing: 1),
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(AssetRes.icGoogle, height: 24, width: 24),
            const SizedBox(width: 10),
            Text(
              'Continue with Gmail',
              style: TextStyleCustom.outFitRegular400(
                  color: ColorRes.blackPure, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginPhoneTextField extends StatefulWidget {
  final TextEditingController controller;

  const LoginPhoneTextField({super.key, required this.controller});

  @override
  State<LoginPhoneTextField> createState() => _LoginPhoneTextFieldState();
}

class _LoginPhoneTextFieldState extends State<LoginPhoneTextField> {
  late PhoneCodesScreenController phoneCodesController;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<PhoneCodesScreenController>()) {
      phoneCodesController = Get.find<PhoneCodesScreenController>();
    } else {
      phoneCodesController = Get.put(PhoneCodesScreenController());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: ShapeDecoration(
          shape: SmoothRectangleBorder(
            borderRadius:
                SmoothBorderRadius(cornerRadius: 10, cornerSmoothing: 1),
            side: BorderSide(color: whitePure(context).withValues(alpha: .4)),
            borderAlign: BorderAlign.inside,
          ),
          color: whitePure(context).withValues(alpha: .88)),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              Get.bottomSheet(const PhoneCodesScreen(),
                      isScrollControlled: true, ignoreSafeArea: false)
                  .then((value) => phoneCodesController.searchPhoneCodes(''));
            },
            child: SizedBox(
              width: 124,
              child: Center(
                child: Obx(() => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${phoneCodesController.selectedCode.value?.countryCode ?? ''} ${phoneCodesController.selectedCode.value?.phoneCode ?? ''}',
                          style: TextStyleCustom.outFitRegular400(
                              color: ColorRes.blackPure, fontSize: 15),
                        ),
                        const Icon(Icons.arrow_drop_down,
                            color: ColorRes.blackPure, size: 24)
                      ],
                    )),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 34,
            color: ColorRes.blackPure.withValues(alpha: .22),
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              style: TextStyleCustom.outFitRegular400(
                  color: ColorRes.blackPure, fontSize: 16),
              onTapOutside: (event) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: LKey.phoneNumber.tr,
                hintStyle: TextStyleCustom.outFitRegular400(
                    color: ColorRes.blackPure.withValues(alpha: .45),
                    fontSize: 16),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
              ),
              cursorColor: ColorRes.blackPure,
            ),
          ),
        ],
      ),
    );
  }
}
