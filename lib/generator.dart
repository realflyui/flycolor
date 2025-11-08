import 'dart:math';

import 'package:flutter/material.dart';
import 'package:okcolor/models/extensions.dart';
import 'package:okcolor/models/oklch.dart';

import 'scales.dart';

class _ColorWithDistance {
  final String scale;
  final OkLch color;
  final double distance;

  _ColorWithDistance({
    required this.scale,
    required this.color,
    required this.distance,
  });
}

class _Step9Result {
  final OkLch step9;
  final OkLch contrast;

  _Step9Result({required this.step9, required this.contrast});
}

/// Generates perceptually uniform, contextually aware 12-step color scales.
///
/// The generation process:
/// 1. Converts input colors to OKLCH for perceptual uniformity
/// 2. Finds two closest template scales using ΔE_OK color difference
/// 3. Blends templates using trigonometry to determine mixing ratio
/// 4. Corrects hue and chroma to match source color identity
/// 5. Transposes lightness curve to anchor to background using Bezier easing
/// 6. Generates alpha variants using reverse alpha blending
///
/// ## Usage
///
/// ```dart
/// import 'package:flycolor/generator.dart';
///
/// final colors = FlyColorGenerator.generate(
///   appearance: 'light',
///   accent: '#3D63DD',
///   gray: '#8B8D98',
///   background: '#FFFFFF',
/// );
///
/// // Access the generated scales
/// colors.accentScale;      // 12-step accent scale
/// colors.grayScale;        // 12-step gray scale
/// colors.accentScaleAlpha; // Alpha variants
/// colors.accentContrast;   // Contrast color for text
/// colors.accentSurface;    // Surface color
/// ```
/// 
/// Original Source: https://github.com/radix-ui/website/blob/main/components/generateRadixColors.tsx
class FlyColorGenerator {
  static const double _kMixingFactor = 0.5;
  static const double _kChromaCapMultiplier = 1.5;
  static const double _kButtonHoverChromaMultiplier = 0.93;

  /// Generate colors from base colors.
  ///
  /// Returns a [GeneratedColors] object containing all generated color scales.
  /// See the class documentation for usage examples.
  ///
  /// ## Parameters
  /// - [appearance] - "light" or "dark" mode
  /// - [accent] - Accent color (Color object or hex string like "#3D63DD")
  /// - [gray] - Gray color (Color object or hex string like "#8B8D98")
  /// - [background] - Background color (Color object or hex string like "#111111")
  static GeneratedColors generate({
    required String appearance,
    required dynamic accent,
    required dynamic gray,
    required dynamic background,
  }) {
    final isLight = appearance == 'light';
    final accentColor = accent is Color
        ? accent
        : hexToColor(accent as String);
    final grayColor = gray is Color ? gray : hexToColor(gray as String);
    final backgroundColor = background is Color
        ? background
        : hexToColor(background as String);

    // Load pre-built scales and convert to OKLCH
    final scales = _loadScales(isLight);

    var accentScale = _getScaleFromColor(
      sourceColor: accentColor,
      scales: scales,
      backgroundColor: backgroundColor,
    );

    final grayScale = _getScaleFromColor(
      sourceColor: grayColor,
      scales: scales,
      backgroundColor: backgroundColor,
    );

    // Make sure we use the tint from the gray scale for when base is pure white or black
    final accentBaseHex = _colorToHex(accentColor).toLowerCase();
    if (accentBaseHex == '#000' ||
        accentBaseHex == '#fff' ||
        accentBaseHex == '#000000' ||
        accentBaseHex == '#ffffff') {
      accentScale = grayScale.map((c) => Color(c.value)).toList();
    }

    final accentOklch = accentColor.toOkLch();
    final accent9AndContrast = _getStep9Colors(accentScale, accentOklch);
    accentScale[8] = accent9AndContrast.step9.toColor();
    accentScale[9] = _getButtonHoverColor(accent9AndContrast.step9, [
      accentScale,
    ]);

    final accentScaleOklch = accentScale.map((c) => c.toOkLch()).toList();
    final minChroma = max(accentScaleOklch[8].c, accentScaleOklch[7].c);
    final step10Oklch = accentScaleOklch[10];
    final step11Oklch = accentScaleOklch[11];
    accentScale[10] = OkLch(
      step10Oklch.l,
      min(minChroma, step10Oklch.c),
      step10Oklch.h,
    ).toColor();
    accentScale[11] = OkLch(
      step11Oklch.l,
      min(minChroma, step11Oklch.c),
      step11Oklch.h,
    ).toColor();

    final contrastColor = accent9AndContrast.contrast.toColor();

    final accentScaleAlpha = accentScale
        .map((color) => _getAlphaColorSrgb(color, backgroundColor))
        .toList();

    final grayScaleAlpha = grayScale
        .map((color) => _getAlphaColorSrgb(color, backgroundColor))
        .toList();

    final surfaceColor = _getAlphaColorSrgb(
      accentScale[1],
      backgroundColor,
      targetAlpha: isLight ? 0.8 : 0.5,
    );

    return GeneratedColors(
      accentScale: accentScale,
      accentScaleAlpha: accentScaleAlpha,
      grayScale: grayScale,
      grayScaleAlpha: grayScaleAlpha,
      accentContrast: contrastColor,
      accentSurface: surfaceColor,
      background: backgroundColor,
    );
  }

