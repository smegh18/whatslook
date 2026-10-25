import 'package:flutter/material.dart';
import 'package:shortzz/utilities/color_res.dart';

class ThemeRes {
  ThemeRes._();

  static ThemeData lightTheme(BuildContext context) {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: scaffoldBackgroundColor(context),
      colorScheme: ColorScheme.fromSeed(
        seedColor: themeAccentSolid(context),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData darkTheme(BuildContext context) {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: scaffoldBackgroundColor(context),
      colorScheme: ColorScheme.fromSeed(
        seedColor: themeAccentSolid(context),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );
  }
}

Color blackPure(BuildContext _) => ColorRes.blackPure;
Color whitePure(BuildContext _) => ColorRes.whitePure;
Color scaffoldBackgroundColor(BuildContext _) => ColorRes.background;
Color appBarColor(BuildContext _) => ColorRes.appBarColro;
Color themeColor(BuildContext _) => ColorRes.themeColor;
Color themeAccentSolid(BuildContext _) => ColorRes.themeAccentSolid;
Color themeGradient1(BuildContext _) => ColorRes.themeGradient1;
Color themeGradient2(BuildContext _) => ColorRes.themeGradient2;
Color textDarkGrey(BuildContext _) => ColorRes.textDarkGrey;
Color textLightGrey(BuildContext _) => ColorRes.textLightGrey;
Color bgLightGrey(BuildContext _) => ColorRes.bgLightGrey;
Color bgGrey(BuildContext _) => ColorRes.bgGrey;
Color bgMediumGrey(BuildContext _) => ColorRes.bgMediumGrey;
Color disableGrey(BuildContext _) => ColorRes.disabledGrey;
Color orange(BuildContext _) => ColorRes.orange;
Color green(BuildContext _) => ColorRes.green;
Color green1(BuildContext _) => ColorRes.green1;
Color likeRed(BuildContext _) => ColorRes.likeRed;
Color textStoryBgGradient2(BuildContext _) => ColorRes.textStoryBgGradient2;
Color blueFollow(BuildContext _) => ColorRes.blueFollow;
Color battleProgressColor(BuildContext _) => ColorRes.battleProgressColor;
Color buttonSecondary(BuildContext _) => ColorRes.buttonSecondary;
Color buttonOverlay(BuildContext _) => ColorRes.buttonOverlay;

Color resolveButtonBackground(BuildContext context,
    {Color? preferred, Color? fallback}) {
  final fallbackColor = fallback ?? themeAccentSolid(context);
  if (preferred == null || preferred.alpha == 0) {
    return fallbackColor;
  }

  final opacity = preferred.alpha / 255;
  if (opacity < .45) {
    return Color.alphaBlend(preferred, fallback ?? buttonSecondary(context));
  }

  if (preferred.computeLuminance() > .72) {
    return fallbackColor;
  }

  return preferred;
}

Color resolveButtonForeground(BuildContext context,
    {required Color backgroundColor, Color? preferred, Color? fallback}) {
  final fallbackColor = fallback ?? whitePure(context);
  if (preferred == null || preferred.alpha == 0) {
    return fallbackColor;
  }

  if (_contrastRatio(preferred, backgroundColor) >= 3.5) {
    return preferred;
  }

  return fallbackColor;
}

double _contrastRatio(Color foreground, Color background) {
  final fg = foreground.computeLuminance();
  final bg = background.computeLuminance();
  final lighter = fg > bg ? fg : bg;
  final darker = fg > bg ? bg : fg;
  return (lighter + 0.05) / (darker + 0.05);
}
