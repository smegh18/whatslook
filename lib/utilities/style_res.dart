import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:shortzz/utilities/color_res.dart';

class StyleRes {
  static const LinearGradient themeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      ColorRes.themeAccentSolid,
      ColorRes.themeGradient1,
      ColorRes.themeGradient2,
    ],
  );

  static LinearGradient textLightGreyGradient({double opacity = 1}) {
    final alpha = opacity.clamp(0.0, 1.0).toDouble();
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        ColorRes.textLightGrey.withValues(alpha: 0.95 * alpha),
        ColorRes.textLightGrey.withValues(alpha: 0.55 * alpha),
      ],
    );
  }

  static LinearGradient textDarkGreyGradient({double opacity = 1}) {
    final alpha = opacity.clamp(0.0, 1.0).toDouble();
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        ColorRes.textDarkGrey.withValues(alpha: 0.95 * alpha),
        ColorRes.textLightGrey.withValues(alpha: 0.8 * alpha),
      ],
    );
  }

  static LinearGradient disabledGreyGradient({double opacity = 1}) {
    final alpha = opacity.clamp(0.0, 1.0).toDouble();
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        ColorRes.disabledGrey.withValues(alpha: 0.8 * alpha),
        ColorRes.disabledGrey.withValues(alpha: 0.45 * alpha),
      ],
    );
  }

  static ui.Gradient get wavesGradient => ui.Gradient.linear(
        const ui.Offset(0, 0),
        const ui.Offset(300, 0),
        const [
          ColorRes.themeGradient1,
          ColorRes.themeAccentSolid,
          ColorRes.themeGradient2,
        ],
        const [0.0, 0.5, 1.0],
      );
}