  /// Parse P3 color string to Color object.
  /// Format: "color(display-p3 r g b)" where r, g, b are in 0-1 range.
  static Color _parseP3Color(String p3String) {
    final match = RegExp(
      r'color\(display-p3\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\)',
    ).firstMatch(p3String);
    if (match == null) {
      throw FormatException('Invalid P3 color format: $p3String');
    }

    final r = (double.parse(match.group(1)!) * 255).round().clamp(0, 255);
    final g = (double.parse(match.group(2)!) * 255).round().clamp(0, 255);
    final b = (double.parse(match.group(3)!) * 255).round().clamp(0, 255);

    return Color.fromRGBO(r, g, b, 1.0);
  }

  /// Load pre-built scales and convert to OKLCH.
  /// Uses P3 colors for template matching.
  static Map<String, List<OkLch>> _loadScales(bool isLight) {
    final sourceScales = isLight ? radixLightScalesP3 : radixDarkScalesP3;
    final scales = <String, List<OkLch>>{};

    for (final entry in sourceScales.entries) {
      scales[entry.key] = entry.value
          .map((p3String) => _parseP3Color(p3String).toOkLch())
          .toList();
    }

    return scales;
  }

  /// Mix two OKLCH colors by interpolating lightness, chroma, and hue separately.
  static OkLch _mixOklch(OkLch a, OkLch b, double ratio) {
    double mixedH;
    if (a.h.isNaN && b.h.isNaN) {
      mixedH = double.nan;
    } else if (a.h.isNaN) {
      mixedH = b.h;
    } else if (b.h.isNaN) {
      mixedH = a.h;
    } else {
      double hDiff = b.h - a.h;
      if (hDiff.abs() > 180) {
        if (hDiff > 0) {
          hDiff -= 360;
        } else {
          hDiff += 360;
        }
      }
      mixedH = a.h + hDiff * ratio;
      while (mixedH < 0) {
        mixedH += 360;
      }
      while (mixedH >= 360) {
        mixedH -= 360;
      }
    }

    return OkLch(
      a.l + (b.l - a.l) * ratio,
      a.c + (b.c - a.c) * ratio,
      mixedH,
    );
  }

