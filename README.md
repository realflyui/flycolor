# FlyColor

A Radix inspired color system for Flutter with perceptually uniform, contextually aware 12-step color scales.

## Key Features

- **Predefined Color Scales**: 30+ color scales (blue, red, green, etc.) with 12 steps each
- **Automatic Dark Mode**: Built-in support for both themes with context-aware access. Dark mode Just Works
- **Accessibility Made Easy**: Text colors are guaranteed to pass target contrast ratios against the corresponding background colors
- **APCA Text Contrast**: Contrast targets are based on the modern APCA contrast algorithm, which accurately predicts how human vision perceives text
- **Transparent Variants**: Each scale has matching alpha color variants (1A-12A), which are handy for UI components that need to blend into colored backgrounds
- **P3 Color Gamut Support**: Template matching uses P3 color space for accurate blending, enabling the brightest yellows and reds possible
- **Designed for User Interfaces**: Each step is designed with a specific use case in mind, such as backgrounds, hover states, borders, overlays, or text
- **Perceptually Uniform**: Uses OKLCH color space for accurate color manipulation
- **Custom Scale Generation**: Generate custom color scales from any input colors (advanced)

For a deep dive into the color generation algorithm and architecture, see [ARCHITECTURE.md](ARCHITECTURE.md).

## Usage

### Predefined Color Scales

FlyColor provides predefined color scales for all colors:

```dart
import 'package:flycolor/flycolor.dart';

// Explicit light/dark mode access
FlyColorLight.blue1;        // Lightest step (light mode)
FlyColorLight.blue9;        // Step 9 (seed/base color)
FlyColorLight.blue12;       // Darkest step
FlyColorLight.blueContrast; // Contrast color for text
FlyColorLight.blueSurface;   // Surface color
FlyColorLight.blue1A;       // Alpha variant

FlyColorDark.blue1;         // Lightest step (dark mode)
FlyColorDark.blue9;         // Step 9 (seed/base color)
FlyColorDark.blue12;        // Darkest step

// Convenience: Step 9 colors (same for light/dark)
FlyColor.blue;              // Step 9 seed color

// Context-aware (automatically switches based on theme)
final colors = FlyColor.of(context);
colors.blue1;               // Automatically uses light or dark variant
colors.blue9;
colors.blueContrast;
colors.blue1A;              // Alpha variant
```

For detailed technical documentation on the colors, see `lib/colors.dart`.

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
colors.accentScale;        // 12-step accent scale (List<Color>)
colors.grayScale;          // 12-step gray scale (List<Color>)
colors.accentScaleAlpha;   // Alpha variants of accent scale (List<Color>)
colors.grayScaleAlpha;     // Alpha variants of gray scale (List<Color>)
colors.accentContrast;     // Contrast color for text on accent backgrounds
colors.accentSurface;      // Surface color variant
colors.background;         // The background color used for generation
```

For detailed technical documentation on the generator, see `lib/generator.dart`.
