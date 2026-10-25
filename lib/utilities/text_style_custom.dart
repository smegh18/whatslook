import 'package:flutter/material.dart';

class TextStyleCustom {
  static TextStyle _build({
    required String family,
    required FontWeight defaultWeight,
    double? fontSize,
    Color? color,
    double? opacity,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    TextDecoration? decoration,
    Color? decorationColor,
    double? letterSpacing,
    double? height,
  }) {
    Color? resolvedColor = color;
    final alpha = opacity ?? 1;
    if (resolvedColor != null && alpha != 1) {
      resolvedColor = resolvedColor.withValues(alpha: alpha);
    }

    return TextStyle(
      fontFamily: family,
      fontWeight: fontWeight ?? defaultWeight,
      fontSize: fontSize,
      color: resolvedColor,
      fontStyle: fontStyle,
      decoration: decoration,
      decorationColor: decorationColor,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle outFitBlack900({
    double? fontSize,
    Color? color,
    double? opacity,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    TextDecoration? decoration,
    Color? decorationColor,
    double? letterSpacing,
    double? height,
  }) {
    return _build(
      family: 'Black',
      defaultWeight: FontWeight.w900,
      fontSize: fontSize,
      color: color,
      opacity: opacity,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      decoration: decoration,
      decorationColor: decorationColor,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle outFitBold700({
    double? fontSize,
    Color? color,
    double? opacity,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    TextDecoration? decoration,
    Color? decorationColor,
    double? letterSpacing,
    double? height,
  }) {
    return _build(
      family: 'Bold',
      defaultWeight: FontWeight.w700,
      fontSize: fontSize,
      color: color,
      opacity: opacity,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      decoration: decoration,
      decorationColor: decorationColor,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle outFitExtraBold800({
    double? fontSize,
    Color? color,
    double? opacity,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    TextDecoration? decoration,
    Color? decorationColor,
    double? letterSpacing,
    double? height,
  }) {
    return _build(
      family: 'ExtraBold',
      defaultWeight: FontWeight.w800,
      fontSize: fontSize,
      color: color,
      opacity: opacity,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      decoration: decoration,
      decorationColor: decorationColor,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle outFitLight300({
    double? fontSize,
    Color? color,
    double? opacity,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    TextDecoration? decoration,
    Color? decorationColor,
    double? letterSpacing,
    double? height,
  }) {
    return _build(
      family: 'Light',
      defaultWeight: FontWeight.w300,
      fontSize: fontSize,
      color: color,
      opacity: opacity,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      decoration: decoration,
      decorationColor: decorationColor,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle outFitMedium500({
    double? fontSize,
    Color? color,
    double? opacity,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    TextDecoration? decoration,
    Color? decorationColor,
    double? letterSpacing,
    double? height,
  }) {
    return _build(
      family: 'Medium',
      defaultWeight: FontWeight.w500,
      fontSize: fontSize,
      color: color,
      opacity: opacity,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      decoration: decoration,
      decorationColor: decorationColor,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle outFitRegular400({
    double? fontSize,
    Color? color,
    double? opacity,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    TextDecoration? decoration,
    Color? decorationColor,
    double? letterSpacing,
    double? height,
  }) {
    return _build(
      family: 'Regular',
      defaultWeight: FontWeight.w400,
      fontSize: fontSize,
      color: color,
      opacity: opacity,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      decoration: decoration,
      decorationColor: decorationColor,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle outFitSemiBold600({
    double? fontSize,
    Color? color,
    double? opacity,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    TextDecoration? decoration,
    Color? decorationColor,
    double? letterSpacing,
    double? height,
  }) {
    return _build(
      family: 'SemiBold',
      defaultWeight: FontWeight.w600,
      fontSize: fontSize,
      color: color,
      opacity: opacity,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      decoration: decoration,
      decorationColor: decorationColor,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle outFitThin100({
    double? fontSize,
    Color? color,
    double? opacity,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    TextDecoration? decoration,
    Color? decorationColor,
    double? letterSpacing,
    double? height,
  }) {
    return _build(
      family: 'Thin',
      defaultWeight: FontWeight.w100,
      fontSize: fontSize,
      color: color,
      opacity: opacity,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      decoration: decoration,
      decorationColor: decorationColor,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle unboundedBlack900({
    double? fontSize,
    Color? color,
    double? opacity,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    TextDecoration? decoration,
    Color? decorationColor,
    double? letterSpacing,
    double? height,
  }) {
    return _build(
      family: 'Unbounded-Black',
      defaultWeight: FontWeight.w900,
      fontSize: fontSize,
      color: color,
      opacity: opacity,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      decoration: decoration,
      decorationColor: decorationColor,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle unboundedBold700({
    double? fontSize,
    Color? color,
    double? opacity,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    TextDecoration? decoration,
    Color? decorationColor,
    double? letterSpacing,
    double? height,
  }) {
    return _build(
      family: 'Unbounded-Bold',
      defaultWeight: FontWeight.w700,
      fontSize: fontSize,
      color: color,
      opacity: opacity,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      decoration: decoration,
      decorationColor: decorationColor,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle unboundedExtraBold800({
    double? fontSize,
    Color? color,
    double? opacity,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    TextDecoration? decoration,
    Color? decorationColor,
    double? letterSpacing,
    double? height,
  }) {
    return _build(
      family: 'Unbounded-ExtraBold',
      defaultWeight: FontWeight.w800,
      fontSize: fontSize,
      color: color,
      opacity: opacity,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      decoration: decoration,
      decorationColor: decorationColor,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle unboundedLight200({
    double? fontSize,
    Color? color,
    double? opacity,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    TextDecoration? decoration,
    Color? decorationColor,
    double? letterSpacing,
    double? height,
  }) {
    return _build(
      family: 'Unbounded-ExtraLight',
      defaultWeight: FontWeight.w200,
      fontSize: fontSize,
      color: color,
      opacity: opacity,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      decoration: decoration,
      decorationColor: decorationColor,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle unboundedMedium500({
    double? fontSize,
    Color? color,
    double? opacity,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    TextDecoration? decoration,
    Color? decorationColor,
    double? letterSpacing,
    double? height,
  }) {
    return _build(
      family: 'Unbounded-Medium',
      defaultWeight: FontWeight.w500,
      fontSize: fontSize,
      color: color,
      opacity: opacity,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      decoration: decoration,
      decorationColor: decorationColor,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle unboundedRegular400({
    double? fontSize,
    Color? color,
    double? opacity,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    TextDecoration? decoration,
    Color? decorationColor,
    double? letterSpacing,
    double? height,
  }) {
    return _build(
      family: 'Unbounded-Regular',
      defaultWeight: FontWeight.w400,
      fontSize: fontSize,
      color: color,
      opacity: opacity,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      decoration: decoration,
      decorationColor: decorationColor,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle unboundedSemiBold600({
    double? fontSize,
    Color? color,
    double? opacity,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    TextDecoration? decoration,
    Color? decorationColor,
    double? letterSpacing,
    double? height,
  }) {
    return _build(
      family: 'Unbounded-SemiBold',
      defaultWeight: FontWeight.w600,
      fontSize: fontSize,
      color: color,
      opacity: opacity,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      decoration: decoration,
      decorationColor: decorationColor,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
}