  /// Generate scale from source color using template matching.
  /// Finds two closest template scales, blends them using trigonometry,
  /// then corrects hue/chroma and transposes lightness to match background.
  static List<Color> _getScaleFromColor({
    required Color sourceColor,
    required Map<String, List<OkLch>> scales,
    required Color backgroundColor,
  }) {
    final sourceOklch = sourceColor.toOkLch();
    final backgroundOklch = backgroundColor.toOkLch();

    final allColors = <_ColorWithDistance>[];
    for (final entry in scales.entries) {
      for (final color in entry.value) {
        final distance = _deltaEOK(sourceOklch, color);
        allColors.add(
          _ColorWithDistance(
            scale: entry.key,
            color: color,
            distance: distance,
          ),
        );
      }
    }

    allColors.sort((a, b) => a.distance.compareTo(b.distance));

    // Remove non-unique scales - get one color from each unique scale
    final closestColors = <_ColorWithDistance>[];
    final seenScales = <String>{};
    for (final color in allColors) {
      if (!seenScales.contains(color.scale)) {
        closestColors.add(color);
        seenScales.add(color.scale);
      }
    }

    // If the next two closest colors are both grays, remove the second one until it's not a gray anymore.
    // This is because up next we will be comparing how close the two closest colors are to the source color,
    // and since the grays are all extremely close to each other, we won't get any useful data from the second
    // closest color if it's also a gray.
    final allAreGrays = closestColors.every(
      (c) => grayScaleNames.contains(c.scale),
    );
    if (!allAreGrays && grayScaleNames.contains(closestColors[0].scale)) {
      while (closestColors.length > 1 &&
          grayScaleNames.contains(closestColors[1].scale)) {
        closestColors.removeAt(1);
      }
    }

    if (closestColors.length < 2) {
      final scale = scales[closestColors[0].scale]!;
      return scale.map((c) => c.toColor()).toList();
    }

    final colorA = closestColors[0];
    final colorB = closestColors[1];

    // Light trigonometry ahead.
    //
    // We want to determine the color that is the closest to the source color. Sometimes it makes sense
    // to proportionally mix the two closest colors together, but sometimes it is not useful at all.
    // Color coords are spatial in 3D, however we can treat the data we have as a 2D projection that is good enough.
    //
    // Case 1:
    // If the distances between the source color, the 1st closest color (A) and the 2nd closest color (B) form
    // a triangle where NEITHER angle A nor B are larger than 90 degrees, then we want to mix the 1st and the 2nd
    // closest colors in the same proportion as distances AD and BD are to each other. Mixing the two would result
    // in a color that would be closer to the source color than either of the two original closest colors.
    // Example: source color is a desaturated blue, which is between "indigo" and "slate" scales.
    //
    //        C ← Source color
    //       /|⟍
    //      / |  ⟍
    //   b /  |    ⟍  a
    //    /   |      ⟍
    //   /    |        ⟍
    //  A --- D -------- B
    //        ↑
    //        The color we want to use as the base, which is a mix of A and B.
    //
    // Case 2:
    // If the distances between the source color, the 1st closest color (A) and the 2nd closest color (B) form
    // a triangle where EITHER angle A or B are larger than 90 degrees, then we don't care about point B because it's
    // directionally the same as A, as mixing A and B can't provide us with a color that is any closer to the source.
    // Example: source color is a saturated blue, with "blue" being the closest scale, and "indigo" just being further.
    //
    //      C ← Source color
    //       \⟍
    //        \  ⟍
    //         \    ⟍  a
    //        b \      ⟍
    //           \        ⟍
    //            A ------- B
    //            ↑
    //            The color we want to use as the base, which is not influenced by B.

    // We'll need all the lengths of the triangle sides, named after the angles they look at:
    final a = colorB.distance;
    final b = colorA.distance;
    final c = _deltaEOK(colorA.color, colorB.color);

    // We can get the ratios of AD to BD lengths with trigonometry using tangents,
    // as the ratio of the tangents of the opposite angles will match.
    final cosA = (b * b + c * c - a * a) / (2 * b * c);
    final radA = acos(cosA.clamp(-1.0, 1.0));
    final sinA = sin(radA);

    final cosB = (a * a + c * c - b * b) / (2 * a * c);
    final radB = acos(cosB.clamp(-1.0, 1.0));
    final sinB = sin(radB);

    if (sinA == 0 || sinB == 0) {
      final scale = scales[colorA.scale]!;
      return scale.map((c) => c.toColor()).toList();
    }

    // Tangent of angle C in the ACD triangle
    final tanC1 = cosA / sinA;

    // Tangent of angle C in the BCD triangle
    final tanC2 = cosB / sinB;

    // The ratio of the tangents corresponds to the ratio of the distances AD to BD
    // In the end, it means how much of scale B we want to mix into scale A.
    // If it's "0" or less, this is an obtuse triangle from case 2, and we use just scale A.
    final ratio = max(0.0, tanC1 / tanC2) * _kMixingFactor;

    // The base scale is going to be a mix of the two closest scales, with the mix ratio we determined before
    final scaleA = scales[colorA.scale]!;
    final scaleB = scales[colorB.scale]!;
    final mixedScale = List.generate(12, (i) {
      return _mixOklch(scaleA[i], scaleB[i], ratio);
    });

    // Get the closest color from the pre-mixed scale we created
    final baseColor = mixedScale.reduce(
      (a, b) => _deltaEOK(sourceOklch, a) < _deltaEOK(sourceOklch, b) ? a : b,
    );

    // Note the chroma difference between the source color and the base color
    final ratioC = sourceOklch.c / (baseColor.c == 0 ? 0.001 : baseColor.c);

    // Modify hue and chroma of the scale to match the source color
    final adjustedScale = mixedScale.map((color) {
      final newC = min(sourceOklch.c * _kChromaCapMultiplier, color.c * ratioC);
      return OkLch(
        color.l,
        newC,
        sourceOklch.h,
      );
    }).toList();

    // Transpose lightness curve to anchor to background using Bezier easing
    final isLight = adjustedScale[0].l > 0.5;
    final lightModeEasing = [0.0, 2.0, 0.0, 2.0];
    final darkModeEasing = [1.0, 0.0, 1.0, 0.0];

    if (isLight) {
      final lightnessScale = adjustedScale.map((c) => c.l).toList();
      final bgL = backgroundOklch.l.clamp(0.0, 1.0);
      // Add white as the first "step" of the light scale
      final newLightness = _transposeProgressionStart(bgL, [
        1.0,
        ...lightnessScale,
      ], lightModeEasing);
      // Remove the step we added
      newLightness.removeAt(0);

      return List.generate(12, (i) {
        return OkLch(
          newLightness[i].clamp(0.0, 1.0),
          adjustedScale[i].c,
          adjustedScale[i].h,
        ).toColor();
      });
    } else {
      // Dark mode
      var ease = List<double>.from(darkModeEasing);
      final referenceBgL = adjustedScale[0].l;
      final bgL = backgroundOklch.l.clamp(0.0, 1.0);

      // If background is lighter than step 0, we want to gradually change the easing to linear
      final ratioL = bgL / (referenceBgL == 0 ? 0.001 : referenceBgL);

      if (ratioL > 1.0) {
        const maxRatio = 1.5;
        for (int i = 0; i < ease.length; i++) {
          final metaRatio = (ratioL - 1.0) * (maxRatio / (maxRatio - 1.0));
          ease[i] = ratioL > maxRatio
              ? 0.0
              : (ease[i] * (1.0 - metaRatio)).clamp(0.0, 1.0);
        }
      }

      final lightnessScale = adjustedScale.map((c) => c.l).toList();
      final newLightness = _transposeProgressionStart(
        bgL,
        lightnessScale,
        ease,
      );

      return List.generate(12, (i) {
        return OkLch(
          newLightness[i].clamp(0.0, 1.0),
          adjustedScale[i].c,
          adjustedScale[i].h,
        ).toColor();
      });
    }
  }

