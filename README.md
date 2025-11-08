# FlyColor

A Radix inspired color system for Flutter with perceptually uniform, contextually aware 12-step color scales.

## Overview

FlyColor provides a comprehensive set of predefined color scales ready to use in your Flutter applications. Each color includes 12 steps plus contrast and surface variants, with full support for light and dark modes.

For advanced use cases, FlyColor also includes a color generator that creates custom scales from any accent, gray, and background colors using OKLCH color space and sophisticated blending algorithms.

## Key Features

- **Predefined Color Scales**: 30+ color scales (blue, red, green, etc.) with 12 steps each
- **Light & Dark Mode**: Built-in support for both themes with context-aware access
- **Perceptually Uniform**: Uses OKLCH color space for accurate color manipulation
- **Custom Scale Generation**: Generate custom color scales from any input colors (advanced)

## Usage

### Predefined Color Scales

FlyColor provides predefined color scales for all colors:

```dart
import 'package:flycolor/colors.dart';

// Direct access (defaults to light mode)
FlyColor.blue9;        // Step 9 (seed/base color)
FlyColor.blue1;        // Lightest step
FlyColor.blue12;       // Darkest step
FlyColor.blueContrast; // Contrast color for text
FlyColor.blueSurface;  // Surface color

// Dark mode variants
FlyColor.blue1Dark;
FlyColor.blue9Dark;

// Explicit light/dark mode
FlyColorLight.blue1;
FlyColorDark.blue1;

// Context-aware (automatically switches based on theme)
FlyColor.of(context).blue1;
FlyColor.of(context).gray9;
```

### Generating Custom Color Scales (Advanced)

For custom color schemes, you can generate scales from any accent, gray, and background colors:

```dart
import 'package:flycolor/generator.dart';

final colors = FlyColorGenerator.generate(
  appearance: 'light',
  accent: '#3D63DD',
  gray: '#8B8D98',
  background: '#FFFFFF',
);

// Access the generated scales
colors.accentScale;      // 12-step accent scale
colors.grayScale;        // 12-step gray scale
colors.accentScaleAlpha; // Alpha variants
colors.accentContrast;   // Contrast color for text
colors.accentSurface;    // Surface color
```

For detailed technical documentation on the generator, see `lib/generator.dart`.