  /// Calculate perceptual distance (ΔE_OK) in OKLCH space.
  static double _deltaEOK(OkLch a, OkLch b) {
    final dL = a.l - b.l;
    final dC = a.c - b.c;

    double dH = a.h - b.h;
    if (dH.isNaN) {
      dH = 0.0;
    } else if (dH.abs() > 180) {
      if (dH > 0) {
        dH -= 360;
      } else {
        dH += 360;
      }
    }
    final dHChroma = 2 * sqrt(a.c * b.c) * sin(dH * pi / 360);

    return sqrt(dL * dL + dC * dC + dHChroma * dHChroma);
  }

  /// Get step 9 color and contrast color.
  ///
  /// If the accent base color is close to the page background color, it's likely
  /// white on white or black on black, so we want to return something that makes sense instead.
  static _Step9Result _getStep9Colors(
    List<Color> scale,
    OkLch accentBaseColor,
  ) {
    final referenceBackgroundColor = scale[0].toOkLch();
    final distance = _deltaEOK(accentBaseColor, referenceBackgroundColor) * 100;

    // Use scale step 9 if accent is too close to background
    if (distance < 25) {
      final step9Oklch = scale[8].toOkLch();
      return _Step9Result(
        step9: step9Oklch,
        contrast: _getTextColor(step9Oklch),
      );
    }

    return _Step9Result(
      step9: accentBaseColor,
      contrast: _getTextColor(accentBaseColor),
    );
  }

  /// Calculate APCA luminance with soft clamp for near-black colors.
  static double _getAPCALuminance(Color color) {
    final r = color.r;
    final g = color.g;
    final b = color.b;

    double linearize(double c) => pow(c, 2.4).toDouble();
    final rLin = linearize(r);
    final gLin = linearize(g);
    final bLin = linearize(b);

    final Y = 0.2126 * rLin + 0.7152 * gLin + 0.0722 * bLin;

    const blkThrs = 0.022;
    const blkClmp = 1.414;

    if (Y < blkThrs) {
      return Y + pow(blkThrs - Y, blkClmp) * 0.000000001;
    }

    return Y;
  }

  /// Calculate APCA contrast (Lc value) between text and background.
  static double _calculateAPCA(Color text, Color background) {
    final Ytxt = _getAPCALuminance(text);
    final Ybg = _getAPCALuminance(background);

    const normTXT = 0.57;
    const normBG = 0.56;
    const revTXT = 0.65;
    const revBG = 0.62;

    if (Ybg > Ytxt) {
      final contrast = pow(Ybg, normBG) - pow(Ytxt, normTXT);
      if (contrast < 0.1) return 0.0;
      return (contrast * 100.0) - 2.7;
    } else {
      final contrast = pow(Ybg, revBG) - pow(Ytxt, revTXT);
      final absContrast = contrast.abs();
      if (absContrast < 0.1) return 0.0;
      return -(absContrast * 100.0) + 2.7;
    }
  }

  /// Get appropriate text color for background using APCA contrast.
  static OkLch _getTextColor(OkLch background) {
    final white = OkLch(1.0, 0.0, 0.0);
    final whiteColor = white.toColor();
    final backgroundLchColor = background.toColor();

    final contrastValue = _calculateAPCA(whiteColor, backgroundLchColor);

    if (contrastValue.abs() < 40) {
      final C = background.c;
      final H = background.h.isNaN ? 0.0 : background.h;
      return OkLch(0.25, max(0.08 * C, 0.04), H);
    }

    return white;
  }

  /// Generate button hover color by adjusting lightness and chroma.
  ///
  /// Finds closest in-scale color to donate the chroma and hue.
  /// Especially useful when the source color is pure white or black,
  /// but the gray scale is tinted.
  static Color _getButtonHoverColor(OkLch source, List<List<Color>> scales) {
    final L = source.l;
    final C = source.c;
    final H = source.h;

    final newL = L > 0.4 ? L - 0.03 / (L + 0.1) : L + 0.03 / (L + 0.1);
    final newC = L > 0.4 && !H.isNaN ? C * _kButtonHoverChromaMultiplier : C;
    var buttonHoverColor = OkLch(newL, newC, H);

    // Find closest in-scale color to donate the chroma and hue
    var closestColor = buttonHoverColor;
    var minDistance = double.infinity;

    for (final scale in scales) {
      for (final color in scale) {
        final colorOklch = color.toOkLch();
        final distance = _deltaEOK(buttonHoverColor, colorOklch);
        if (distance < minDistance) {
          minDistance = distance;
          closestColor = colorOklch;
        }
      }
    }

    buttonHoverColor = OkLch(
      buttonHoverColor.l,
      closestColor.c,
      closestColor.h,
    );

    return buttonHoverColor.toColor();
  }

  /// Calculate alpha color using reverse alpha blending.
  ///
  /// Solves for foreground color and alpha that blend to target over background.
  /// Formula: target = background * (1 - alpha) + foreground * alpha
  /// Solving for alpha: alpha = (target - background) / (foreground - background)
  ///
  /// Expects 0-1 numbers for the RGB channels, but works with 0-255 integers internally.
  static Color _getAlphaColorSrgb(
    Color targetColor,
    Color backgroundColor, {
    double? targetAlpha,
  }) {
    // Convert colors to 0-255 RGB
    final tr = (targetColor.r * 255.0).round();
    final tg = (targetColor.g * 255.0).round();
    final tb = (targetColor.b * 255.0).round();
    final br = (backgroundColor.r * 255.0).round();
    final bg = (backgroundColor.g * 255.0).round();
    final bb = (backgroundColor.b * 255.0).round();

    // Is the background color lighter, RGB-wise, than target color?
    // Decide whether we want to add as little color or as much color as possible,
    // darkening or lightening the background respectively.
    // If at least one of the bits of the target RGB value
    // is lighter than the background, we want to lighten it.
    final desiredRgb = (tr > br || tg > bg || tb > bb) ? 255 : 0;

    double alphaR = 0.0;
    double alphaG = 0.0;
    double alphaB = 0.0;

    if (desiredRgb - br != 0) {
      alphaR = (tr - br) / (desiredRgb - br);
    } else if (tr == br) {
      alphaR = 0.0;
    }
    if (desiredRgb - bg != 0) {
      alphaG = (tg - bg) / (desiredRgb - bg);
    } else if (tg == bg) {
      alphaG = 0.0;
    }
    if (desiredRgb - bb != 0) {
      alphaB = (tb - bb) / (desiredRgb - bb);
    } else if (tb == bb) {
      alphaB = 0.0;
    }

    if (tr == br && tg == bg && tb == bb) {
      return Color.fromRGBO(0, 0, 0, 0.0);
    }

    final isPureGray = (alphaR == alphaG && alphaG == alphaB);

    // No need for precision gymnastics with pure grays, and we can get cleaner output
    if (isPureGray) {
      // Convert back to 0-1 values
      final v = desiredRgb / 255.0;
      final alpha = alphaR.clamp(0.0, 1.0);
      return Color.fromRGBO(
        (v * 255).round(),
        (v * 255).round(),
        (v * 255).round(),
        alpha,
      );
    }

    final maxAlpha =
        targetAlpha ??
        [
          alphaR,
          alphaG,
          alphaB,
        ].reduce((a, b) => a > b ? a : b).clamp(0.0, 1.0);

    final r = ((br * (1 - maxAlpha) - tr) / maxAlpha * -1).round().clamp(
      0,
      255,
    );
    final g = ((bg * (1 - maxAlpha) - tg) / maxAlpha * -1).round().clamp(
      0,
      255,
    );
    final b = ((bb * (1 - maxAlpha) - tb) / maxAlpha * -1).round().clamp(
      0,
      255,
    );

    final blendedR = _blendAlpha(r, maxAlpha, br);
    final blendedG = _blendAlpha(g, maxAlpha, bg);
    final blendedB = _blendAlpha(b, maxAlpha, bb);

    int finalR = r;
    int finalG = g;
    int finalB = b;

    // Correct for rounding errors in light mode
    if (desiredRgb == 0) {
      if (tr <= br && tr != blendedR) {
        finalR = tr > blendedR ? r + 1 : r - 1;
      }
      if (tg <= bg && tg != blendedG) {
        finalG = tg > blendedG ? g + 1 : g - 1;
      }
      if (tb <= bb && tb != blendedB) {
        finalB = tb > blendedB ? b + 1 : b - 1;
      }
    }

    // Correct for rounding errors in dark mode
    if (desiredRgb == 255) {
      if (tr >= br && tr != blendedR) {
        finalR = tr > blendedR ? r + 1 : r - 1;
      }
      if (tg >= bg && tg != blendedG) {
        finalG = tg > blendedG ? g + 1 : g - 1;
      }
      if (tb >= bb && tb != blendedB) {
        finalB = tb > blendedB ? b + 1 : b - 1;
      }
    }

    return Color.fromRGBO(
      finalR.clamp(0, 255),
      finalG.clamp(0, 255),
      finalB.clamp(0, 255),
      maxAlpha,
    );
  }

  /// Important – This rounding is how the browser actually overlays
  /// transparent RGB bits over each other. It does NOT round the whole result altogether.
  static int _blendAlpha(int foreground, double alpha, int background) {
    return (background * (1 - alpha)).round() + (foreground * alpha).round();
  }

  /// Convert hex string to Color.
  /// Handles:
  /// - Full form (#RRGGBB) - 6 characters
  /// - Short form (#RGB) - 3 characters
  /// - With alpha (#RRGGBBAA) - 8 characters
  static Color hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    
    // Handle 8-character hex with alpha (RRGGBBAA)
    if (hex.length == 8) {
      final rgbHex = hex.substring(0, 6);
      final alphaHex = hex.substring(6, 8);
      final rgbColor = Color(int.parse(rgbHex, radix: 16) | 0xFF000000);
      final alpha = int.parse(alphaHex, radix: 16);
      return rgbColor.withAlpha(alpha);
    }
    
    // Handle 3-character short form (RGB)
    if (hex.length == 3) {
      hex = hex.split('').map((c) => c + c).join('');
    }
    
    // Handle 6-character form (RRGGBB)
    if (hex.length != 6) {
      throw ArgumentError('Invalid hex color: #$hex');
    }
    return Color(int.parse(hex, radix: 16) | 0xFF000000);
  }

  /// Convert Color to hex string (RRGGBB format).
  static String _colorToHex(Color color) {
    final argb = color.value;
    final hex = argb.toRadixString(16).padLeft(8, '0');
    return '#${hex.substring(2).toUpperCase()}';
  }

  /// Cubic Bezier easing function.
  ///
  /// Uses Newton's method to solve for t given x, then evaluates y at that t.
  /// This allows us to use Bezier curves as easing functions where we specify
  /// the x (input) and get the y (output) value.
  static double _bezierEasing(
    double t,
    double p1x,
    double p1y,
    double p2x,
    double p2y,
  ) {
    t = t.clamp(0.0, 1.0);

    final cx = 3.0 * p1x;
    final bx = 3.0 * (p2x - p1x) - cx;
    final ax = 1.0 - cx - bx;

    final cy = 3.0 * p1y;
    final by = 3.0 * (p2y - p1y) - cy;
    final ay = 1.0 - cy - by;

    // Newton's method to solve for t
    double currentT = t;
    for (int i = 0; i < 8; i++) {
      final currentX = _bezierX(currentT, ax, bx, cx);
      final currentDx = _bezierXDerivative(currentT, ax, bx, cx);
      if (currentDx.abs() < 1e-6) break;
      currentT = currentT - (currentX - t) / currentDx;
      currentT = currentT.clamp(0.0, 1.0);
    }

    return _bezierY(currentT, ay, by, cy);
  }

  static double _bezierX(double t, double ax, double bx, double cx) {
    return ((ax * t + bx) * t + cx) * t;
  }

  static double _bezierY(double t, double ay, double by, double cy) {
    return ((ay * t + by) * t + cy) * t;
  }

  static double _bezierXDerivative(double t, double ax, double bx, double cx) {
    return (3.0 * ax * t + 2.0 * bx) * t + cx;
  }

  /// Transpose lightness progression to anchor to background using Bezier easing.
  ///
  /// Adjusts the lightness values in the array so that the first value (arr[0])
  /// is transposed to the target value (to), using a Bezier curve to control
  /// how the adjustment is distributed across the progression.
  static List<double> _transposeProgressionStart(
    double to,
    List<double> arr,
    List<double> curve,
  ) {
    return arr.asMap().entries.map((entry) {
      final i = entry.key;
      final n = entry.value;
      final lastIndex = arr.length - 1;
      final diff = arr[0] - to;
      double fn(double t) =>
          _bezierEasing(t, curve[0], curve[1], curve[2], curve[3]);
      return n - diff * fn(1 - i / lastIndex);
    }).toList();
  }
}

/// Generated color scales and variants.
///
/// Returned by [FlyColorGenerator.generate] with all generated color scales
/// and utility colors for use in your application.
///
/// Contains:
/// - [accentScale] - 12-step accent color scale
/// - [grayScale] - 12-step gray color scale
/// - [accentScaleAlpha] - Alpha variants of accent scale
/// - [grayScaleAlpha] - Alpha variants of gray scale
/// - [accentContrast] - Contrast color for text on accent backgrounds
/// - [accentSurface] - Surface color variant
/// - [background] - The background color used for generation
///
/// See [FlyColorGenerator] for usage examples.
class GeneratedColors {
  final List<Color> accentScale;
  final List<Color> accentScaleAlpha;
  final List<Color> grayScale;
  final List<Color> grayScaleAlpha;
  final Color accentContrast;
  final Color accentSurface;
  final Color background;

  GeneratedColors({
    required this.accentScale,
    required this.accentScaleAlpha,
    required this.grayScale,
    required this.grayScaleAlpha,
    required this.accentContrast,
    required this.accentSurface,
    required this.background,
  });

  /// Get hex string for a color
  String colorToHex(Color color) {
    final argb = color.value;
    final hex = argb.toRadixString(16).padLeft(8, '0');
    return '#${hex.substring(2).toUpperCase()}';
  }

  /// Get hex string for a color with alpha (8-character format: #RRGGBBAA).
  String colorToHexWithAlpha(Color color) {
    final argb = color.value;
    final r = (argb >> 16) & 0xFF;
    final g = (argb >> 8) & 0xFF;
    final b = argb & 0xFF;
    final a = (argb >> 24) & 0xFF;

    return '#${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}'
        '${a.toRadixString(16).padLeft(2, '0')}';
  }

  /// Get all colors as a map.
  Map<String, dynamic> toMap() {
    return {
      'accentScale': accentScale.map((c) => colorToHex(c)).toList(),
      'accentScaleAlpha': accentScaleAlpha.map((c) => colorToHex(c)).toList(),
      'grayScale': grayScale.map((c) => colorToHex(c)).toList(),
      'grayScaleAlpha': grayScaleAlpha.map((c) => colorToHex(c)).toList(),
      'accentContrast': colorToHex(accentContrast),
      'accentSurface': colorToHex(accentSurface),
      'background': colorToHex(background),
    };
  }
}
