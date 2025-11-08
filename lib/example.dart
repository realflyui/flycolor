import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'generator.dart';
import 'colors.dart';

class FlyColorExample extends StatefulWidget {
  final void Function(ThemeMode) onThemeModeChanged;
  final ThemeMode currentThemeMode;

  const FlyColorExample({
    super.key,
    required this.onThemeModeChanged,
    required this.currentThemeMode,
  });

  @override
  State<FlyColorExample> createState() => _FlyColorExampleState();
}

class _FlyColorExampleState extends State<FlyColorExample> {
  String _accentColor = '#0090FF';
  String _grayColor = '#8B8D98';
  String _backgroundColor = '#FFFFFF';
  bool _backgroundColorManuallySet = false;
  bool _showAlpha = false;

  GeneratedColors? _generatedColors;
  late TextEditingController _accentColorController;
  late TextEditingController _grayColorController;
  late TextEditingController _backgroundColorController;

  @override
  void initState() {
    super.initState();
    _accentColorController = TextEditingController(text: _accentColor);
    _grayColorController = TextEditingController(text: _grayColor);
    _backgroundColorController = TextEditingController(text: _backgroundColor);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize colors if not already initialized
    if (_generatedColors == null) {
      _generateColors(context);
    }
    // Only update background color automatically if it wasn't manually set
    if (!_backgroundColorManuallySet) {
      final brightness = Theme.of(context).brightness;
      final newBackground = brightness == Brightness.light ? '#FFFFFF' : '#111111';
      if (_backgroundColor != newBackground) {
        setState(() {
          _backgroundColor = newBackground;
          _backgroundColorController.text = newBackground;
        });
        _generateColors(context);
      }
    }
  }

  @override
  void dispose() {
    _accentColorController.dispose();
    _grayColorController.dispose();
    _backgroundColorController.dispose();
    super.dispose();
  }


  void _generateColors(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final appearance = brightness == Brightness.light ? 'light' : 'dark';
    setState(() {
      _generatedColors = FlyColorGenerator.generate(
        appearance: appearance,
        accent: _accentColor,
        gray: _grayColor,
        background: _backgroundColor,
      );
    });
  }

  void _resetToDefaults(BuildContext context) {
    setState(() {
      _accentColor = '#0090FF';
      _grayColor = '#8B8D98';
      _backgroundColor = '#FFFFFF';
      _backgroundColorManuallySet = false;
      _accentColorController.text = _accentColor;
      _grayColorController.text = _grayColor;
      _backgroundColorController.text = _backgroundColor;
      widget.onThemeModeChanged(ThemeMode.light);
      _generateColors(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading if colors not initialized yet
    if (_generatedColors == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    final textColor = FlyColor.of(context).gray12;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('FlyColor'),
        backgroundColor: _generatedColors!.background,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: false,
                  icon: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      border: Border.all(color: Colors.grey[600]!, width: 1),
                    ),
                  ),
                ),
                ButtonSegment(
                  value: true,
                  icon: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[600]!, width: 1),
                    ),
                    child: CustomPaint(
                      painter: _CheckerboardPainter(
                        color1: isDark ? const Color(0xFF404040) : const Color(0xFFE0E0E0),
                        color2: isDark ? const Color(0xFF505050) : const Color(0xFFF5F5F5),
                      ),
                    ),
                  ),
                ),
              ],
              selected: {_showAlpha},
              onSelectionChanged: (Set<bool> newSelection) {
                setState(() {
                  _showAlpha = newSelection.first;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode, size: 18),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode, size: 18),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto, size: 18),
                ),
              ],
              selected: {widget.currentThemeMode},
              onSelectionChanged: (Set<ThemeMode> newSelection) {
                final newMode = newSelection.first;
                widget.onThemeModeChanged(newMode);
                // Background color will be updated when theme actually changes
                // via didChangeDependencies
              },
            ),
          ),
        ],
      ),
      backgroundColor: _generatedColors!.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAllColors(context, textColor),
            const SizedBox(height: 24),

            // Controls
            _buildControls(context, textColor),
            const SizedBox(height: 24),

            // Color Scales
            _buildColorScaleHeaders(textColor),
            _showAlpha
                ? _buildAlphaColorScaleRow(
                  _generatedColors!.accentScaleAlpha,
                  'Accent',
                  textColor,
                  isDark: isDark,
                  contrastColor: _generatedColors!.accentContrast,
                  surfaceColor: _generatedColors!.accentSurface,
                )
                : _buildColorScaleRow(
                  _generatedColors!.accentScale,
                  'Accent',
                  textColor,
                  contrastColor: _generatedColors!.accentContrast,
                  surfaceColor: _generatedColors!.accentSurface,
                ),
            const SizedBox(height: 4),
            _showAlpha
                ? _buildAlphaColorScaleRow(
                  _generatedColors!.grayScaleAlpha,
                  'Gray',
                  textColor,
                  isDark: isDark,
                )
                : _buildColorScaleRow(_generatedColors!.grayScale, 'Gray', textColor),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context, Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Custom Palette',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Builder(
                builder: (context) => OutlinedButton.icon(
                  onPressed: () => _resetToDefaults(context),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reset'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Accent color picker
          _buildColorPicker(
            context,
            'Accent Color',
            _accentColor,
            _accentColorController,
            (color) {
              setState(() {
                _accentColor = color;
                _accentColorController.text = color;
              });
              _generateColors(context);
            },
          ),
          const SizedBox(height: 12),

          // Gray color picker
          _buildColorPicker(
            context,
            'Gray Color',
            _grayColor,
            _grayColorController,
            (color) {
              setState(() {
                _grayColor = color;
                _grayColorController.text = color;
              });
              _generateColors(context);
            },
          ),
          const SizedBox(height: 12),

          // Background color picker
          _buildColorPicker(
            context,
            'Background',
            _backgroundColor,
            _backgroundColorController,
            (color) {
              setState(() {
                _backgroundColor = color;
                _backgroundColorManuallySet = true;
                _backgroundColorController.text = color;
              });
              // Change theme mode based on color brightness
              final colorObj = FlyColorGenerator.hexToColor(color);
              final luminance = colorObj.computeLuminance();
              // If color is light (luminance > 0.5), use light theme; otherwise dark
              widget.onThemeModeChanged(
                luminance > 0.5 ? ThemeMode.light : ThemeMode.dark,
              );
              _generateColors(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildColorPicker(
    BuildContext context,
    String label,
    String currentColor,
    TextEditingController controller,
    void Function(String) onColorChanged,
  ) {
    final isAccent = label == 'Accent Color';
    final isGray = label == 'Gray Color';
    final presetColors = isAccent
        ? [
            FlyColor.blue.toHex(),
            FlyColor.green.toHex(),
            FlyColor.red.toHex(),
            FlyColor.purple.toHex(),
            FlyColor.orange.toHex(),
            FlyColor.cyan.toHex(),
            FlyColor.violet.toHex(),
            FlyColor.pink.toHex(),
          ]
        : [
            '#FFFFFF', // light
            '#111111', // dark
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(width: 100, child: Text('$label: ')),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: FlyColorGenerator.hexToColor(currentColor),
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) {
                  if (value.startsWith('#') && value.length == 7) {
                    onColorChanged(value);
                  }
                },
              ),
            ),
          ],
        ),
        // Preset seed buttons (only for accent and background, not gray)
        if (!isGray) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 108.0),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: presetColors.map((color) {
                return _buildQuickColorButton(
                  color,
                  currentColor,
                  onColorChanged,
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickColorButton(
    String color,
    String currentColor,
    void Function(String) onColorChanged,
  ) {
    final isSelected = color == currentColor;
    return GestureDetector(
      onTap: () => onColorChanged(color),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: FlyColorGenerator.hexToColor(color),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  void _showColorInfoDialog(
    BuildContext context,
    Color color,
    String colorName,
    int? step,
    bool isAlpha,
  ) {
    // Pre-compute all values outside the builder
    final hex = color.toHex();
    final r = color.red;
    final g = color.green;
    final b = color.blue;
    final a = color.alpha;
    final opacity = (a / 255).toStringAsFixed(2);
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final checkerboardColor1 = isDark ? const Color(0xFF404040) : const Color(0xFFE0E0E0);
    final checkerboardColor2 = isDark ? const Color(0xFF505050) : const Color(0xFFF5F5F5);

    // Generate usage examples
    String? usageCode;
    String? contextAwareUsage;
    
    if (step != null) {
      // Regular color step
      final suffix = isAlpha ? 'A' : '';
      // Current mode usage - show dark variant if in dark mode, light variant if in light mode
      if (isDark) {
        usageCode = 'FlyColor.$colorName$step${isAlpha ? 'DarkA' : 'Dark'}';
      } else {
        usageCode = 'FlyColor.$colorName$step$suffix';
      }
      contextAwareUsage = 'FlyColor.of(context).$colorName$step$suffix';
    } else {
      // Contrast or Surface
      if (colorName.endsWith(' Contrast')) {
        final baseName = colorName.replaceAll(' Contrast', '');
        usageCode = isDark 
            ? 'FlyColor.${baseName}ContrastDark'
            : 'FlyColor.${baseName}Contrast';
        contextAwareUsage = 'FlyColor.of(context).${baseName}Contrast';
      } else if (colorName.endsWith(' Surface')) {
        final baseName = colorName.replaceAll(' Surface', '');
        usageCode = isDark
            ? 'FlyColor.${baseName}SurfaceDark'
            : 'FlyColor.${baseName}Surface';
        contextAwareUsage = 'FlyColor.of(context).${baseName}Surface';
      }
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Color preview
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isAlpha
                      ? RepaintBoundary(
                          child: Stack(
                            children: [
                              // Checkerboard background
                              CustomPaint(
                                painter: _CheckerboardPainter(
                                  color1: checkerboardColor1,
                                  color2: checkerboardColor2,
                                ),
                                child: Container(),
                              ),
                              // Color overlay
                              Container(color: color),
                            ],
                          ),
                        )
                      : Container(color: color),
                ),
              ),
              const SizedBox(height: 20),
              // Color name and step
              Text(
                step != null ? '$colorName $step${isAlpha ? 'A' : ''}' : colorName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              // Hex code
              _buildInfoRow(
                context,
                'Hex',
                hex,
                textColor: textColor,
                onCopy: () {
                  Clipboard.setData(ClipboardData(text: hex));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Copied $hex to clipboard')),
                  );
                },
              ),
              const SizedBox(height: 8),
              // RGB
              _buildInfoRow(
                context,
                'RGB',
                'rgb($r, $g, $b)',
                textColor: textColor,
                onCopy: () {
                  Clipboard.setData(ClipboardData(text: 'rgb($r, $g, $b)'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied RGB to clipboard')),
                  );
                },
              ),
              if (isAlpha || a < 255) ...[
                const SizedBox(height: 8),
                // Alpha
                _buildInfoRow(
                  context,
                  'Alpha',
                  '$a / 255 ($opacity)',
                  textColor: textColor,
                  onCopy: () {
                    Clipboard.setData(ClipboardData(text: a.toString()));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied alpha to clipboard')),
                    );
                  },
                ),
              ],
              if (usageCode != null)
                Builder(
                  builder: (context) {
                    final directCode = usageCode!;
                    final contextCode = contextAwareUsage;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Divider(color: textColor.withOpacity(0.2)),
                        const SizedBox(height: 16),
                        Text(
                          'Usage',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Direct access
                        _buildInfoRow(
                          context,
                          'Direct',
                          directCode,
                          textColor: textColor,
                          onCopy: () {
                            Clipboard.setData(ClipboardData(text: directCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Copied $directCode to clipboard')),
                            );
                          },
                        ),
                        if (contextCode != null) ...[
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            context,
                            'Context',
                            contextCode,
                            textColor: textColor,
                            onCopy: () {
                              Clipboard.setData(ClipboardData(text: contextCode));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Copied $contextCode to clipboard')),
                              );
                            },
                          ),
                        ],
                      ],
                    );
                  },
                ),
              const SizedBox(height: 20),
              // Close button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    VoidCallback? onCopy,
    Color? textColor,
  }) {
    final effectiveTextColor = textColor ?? 
        (Theme.of(context).brightness == Brightness.dark 
            ? Colors.white 
            : Colors.black);

    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: effectiveTextColor.withOpacity(0.7),
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'monospace',
              color: effectiveTextColor,
            ),
          ),
        ),
        if (onCopy != null)
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: onCopy,
            tooltip: 'Copy to clipboard',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }

  Widget _buildColorScaleHeaders(Color textColor) {
    return Column(
      children: [
        // Category labels row
        Row(
          children: [
            SizedBox(
              width: 60,
              child: const Text(
                '',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  // Backgrounds (steps 1-2)
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Text(
                        'Backgrounds',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                  // Interactive components (steps 3-5)
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: Text(
                        'Interactive components',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                  // Borders and separators (steps 6-8)
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: Text(
                        'Borders and separators',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                  // Solid colors (steps 9-10)
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Text(
                        'Solid colors',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                  // Accessible text (steps 11-12)
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Text(
                        'Accessible text',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                  // Contrast and Surface
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Text(
                        'Contrast & Surface',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Step numbers row
        Row(
          children: [
            SizedBox(
              width: 60,
              child: const Text(
                '',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  // Step numbers 1-12
                  ...List.generate(12, (index) {
                    return Expanded(
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                    );
                  }),
                  // Contrast column
                  Expanded(
                    child: Center(
                      child: Text(
                        'C',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                  // Surface column
                  Expanded(
                    child: Center(
                      child: Text(
                        'S',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildColorScaleRow(
    List<Color> colors,
    String label,
    Color textColor, {
    Color? contrastColor,
    Color? surfaceColor,
  }) {
    return Row(
      children: [
        // Label column
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        // Color swatches
        Expanded(
          child: Row(
            children: [
              // 12 step colors
              ...colors.asMap().entries.map((entry) {
                final index = entry.key;
                final color = entry.value;
                final step = index + 1;
                return Expanded(
                  child: RepaintBoundary(
                    child: GestureDetector(
                      onTap: () => _showColorInfoDialog(
                        context,
                        color,
                        label,
                        step,
                        false,
                      ),
                      child: Container(
                        height: 80,
                        color: color,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showColorInfoDialog(
                              context,
                              color,
                              label,
                              step,
                              false,
                            ),
                            child: Container(),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
              // Contrast color
              if (contrastColor != null)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final color = contrastColor;
                      return GestureDetector(
                        onTap: () => _showColorInfoDialog(
                          context,
                          color,
                          '$label Contrast',
                          null,
                          false,
                        ),
                        child: Container(
                          height: 80,
                          color: color,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showColorInfoDialog(
                                context,
                                color,
                                '$label Contrast',
                                null,
                                false,
                              ),
                              child: Container(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                Expanded(
                  child: Container(
                    height: 80,
                    color: Colors.transparent,
                  ),
                ),
              // Surface color
              if (surfaceColor != null)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final color = surfaceColor;
                      return GestureDetector(
                        onTap: () => _showColorInfoDialog(
                          context,
                          color,
                          '$label Surface',
                          null,
                          false,
                        ),
                        child: Container(
                          height: 80,
                          color: color,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showColorInfoDialog(
                                context,
                                color,
                                '$label Surface',
                                null,
                                false,
                              ),
                              child: Container(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                Expanded(
                  child: Container(
                    height: 80,
                    color: Colors.transparent,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlphaColorScaleRow(
    List<Color> colors,
    String label,
    Color textColor, {
    bool isDark = false,
    Color? contrastColor,
    Color? surfaceColor,
  }) {
    return Row(
      children: [
        // Label column
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        // Color swatches with background pattern
        Expanded(
          child: Row(
            children: [
              // 12 step colors with checkerboard background
              ...colors.asMap().entries.map((entry) {
                final index = entry.key;
                final color = entry.value;
                final step = index + 1;
                return Expanded(
                  child: RepaintBoundary(
                    child: GestureDetector(
                      onTap: () => _showColorInfoDialog(
                        context,
                        color,
                        label,
                        step,
                        true,
                      ),
                      child: Container(
                        height: 80,
                        child: CustomPaint(
                          painter: _CheckerboardPainter(
                            color1: isDark ? const Color(0xFF404040) : const Color(0xFFE0E0E0),
                            color2: isDark ? const Color(0xFF505050) : const Color(0xFFF5F5F5),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showColorInfoDialog(
                                context,
                                color,
                                label,
                                step,
                                true,
                              ),
                              child: Container(color: color),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
              // Contrast color
              if (contrastColor != null)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final color = contrastColor;
                      return GestureDetector(
                        onTap: () => _showColorInfoDialog(
                          context,
                          color,
                          '$label Contrast',
                          null,
                          false,
                        ),
                        child: Container(
                          height: 80,
                          color: color,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showColorInfoDialog(
                                context,
                                color,
                                '$label Contrast',
                                null,
                                false,
                              ),
                              child: Container(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                Expanded(
                  child: Container(
                    height: 80,
                    color: Colors.transparent,
                  ),
                ),
              // Surface color
              if (surfaceColor != null)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final color = surfaceColor;
                      return GestureDetector(
                        onTap: () => _showColorInfoDialog(
                          context,
                          color,
                          '$label Surface',
                          null,
                          false,
                        ),
                        child: Container(
                          height: 80,
                          color: color,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showColorInfoDialog(
                                context,
                                color,
                                '$label Surface',
                                null,
                                false,
                              ),
                              child: Container(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                Expanded(
                  child: Container(
                    height: 80,
                    color: Colors.transparent,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }



  Widget _buildAllColors(BuildContext context, Color textColor) {
    final brightness = Theme.of(context).brightness;
    final isLight = brightness == Brightness.light;

    // Helper function to get alpha color for a step
    Color getAlphaColor(String name, int step) {
      switch (name) {
        case 'gray':
          return isLight
              ? [FlyColor.gray1A, FlyColor.gray2A, FlyColor.gray3A, FlyColor.gray4A, FlyColor.gray5A, FlyColor.gray6A, FlyColor.gray7A, FlyColor.gray8A, FlyColor.gray9A, FlyColor.gray10A, FlyColor.gray11A, FlyColor.gray12A][step - 1]
              : [FlyColor.gray1DarkA, FlyColor.gray2DarkA, FlyColor.gray3DarkA, FlyColor.gray4DarkA, FlyColor.gray5DarkA, FlyColor.gray6DarkA, FlyColor.gray7DarkA, FlyColor.gray8DarkA, FlyColor.gray9DarkA, FlyColor.gray10DarkA, FlyColor.gray11DarkA, FlyColor.gray12DarkA][step - 1];
        case 'mauve':
          return isLight
              ? [FlyColor.mauve1A, FlyColor.mauve2A, FlyColor.mauve3A, FlyColor.mauve4A, FlyColor.mauve5A, FlyColor.mauve6A, FlyColor.mauve7A, FlyColor.mauve8A, FlyColor.mauve9A, FlyColor.mauve10A, FlyColor.mauve11A, FlyColor.mauve12A][step - 1]
              : [FlyColor.mauve1DarkA, FlyColor.mauve2DarkA, FlyColor.mauve3DarkA, FlyColor.mauve4DarkA, FlyColor.mauve5DarkA, FlyColor.mauve6DarkA, FlyColor.mauve7DarkA, FlyColor.mauve8DarkA, FlyColor.mauve9DarkA, FlyColor.mauve10DarkA, FlyColor.mauve11DarkA, FlyColor.mauve12DarkA][step - 1];
        case 'slate':
          return isLight
              ? [FlyColor.slate1A, FlyColor.slate2A, FlyColor.slate3A, FlyColor.slate4A, FlyColor.slate5A, FlyColor.slate6A, FlyColor.slate7A, FlyColor.slate8A, FlyColor.slate9A, FlyColor.slate10A, FlyColor.slate11A, FlyColor.slate12A][step - 1]
              : [FlyColor.slate1DarkA, FlyColor.slate2DarkA, FlyColor.slate3DarkA, FlyColor.slate4DarkA, FlyColor.slate5DarkA, FlyColor.slate6DarkA, FlyColor.slate7DarkA, FlyColor.slate8DarkA, FlyColor.slate9DarkA, FlyColor.slate10DarkA, FlyColor.slate11DarkA, FlyColor.slate12DarkA][step - 1];
        case 'sage':
          return isLight
              ? [FlyColor.sage1A, FlyColor.sage2A, FlyColor.sage3A, FlyColor.sage4A, FlyColor.sage5A, FlyColor.sage6A, FlyColor.sage7A, FlyColor.sage8A, FlyColor.sage9A, FlyColor.sage10A, FlyColor.sage11A, FlyColor.sage12A][step - 1]
              : [FlyColor.sage1DarkA, FlyColor.sage2DarkA, FlyColor.sage3DarkA, FlyColor.sage4DarkA, FlyColor.sage5DarkA, FlyColor.sage6DarkA, FlyColor.sage7DarkA, FlyColor.sage8DarkA, FlyColor.sage9DarkA, FlyColor.sage10DarkA, FlyColor.sage11DarkA, FlyColor.sage12DarkA][step - 1];
        case 'olive':
          return isLight
              ? [FlyColor.olive1A, FlyColor.olive2A, FlyColor.olive3A, FlyColor.olive4A, FlyColor.olive5A, FlyColor.olive6A, FlyColor.olive7A, FlyColor.olive8A, FlyColor.olive9A, FlyColor.olive10A, FlyColor.olive11A, FlyColor.olive12A][step - 1]
              : [FlyColor.olive1DarkA, FlyColor.olive2DarkA, FlyColor.olive3DarkA, FlyColor.olive4DarkA, FlyColor.olive5DarkA, FlyColor.olive6DarkA, FlyColor.olive7DarkA, FlyColor.olive8DarkA, FlyColor.olive9DarkA, FlyColor.olive10DarkA, FlyColor.olive11DarkA, FlyColor.olive12DarkA][step - 1];
        case 'sand':
          return isLight
              ? [FlyColor.sand1A, FlyColor.sand2A, FlyColor.sand3A, FlyColor.sand4A, FlyColor.sand5A, FlyColor.sand6A, FlyColor.sand7A, FlyColor.sand8A, FlyColor.sand9A, FlyColor.sand10A, FlyColor.sand11A, FlyColor.sand12A][step - 1]
              : [FlyColor.sand1DarkA, FlyColor.sand2DarkA, FlyColor.sand3DarkA, FlyColor.sand4DarkA, FlyColor.sand5DarkA, FlyColor.sand6DarkA, FlyColor.sand7DarkA, FlyColor.sand8DarkA, FlyColor.sand9DarkA, FlyColor.sand10DarkA, FlyColor.sand11DarkA, FlyColor.sand12DarkA][step - 1];
        case 'tomato':
          return isLight
              ? [FlyColor.tomato1A, FlyColor.tomato2A, FlyColor.tomato3A, FlyColor.tomato4A, FlyColor.tomato5A, FlyColor.tomato6A, FlyColor.tomato7A, FlyColor.tomato8A, FlyColor.tomato9A, FlyColor.tomato10A, FlyColor.tomato11A, FlyColor.tomato12A][step - 1]
              : [FlyColor.tomato1DarkA, FlyColor.tomato2DarkA, FlyColor.tomato3DarkA, FlyColor.tomato4DarkA, FlyColor.tomato5DarkA, FlyColor.tomato6DarkA, FlyColor.tomato7DarkA, FlyColor.tomato8DarkA, FlyColor.tomato9DarkA, FlyColor.tomato10DarkA, FlyColor.tomato11DarkA, FlyColor.tomato12DarkA][step - 1];
        case 'red':
          return isLight
              ? [FlyColor.red1A, FlyColor.red2A, FlyColor.red3A, FlyColor.red4A, FlyColor.red5A, FlyColor.red6A, FlyColor.red7A, FlyColor.red8A, FlyColor.red9A, FlyColor.red10A, FlyColor.red11A, FlyColor.red12A][step - 1]
              : [FlyColor.red1DarkA, FlyColor.red2DarkA, FlyColor.red3DarkA, FlyColor.red4DarkA, FlyColor.red5DarkA, FlyColor.red6DarkA, FlyColor.red7DarkA, FlyColor.red8DarkA, FlyColor.red9DarkA, FlyColor.red10DarkA, FlyColor.red11DarkA, FlyColor.red12DarkA][step - 1];
        case 'ruby':
          return isLight
              ? [FlyColor.ruby1A, FlyColor.ruby2A, FlyColor.ruby3A, FlyColor.ruby4A, FlyColor.ruby5A, FlyColor.ruby6A, FlyColor.ruby7A, FlyColor.ruby8A, FlyColor.ruby9A, FlyColor.ruby10A, FlyColor.ruby11A, FlyColor.ruby12A][step - 1]
              : [FlyColor.ruby1DarkA, FlyColor.ruby2DarkA, FlyColor.ruby3DarkA, FlyColor.ruby4DarkA, FlyColor.ruby5DarkA, FlyColor.ruby6DarkA, FlyColor.ruby7DarkA, FlyColor.ruby8DarkA, FlyColor.ruby9DarkA, FlyColor.ruby10DarkA, FlyColor.ruby11DarkA, FlyColor.ruby12DarkA][step - 1];
        case 'crimson':
          return isLight
              ? [FlyColor.crimson1A, FlyColor.crimson2A, FlyColor.crimson3A, FlyColor.crimson4A, FlyColor.crimson5A, FlyColor.crimson6A, FlyColor.crimson7A, FlyColor.crimson8A, FlyColor.crimson9A, FlyColor.crimson10A, FlyColor.crimson11A, FlyColor.crimson12A][step - 1]
              : [FlyColor.crimson1DarkA, FlyColor.crimson2DarkA, FlyColor.crimson3DarkA, FlyColor.crimson4DarkA, FlyColor.crimson5DarkA, FlyColor.crimson6DarkA, FlyColor.crimson7DarkA, FlyColor.crimson8DarkA, FlyColor.crimson9DarkA, FlyColor.crimson10DarkA, FlyColor.crimson11DarkA, FlyColor.crimson12DarkA][step - 1];
        case 'pink':
          return isLight
              ? [FlyColor.pink1A, FlyColor.pink2A, FlyColor.pink3A, FlyColor.pink4A, FlyColor.pink5A, FlyColor.pink6A, FlyColor.pink7A, FlyColor.pink8A, FlyColor.pink9A, FlyColor.pink10A, FlyColor.pink11A, FlyColor.pink12A][step - 1]
              : [FlyColor.pink1DarkA, FlyColor.pink2DarkA, FlyColor.pink3DarkA, FlyColor.pink4DarkA, FlyColor.pink5DarkA, FlyColor.pink6DarkA, FlyColor.pink7DarkA, FlyColor.pink8DarkA, FlyColor.pink9DarkA, FlyColor.pink10DarkA, FlyColor.pink11DarkA, FlyColor.pink12DarkA][step - 1];
        case 'plum':
          return isLight
              ? [FlyColor.plum1A, FlyColor.plum2A, FlyColor.plum3A, FlyColor.plum4A, FlyColor.plum5A, FlyColor.plum6A, FlyColor.plum7A, FlyColor.plum8A, FlyColor.plum9A, FlyColor.plum10A, FlyColor.plum11A, FlyColor.plum12A][step - 1]
              : [FlyColor.plum1DarkA, FlyColor.plum2DarkA, FlyColor.plum3DarkA, FlyColor.plum4DarkA, FlyColor.plum5DarkA, FlyColor.plum6DarkA, FlyColor.plum7DarkA, FlyColor.plum8DarkA, FlyColor.plum9DarkA, FlyColor.plum10DarkA, FlyColor.plum11DarkA, FlyColor.plum12DarkA][step - 1];
        case 'purple':
          return isLight
              ? [FlyColor.purple1A, FlyColor.purple2A, FlyColor.purple3A, FlyColor.purple4A, FlyColor.purple5A, FlyColor.purple6A, FlyColor.purple7A, FlyColor.purple8A, FlyColor.purple9A, FlyColor.purple10A, FlyColor.purple11A, FlyColor.purple12A][step - 1]
              : [FlyColor.purple1DarkA, FlyColor.purple2DarkA, FlyColor.purple3DarkA, FlyColor.purple4DarkA, FlyColor.purple5DarkA, FlyColor.purple6DarkA, FlyColor.purple7DarkA, FlyColor.purple8DarkA, FlyColor.purple9DarkA, FlyColor.purple10DarkA, FlyColor.purple11DarkA, FlyColor.purple12DarkA][step - 1];
        case 'violet':
          return isLight
              ? [FlyColor.violet1A, FlyColor.violet2A, FlyColor.violet3A, FlyColor.violet4A, FlyColor.violet5A, FlyColor.violet6A, FlyColor.violet7A, FlyColor.violet8A, FlyColor.violet9A, FlyColor.violet10A, FlyColor.violet11A, FlyColor.violet12A][step - 1]
              : [FlyColor.violet1DarkA, FlyColor.violet2DarkA, FlyColor.violet3DarkA, FlyColor.violet4DarkA, FlyColor.violet5DarkA, FlyColor.violet6DarkA, FlyColor.violet7DarkA, FlyColor.violet8DarkA, FlyColor.violet9DarkA, FlyColor.violet10DarkA, FlyColor.violet11DarkA, FlyColor.violet12DarkA][step - 1];
        case 'iris':
          return isLight
              ? [FlyColor.iris1A, FlyColor.iris2A, FlyColor.iris3A, FlyColor.iris4A, FlyColor.iris5A, FlyColor.iris6A, FlyColor.iris7A, FlyColor.iris8A, FlyColor.iris9A, FlyColor.iris10A, FlyColor.iris11A, FlyColor.iris12A][step - 1]
              : [FlyColor.iris1DarkA, FlyColor.iris2DarkA, FlyColor.iris3DarkA, FlyColor.iris4DarkA, FlyColor.iris5DarkA, FlyColor.iris6DarkA, FlyColor.iris7DarkA, FlyColor.iris8DarkA, FlyColor.iris9DarkA, FlyColor.iris10DarkA, FlyColor.iris11DarkA, FlyColor.iris12DarkA][step - 1];
        case 'indigo':
          return isLight
              ? [FlyColor.indigo1A, FlyColor.indigo2A, FlyColor.indigo3A, FlyColor.indigo4A, FlyColor.indigo5A, FlyColor.indigo6A, FlyColor.indigo7A, FlyColor.indigo8A, FlyColor.indigo9A, FlyColor.indigo10A, FlyColor.indigo11A, FlyColor.indigo12A][step - 1]
              : [FlyColor.indigo1DarkA, FlyColor.indigo2DarkA, FlyColor.indigo3DarkA, FlyColor.indigo4DarkA, FlyColor.indigo5DarkA, FlyColor.indigo6DarkA, FlyColor.indigo7DarkA, FlyColor.indigo8DarkA, FlyColor.indigo9DarkA, FlyColor.indigo10DarkA, FlyColor.indigo11DarkA, FlyColor.indigo12DarkA][step - 1];
        case 'blue':
          return isLight
              ? [FlyColor.blue1A, FlyColor.blue2A, FlyColor.blue3A, FlyColor.blue4A, FlyColor.blue5A, FlyColor.blue6A, FlyColor.blue7A, FlyColor.blue8A, FlyColor.blue9A, FlyColor.blue10A, FlyColor.blue11A, FlyColor.blue12A][step - 1]
              : [FlyColor.blue1DarkA, FlyColor.blue2DarkA, FlyColor.blue3DarkA, FlyColor.blue4DarkA, FlyColor.blue5DarkA, FlyColor.blue6DarkA, FlyColor.blue7DarkA, FlyColor.blue8DarkA, FlyColor.blue9DarkA, FlyColor.blue10DarkA, FlyColor.blue11DarkA, FlyColor.blue12DarkA][step - 1];
        case 'cyan':
          return isLight
              ? [FlyColor.cyan1A, FlyColor.cyan2A, FlyColor.cyan3A, FlyColor.cyan4A, FlyColor.cyan5A, FlyColor.cyan6A, FlyColor.cyan7A, FlyColor.cyan8A, FlyColor.cyan9A, FlyColor.cyan10A, FlyColor.cyan11A, FlyColor.cyan12A][step - 1]
              : [FlyColor.cyan1DarkA, FlyColor.cyan2DarkA, FlyColor.cyan3DarkA, FlyColor.cyan4DarkA, FlyColor.cyan5DarkA, FlyColor.cyan6DarkA, FlyColor.cyan7DarkA, FlyColor.cyan8DarkA, FlyColor.cyan9DarkA, FlyColor.cyan10DarkA, FlyColor.cyan11DarkA, FlyColor.cyan12DarkA][step - 1];
        case 'teal':
          return isLight
              ? [FlyColor.teal1A, FlyColor.teal2A, FlyColor.teal3A, FlyColor.teal4A, FlyColor.teal5A, FlyColor.teal6A, FlyColor.teal7A, FlyColor.teal8A, FlyColor.teal9A, FlyColor.teal10A, FlyColor.teal11A, FlyColor.teal12A][step - 1]
              : [FlyColor.teal1DarkA, FlyColor.teal2DarkA, FlyColor.teal3DarkA, FlyColor.teal4DarkA, FlyColor.teal5DarkA, FlyColor.teal6DarkA, FlyColor.teal7DarkA, FlyColor.teal8DarkA, FlyColor.teal9DarkA, FlyColor.teal10DarkA, FlyColor.teal11DarkA, FlyColor.teal12DarkA][step - 1];
        case 'jade':
          return isLight
              ? [FlyColor.jade1A, FlyColor.jade2A, FlyColor.jade3A, FlyColor.jade4A, FlyColor.jade5A, FlyColor.jade6A, FlyColor.jade7A, FlyColor.jade8A, FlyColor.jade9A, FlyColor.jade10A, FlyColor.jade11A, FlyColor.jade12A][step - 1]
              : [FlyColor.jade1DarkA, FlyColor.jade2DarkA, FlyColor.jade3DarkA, FlyColor.jade4DarkA, FlyColor.jade5DarkA, FlyColor.jade6DarkA, FlyColor.jade7DarkA, FlyColor.jade8DarkA, FlyColor.jade9DarkA, FlyColor.jade10DarkA, FlyColor.jade11DarkA, FlyColor.jade12DarkA][step - 1];
        case 'green':
          return isLight
              ? [FlyColor.green1A, FlyColor.green2A, FlyColor.green3A, FlyColor.green4A, FlyColor.green5A, FlyColor.green6A, FlyColor.green7A, FlyColor.green8A, FlyColor.green9A, FlyColor.green10A, FlyColor.green11A, FlyColor.green12A][step - 1]
              : [FlyColor.green1DarkA, FlyColor.green2DarkA, FlyColor.green3DarkA, FlyColor.green4DarkA, FlyColor.green5DarkA, FlyColor.green6DarkA, FlyColor.green7DarkA, FlyColor.green8DarkA, FlyColor.green9DarkA, FlyColor.green10DarkA, FlyColor.green11DarkA, FlyColor.green12DarkA][step - 1];
        case 'grass':
          return isLight
              ? [FlyColor.grass1A, FlyColor.grass2A, FlyColor.grass3A, FlyColor.grass4A, FlyColor.grass5A, FlyColor.grass6A, FlyColor.grass7A, FlyColor.grass8A, FlyColor.grass9A, FlyColor.grass10A, FlyColor.grass11A, FlyColor.grass12A][step - 1]
              : [FlyColor.grass1DarkA, FlyColor.grass2DarkA, FlyColor.grass3DarkA, FlyColor.grass4DarkA, FlyColor.grass5DarkA, FlyColor.grass6DarkA, FlyColor.grass7DarkA, FlyColor.grass8DarkA, FlyColor.grass9DarkA, FlyColor.grass10DarkA, FlyColor.grass11DarkA, FlyColor.grass12DarkA][step - 1];
        case 'brown':
          return isLight
              ? [FlyColor.brown1A, FlyColor.brown2A, FlyColor.brown3A, FlyColor.brown4A, FlyColor.brown5A, FlyColor.brown6A, FlyColor.brown7A, FlyColor.brown8A, FlyColor.brown9A, FlyColor.brown10A, FlyColor.brown11A, FlyColor.brown12A][step - 1]
              : [FlyColor.brown1DarkA, FlyColor.brown2DarkA, FlyColor.brown3DarkA, FlyColor.brown4DarkA, FlyColor.brown5DarkA, FlyColor.brown6DarkA, FlyColor.brown7DarkA, FlyColor.brown8DarkA, FlyColor.brown9DarkA, FlyColor.brown10DarkA, FlyColor.brown11DarkA, FlyColor.brown12DarkA][step - 1];
        case 'orange':
          return isLight
              ? [FlyColor.orange1A, FlyColor.orange2A, FlyColor.orange3A, FlyColor.orange4A, FlyColor.orange5A, FlyColor.orange6A, FlyColor.orange7A, FlyColor.orange8A, FlyColor.orange9A, FlyColor.orange10A, FlyColor.orange11A, FlyColor.orange12A][step - 1]
              : [FlyColor.orange1DarkA, FlyColor.orange2DarkA, FlyColor.orange3DarkA, FlyColor.orange4DarkA, FlyColor.orange5DarkA, FlyColor.orange6DarkA, FlyColor.orange7DarkA, FlyColor.orange8DarkA, FlyColor.orange9DarkA, FlyColor.orange10DarkA, FlyColor.orange11DarkA, FlyColor.orange12DarkA][step - 1];
        case 'sky':
          return isLight
              ? [FlyColor.sky1A, FlyColor.sky2A, FlyColor.sky3A, FlyColor.sky4A, FlyColor.sky5A, FlyColor.sky6A, FlyColor.sky7A, FlyColor.sky8A, FlyColor.sky9A, FlyColor.sky10A, FlyColor.sky11A, FlyColor.sky12A][step - 1]
              : [FlyColor.sky1DarkA, FlyColor.sky2DarkA, FlyColor.sky3DarkA, FlyColor.sky4DarkA, FlyColor.sky5DarkA, FlyColor.sky6DarkA, FlyColor.sky7DarkA, FlyColor.sky8DarkA, FlyColor.sky9DarkA, FlyColor.sky10DarkA, FlyColor.sky11DarkA, FlyColor.sky12DarkA][step - 1];
        case 'mint':
          return isLight
              ? [FlyColor.mint1A, FlyColor.mint2A, FlyColor.mint3A, FlyColor.mint4A, FlyColor.mint5A, FlyColor.mint6A, FlyColor.mint7A, FlyColor.mint8A, FlyColor.mint9A, FlyColor.mint10A, FlyColor.mint11A, FlyColor.mint12A][step - 1]
              : [FlyColor.mint1DarkA, FlyColor.mint2DarkA, FlyColor.mint3DarkA, FlyColor.mint4DarkA, FlyColor.mint5DarkA, FlyColor.mint6DarkA, FlyColor.mint7DarkA, FlyColor.mint8DarkA, FlyColor.mint9DarkA, FlyColor.mint10DarkA, FlyColor.mint11DarkA, FlyColor.mint12DarkA][step - 1];
        case 'lime':
          return isLight
              ? [FlyColor.lime1A, FlyColor.lime2A, FlyColor.lime3A, FlyColor.lime4A, FlyColor.lime5A, FlyColor.lime6A, FlyColor.lime7A, FlyColor.lime8A, FlyColor.lime9A, FlyColor.lime10A, FlyColor.lime11A, FlyColor.lime12A][step - 1]
              : [FlyColor.lime1DarkA, FlyColor.lime2DarkA, FlyColor.lime3DarkA, FlyColor.lime4DarkA, FlyColor.lime5DarkA, FlyColor.lime6DarkA, FlyColor.lime7DarkA, FlyColor.lime8DarkA, FlyColor.lime9DarkA, FlyColor.lime10DarkA, FlyColor.lime11DarkA, FlyColor.lime12DarkA][step - 1];
        case 'yellow':
          return isLight
              ? [FlyColor.yellow1A, FlyColor.yellow2A, FlyColor.yellow3A, FlyColor.yellow4A, FlyColor.yellow5A, FlyColor.yellow6A, FlyColor.yellow7A, FlyColor.yellow8A, FlyColor.yellow9A, FlyColor.yellow10A, FlyColor.yellow11A, FlyColor.yellow12A][step - 1]
              : [FlyColor.yellow1DarkA, FlyColor.yellow2DarkA, FlyColor.yellow3DarkA, FlyColor.yellow4DarkA, FlyColor.yellow5DarkA, FlyColor.yellow6DarkA, FlyColor.yellow7DarkA, FlyColor.yellow8DarkA, FlyColor.yellow9DarkA, FlyColor.yellow10DarkA, FlyColor.yellow11DarkA, FlyColor.yellow12DarkA][step - 1];
        case 'amber':
          return isLight
              ? [FlyColor.amber1A, FlyColor.amber2A, FlyColor.amber3A, FlyColor.amber4A, FlyColor.amber5A, FlyColor.amber6A, FlyColor.amber7A, FlyColor.amber8A, FlyColor.amber9A, FlyColor.amber10A, FlyColor.amber11A, FlyColor.amber12A][step - 1]
              : [FlyColor.amber1DarkA, FlyColor.amber2DarkA, FlyColor.amber3DarkA, FlyColor.amber4DarkA, FlyColor.amber5DarkA, FlyColor.amber6DarkA, FlyColor.amber7DarkA, FlyColor.amber8DarkA, FlyColor.amber9DarkA, FlyColor.amber10DarkA, FlyColor.amber11DarkA, FlyColor.amber12DarkA][step - 1];
        default:
          throw ArgumentError('Unknown color scale: $name');
      }
    }

    // Helper function to get color for a step (hardcoded for example page)
    Color getColor(String name, int step) {
      switch (name) {
        case 'gray':
          return isLight
              ? [FlyColor.gray1, FlyColor.gray2, FlyColor.gray3, FlyColor.gray4, FlyColor.gray5, FlyColor.gray6, FlyColor.gray7, FlyColor.gray8, FlyColor.gray9, FlyColor.gray10, FlyColor.gray11, FlyColor.gray12][step - 1]
              : [FlyColor.gray1Dark, FlyColor.gray2Dark, FlyColor.gray3Dark, FlyColor.gray4Dark, FlyColor.gray5Dark, FlyColor.gray6Dark, FlyColor.gray7Dark, FlyColor.gray8Dark, FlyColor.gray9Dark, FlyColor.gray10Dark, FlyColor.gray11Dark, FlyColor.gray12Dark][step - 1];
        case 'mauve':
          return isLight
              ? [FlyColor.mauve1, FlyColor.mauve2, FlyColor.mauve3, FlyColor.mauve4, FlyColor.mauve5, FlyColor.mauve6, FlyColor.mauve7, FlyColor.mauve8, FlyColor.mauve9, FlyColor.mauve10, FlyColor.mauve11, FlyColor.mauve12][step - 1]
              : [FlyColor.mauve1Dark, FlyColor.mauve2Dark, FlyColor.mauve3Dark, FlyColor.mauve4Dark, FlyColor.mauve5Dark, FlyColor.mauve6Dark, FlyColor.mauve7Dark, FlyColor.mauve8Dark, FlyColor.mauve9Dark, FlyColor.mauve10Dark, FlyColor.mauve11Dark, FlyColor.mauve12Dark][step - 1];
        case 'slate':
          return isLight
              ? [FlyColor.slate1, FlyColor.slate2, FlyColor.slate3, FlyColor.slate4, FlyColor.slate5, FlyColor.slate6, FlyColor.slate7, FlyColor.slate8, FlyColor.slate9, FlyColor.slate10, FlyColor.slate11, FlyColor.slate12][step - 1]
              : [FlyColor.slate1Dark, FlyColor.slate2Dark, FlyColor.slate3Dark, FlyColor.slate4Dark, FlyColor.slate5Dark, FlyColor.slate6Dark, FlyColor.slate7Dark, FlyColor.slate8Dark, FlyColor.slate9Dark, FlyColor.slate10Dark, FlyColor.slate11Dark, FlyColor.slate12Dark][step - 1];
        case 'sage':
          return isLight
              ? [FlyColor.sage1, FlyColor.sage2, FlyColor.sage3, FlyColor.sage4, FlyColor.sage5, FlyColor.sage6, FlyColor.sage7, FlyColor.sage8, FlyColor.sage9, FlyColor.sage10, FlyColor.sage11, FlyColor.sage12][step - 1]
              : [FlyColor.sage1Dark, FlyColor.sage2Dark, FlyColor.sage3Dark, FlyColor.sage4Dark, FlyColor.sage5Dark, FlyColor.sage6Dark, FlyColor.sage7Dark, FlyColor.sage8Dark, FlyColor.sage9Dark, FlyColor.sage10Dark, FlyColor.sage11Dark, FlyColor.sage12Dark][step - 1];
        case 'olive':
          return isLight
              ? [FlyColor.olive1, FlyColor.olive2, FlyColor.olive3, FlyColor.olive4, FlyColor.olive5, FlyColor.olive6, FlyColor.olive7, FlyColor.olive8, FlyColor.olive9, FlyColor.olive10, FlyColor.olive11, FlyColor.olive12][step - 1]
              : [FlyColor.olive1Dark, FlyColor.olive2Dark, FlyColor.olive3Dark, FlyColor.olive4Dark, FlyColor.olive5Dark, FlyColor.olive6Dark, FlyColor.olive7Dark, FlyColor.olive8Dark, FlyColor.olive9Dark, FlyColor.olive10Dark, FlyColor.olive11Dark, FlyColor.olive12Dark][step - 1];
        case 'sand':
          return isLight
              ? [FlyColor.sand1, FlyColor.sand2, FlyColor.sand3, FlyColor.sand4, FlyColor.sand5, FlyColor.sand6, FlyColor.sand7, FlyColor.sand8, FlyColor.sand9, FlyColor.sand10, FlyColor.sand11, FlyColor.sand12][step - 1]
              : [FlyColor.sand1Dark, FlyColor.sand2Dark, FlyColor.sand3Dark, FlyColor.sand4Dark, FlyColor.sand5Dark, FlyColor.sand6Dark, FlyColor.sand7Dark, FlyColor.sand8Dark, FlyColor.sand9Dark, FlyColor.sand10Dark, FlyColor.sand11Dark, FlyColor.sand12Dark][step - 1];
        case 'tomato':
          return isLight
              ? [FlyColor.tomato1, FlyColor.tomato2, FlyColor.tomato3, FlyColor.tomato4, FlyColor.tomato5, FlyColor.tomato6, FlyColor.tomato7, FlyColor.tomato8, FlyColor.tomato9, FlyColor.tomato10, FlyColor.tomato11, FlyColor.tomato12][step - 1]
              : [FlyColor.tomato1Dark, FlyColor.tomato2Dark, FlyColor.tomato3Dark, FlyColor.tomato4Dark, FlyColor.tomato5Dark, FlyColor.tomato6Dark, FlyColor.tomato7Dark, FlyColor.tomato8Dark, FlyColor.tomato9Dark, FlyColor.tomato10Dark, FlyColor.tomato11Dark, FlyColor.tomato12Dark][step - 1];
        case 'red':
          return isLight
              ? [FlyColor.red1, FlyColor.red2, FlyColor.red3, FlyColor.red4, FlyColor.red5, FlyColor.red6, FlyColor.red7, FlyColor.red8, FlyColor.red9, FlyColor.red10, FlyColor.red11, FlyColor.red12][step - 1]
              : [FlyColor.red1Dark, FlyColor.red2Dark, FlyColor.red3Dark, FlyColor.red4Dark, FlyColor.red5Dark, FlyColor.red6Dark, FlyColor.red7Dark, FlyColor.red8Dark, FlyColor.red9Dark, FlyColor.red10Dark, FlyColor.red11Dark, FlyColor.red12Dark][step - 1];
        case 'ruby':
          return isLight
              ? [FlyColor.ruby1, FlyColor.ruby2, FlyColor.ruby3, FlyColor.ruby4, FlyColor.ruby5, FlyColor.ruby6, FlyColor.ruby7, FlyColor.ruby8, FlyColor.ruby9, FlyColor.ruby10, FlyColor.ruby11, FlyColor.ruby12][step - 1]
              : [FlyColor.ruby1Dark, FlyColor.ruby2Dark, FlyColor.ruby3Dark, FlyColor.ruby4Dark, FlyColor.ruby5Dark, FlyColor.ruby6Dark, FlyColor.ruby7Dark, FlyColor.ruby8Dark, FlyColor.ruby9Dark, FlyColor.ruby10Dark, FlyColor.ruby11Dark, FlyColor.ruby12Dark][step - 1];
        case 'crimson':
          return isLight
              ? [FlyColor.crimson1, FlyColor.crimson2, FlyColor.crimson3, FlyColor.crimson4, FlyColor.crimson5, FlyColor.crimson6, FlyColor.crimson7, FlyColor.crimson8, FlyColor.crimson9, FlyColor.crimson10, FlyColor.crimson11, FlyColor.crimson12][step - 1]
              : [FlyColor.crimson1Dark, FlyColor.crimson2Dark, FlyColor.crimson3Dark, FlyColor.crimson4Dark, FlyColor.crimson5Dark, FlyColor.crimson6Dark, FlyColor.crimson7Dark, FlyColor.crimson8Dark, FlyColor.crimson9Dark, FlyColor.crimson10Dark, FlyColor.crimson11Dark, FlyColor.crimson12Dark][step - 1];
        case 'pink':
          return isLight
              ? [FlyColor.pink1, FlyColor.pink2, FlyColor.pink3, FlyColor.pink4, FlyColor.pink5, FlyColor.pink6, FlyColor.pink7, FlyColor.pink8, FlyColor.pink9, FlyColor.pink10, FlyColor.pink11, FlyColor.pink12][step - 1]
              : [FlyColor.pink1Dark, FlyColor.pink2Dark, FlyColor.pink3Dark, FlyColor.pink4Dark, FlyColor.pink5Dark, FlyColor.pink6Dark, FlyColor.pink7Dark, FlyColor.pink8Dark, FlyColor.pink9Dark, FlyColor.pink10Dark, FlyColor.pink11Dark, FlyColor.pink12Dark][step - 1];
        case 'plum':
          return isLight
              ? [FlyColor.plum1, FlyColor.plum2, FlyColor.plum3, FlyColor.plum4, FlyColor.plum5, FlyColor.plum6, FlyColor.plum7, FlyColor.plum8, FlyColor.plum9, FlyColor.plum10, FlyColor.plum11, FlyColor.plum12][step - 1]
              : [FlyColor.plum1Dark, FlyColor.plum2Dark, FlyColor.plum3Dark, FlyColor.plum4Dark, FlyColor.plum5Dark, FlyColor.plum6Dark, FlyColor.plum7Dark, FlyColor.plum8Dark, FlyColor.plum9Dark, FlyColor.plum10Dark, FlyColor.plum11Dark, FlyColor.plum12Dark][step - 1];
        case 'purple':
          return isLight
              ? [FlyColor.purple1, FlyColor.purple2, FlyColor.purple3, FlyColor.purple4, FlyColor.purple5, FlyColor.purple6, FlyColor.purple7, FlyColor.purple8, FlyColor.purple9, FlyColor.purple10, FlyColor.purple11, FlyColor.purple12][step - 1]
              : [FlyColor.purple1Dark, FlyColor.purple2Dark, FlyColor.purple3Dark, FlyColor.purple4Dark, FlyColor.purple5Dark, FlyColor.purple6Dark, FlyColor.purple7Dark, FlyColor.purple8Dark, FlyColor.purple9Dark, FlyColor.purple10Dark, FlyColor.purple11Dark, FlyColor.purple12Dark][step - 1];
        case 'violet':
          return isLight
              ? [FlyColor.violet1, FlyColor.violet2, FlyColor.violet3, FlyColor.violet4, FlyColor.violet5, FlyColor.violet6, FlyColor.violet7, FlyColor.violet8, FlyColor.violet9, FlyColor.violet10, FlyColor.violet11, FlyColor.violet12][step - 1]
              : [FlyColor.violet1Dark, FlyColor.violet2Dark, FlyColor.violet3Dark, FlyColor.violet4Dark, FlyColor.violet5Dark, FlyColor.violet6Dark, FlyColor.violet7Dark, FlyColor.violet8Dark, FlyColor.violet9Dark, FlyColor.violet10Dark, FlyColor.violet11Dark, FlyColor.violet12Dark][step - 1];
        case 'iris':
          return isLight
              ? [FlyColor.iris1, FlyColor.iris2, FlyColor.iris3, FlyColor.iris4, FlyColor.iris5, FlyColor.iris6, FlyColor.iris7, FlyColor.iris8, FlyColor.iris9, FlyColor.iris10, FlyColor.iris11, FlyColor.iris12][step - 1]
              : [FlyColor.iris1Dark, FlyColor.iris2Dark, FlyColor.iris3Dark, FlyColor.iris4Dark, FlyColor.iris5Dark, FlyColor.iris6Dark, FlyColor.iris7Dark, FlyColor.iris8Dark, FlyColor.iris9Dark, FlyColor.iris10Dark, FlyColor.iris11Dark, FlyColor.iris12Dark][step - 1];
        case 'indigo':
          return isLight
              ? [FlyColor.indigo1, FlyColor.indigo2, FlyColor.indigo3, FlyColor.indigo4, FlyColor.indigo5, FlyColor.indigo6, FlyColor.indigo7, FlyColor.indigo8, FlyColor.indigo9, FlyColor.indigo10, FlyColor.indigo11, FlyColor.indigo12][step - 1]
              : [FlyColor.indigo1Dark, FlyColor.indigo2Dark, FlyColor.indigo3Dark, FlyColor.indigo4Dark, FlyColor.indigo5Dark, FlyColor.indigo6Dark, FlyColor.indigo7Dark, FlyColor.indigo8Dark, FlyColor.indigo9Dark, FlyColor.indigo10Dark, FlyColor.indigo11Dark, FlyColor.indigo12Dark][step - 1];
        case 'blue':
          return isLight
              ? [FlyColor.blue1, FlyColor.blue2, FlyColor.blue3, FlyColor.blue4, FlyColor.blue5, FlyColor.blue6, FlyColor.blue7, FlyColor.blue8, FlyColor.blue9, FlyColor.blue10, FlyColor.blue11, FlyColor.blue12][step - 1]
              : [FlyColor.blue1Dark, FlyColor.blue2Dark, FlyColor.blue3Dark, FlyColor.blue4Dark, FlyColor.blue5Dark, FlyColor.blue6Dark, FlyColor.blue7Dark, FlyColor.blue8Dark, FlyColor.blue9Dark, FlyColor.blue10Dark, FlyColor.blue11Dark, FlyColor.blue12Dark][step - 1];
        case 'cyan':
          return isLight
              ? [FlyColor.cyan1, FlyColor.cyan2, FlyColor.cyan3, FlyColor.cyan4, FlyColor.cyan5, FlyColor.cyan6, FlyColor.cyan7, FlyColor.cyan8, FlyColor.cyan9, FlyColor.cyan10, FlyColor.cyan11, FlyColor.cyan12][step - 1]
              : [FlyColor.cyan1Dark, FlyColor.cyan2Dark, FlyColor.cyan3Dark, FlyColor.cyan4Dark, FlyColor.cyan5Dark, FlyColor.cyan6Dark, FlyColor.cyan7Dark, FlyColor.cyan8Dark, FlyColor.cyan9Dark, FlyColor.cyan10Dark, FlyColor.cyan11Dark, FlyColor.cyan12Dark][step - 1];
        case 'teal':
          return isLight
              ? [FlyColor.teal1, FlyColor.teal2, FlyColor.teal3, FlyColor.teal4, FlyColor.teal5, FlyColor.teal6, FlyColor.teal7, FlyColor.teal8, FlyColor.teal9, FlyColor.teal10, FlyColor.teal11, FlyColor.teal12][step - 1]
              : [FlyColor.teal1Dark, FlyColor.teal2Dark, FlyColor.teal3Dark, FlyColor.teal4Dark, FlyColor.teal5Dark, FlyColor.teal6Dark, FlyColor.teal7Dark, FlyColor.teal8Dark, FlyColor.teal9Dark, FlyColor.teal10Dark, FlyColor.teal11Dark, FlyColor.teal12Dark][step - 1];
        case 'jade':
          return isLight
              ? [FlyColor.jade1, FlyColor.jade2, FlyColor.jade3, FlyColor.jade4, FlyColor.jade5, FlyColor.jade6, FlyColor.jade7, FlyColor.jade8, FlyColor.jade9, FlyColor.jade10, FlyColor.jade11, FlyColor.jade12][step - 1]
              : [FlyColor.jade1Dark, FlyColor.jade2Dark, FlyColor.jade3Dark, FlyColor.jade4Dark, FlyColor.jade5Dark, FlyColor.jade6Dark, FlyColor.jade7Dark, FlyColor.jade8Dark, FlyColor.jade9Dark, FlyColor.jade10Dark, FlyColor.jade11Dark, FlyColor.jade12Dark][step - 1];
        case 'green':
          return isLight
              ? [FlyColor.green1, FlyColor.green2, FlyColor.green3, FlyColor.green4, FlyColor.green5, FlyColor.green6, FlyColor.green7, FlyColor.green8, FlyColor.green9, FlyColor.green10, FlyColor.green11, FlyColor.green12][step - 1]
              : [FlyColor.green1Dark, FlyColor.green2Dark, FlyColor.green3Dark, FlyColor.green4Dark, FlyColor.green5Dark, FlyColor.green6Dark, FlyColor.green7Dark, FlyColor.green8Dark, FlyColor.green9Dark, FlyColor.green10Dark, FlyColor.green11Dark, FlyColor.green12Dark][step - 1];
        case 'grass':
          return isLight
              ? [FlyColor.grass1, FlyColor.grass2, FlyColor.grass3, FlyColor.grass4, FlyColor.grass5, FlyColor.grass6, FlyColor.grass7, FlyColor.grass8, FlyColor.grass9, FlyColor.grass10, FlyColor.grass11, FlyColor.grass12][step - 1]
              : [FlyColor.grass1Dark, FlyColor.grass2Dark, FlyColor.grass3Dark, FlyColor.grass4Dark, FlyColor.grass5Dark, FlyColor.grass6Dark, FlyColor.grass7Dark, FlyColor.grass8Dark, FlyColor.grass9Dark, FlyColor.grass10Dark, FlyColor.grass11Dark, FlyColor.grass12Dark][step - 1];
        case 'brown':
          return isLight
              ? [FlyColor.brown1, FlyColor.brown2, FlyColor.brown3, FlyColor.brown4, FlyColor.brown5, FlyColor.brown6, FlyColor.brown7, FlyColor.brown8, FlyColor.brown9, FlyColor.brown10, FlyColor.brown11, FlyColor.brown12][step - 1]
              : [FlyColor.brown1Dark, FlyColor.brown2Dark, FlyColor.brown3Dark, FlyColor.brown4Dark, FlyColor.brown5Dark, FlyColor.brown6Dark, FlyColor.brown7Dark, FlyColor.brown8Dark, FlyColor.brown9Dark, FlyColor.brown10Dark, FlyColor.brown11Dark, FlyColor.brown12Dark][step - 1];
        case 'orange':
          return isLight
              ? [FlyColor.orange1, FlyColor.orange2, FlyColor.orange3, FlyColor.orange4, FlyColor.orange5, FlyColor.orange6, FlyColor.orange7, FlyColor.orange8, FlyColor.orange9, FlyColor.orange10, FlyColor.orange11, FlyColor.orange12][step - 1]
              : [FlyColor.orange1Dark, FlyColor.orange2Dark, FlyColor.orange3Dark, FlyColor.orange4Dark, FlyColor.orange5Dark, FlyColor.orange6Dark, FlyColor.orange7Dark, FlyColor.orange8Dark, FlyColor.orange9Dark, FlyColor.orange10Dark, FlyColor.orange11Dark, FlyColor.orange12Dark][step - 1];
        case 'sky':
          return isLight
              ? [FlyColor.sky1, FlyColor.sky2, FlyColor.sky3, FlyColor.sky4, FlyColor.sky5, FlyColor.sky6, FlyColor.sky7, FlyColor.sky8, FlyColor.sky9, FlyColor.sky10, FlyColor.sky11, FlyColor.sky12][step - 1]
              : [FlyColor.sky1Dark, FlyColor.sky2Dark, FlyColor.sky3Dark, FlyColor.sky4Dark, FlyColor.sky5Dark, FlyColor.sky6Dark, FlyColor.sky7Dark, FlyColor.sky8Dark, FlyColor.sky9Dark, FlyColor.sky10Dark, FlyColor.sky11Dark, FlyColor.sky12Dark][step - 1];
        case 'mint':
          return isLight
              ? [FlyColor.mint1, FlyColor.mint2, FlyColor.mint3, FlyColor.mint4, FlyColor.mint5, FlyColor.mint6, FlyColor.mint7, FlyColor.mint8, FlyColor.mint9, FlyColor.mint10, FlyColor.mint11, FlyColor.mint12][step - 1]
              : [FlyColor.mint1Dark, FlyColor.mint2Dark, FlyColor.mint3Dark, FlyColor.mint4Dark, FlyColor.mint5Dark, FlyColor.mint6Dark, FlyColor.mint7Dark, FlyColor.mint8Dark, FlyColor.mint9Dark, FlyColor.mint10Dark, FlyColor.mint11Dark, FlyColor.mint12Dark][step - 1];
        case 'lime':
          return isLight
              ? [FlyColor.lime1, FlyColor.lime2, FlyColor.lime3, FlyColor.lime4, FlyColor.lime5, FlyColor.lime6, FlyColor.lime7, FlyColor.lime8, FlyColor.lime9, FlyColor.lime10, FlyColor.lime11, FlyColor.lime12][step - 1]
              : [FlyColor.lime1Dark, FlyColor.lime2Dark, FlyColor.lime3Dark, FlyColor.lime4Dark, FlyColor.lime5Dark, FlyColor.lime6Dark, FlyColor.lime7Dark, FlyColor.lime8Dark, FlyColor.lime9Dark, FlyColor.lime10Dark, FlyColor.lime11Dark, FlyColor.lime12Dark][step - 1];
        case 'yellow':
          return isLight
              ? [FlyColor.yellow1, FlyColor.yellow2, FlyColor.yellow3, FlyColor.yellow4, FlyColor.yellow5, FlyColor.yellow6, FlyColor.yellow7, FlyColor.yellow8, FlyColor.yellow9, FlyColor.yellow10, FlyColor.yellow11, FlyColor.yellow12][step - 1]
              : [FlyColor.yellow1Dark, FlyColor.yellow2Dark, FlyColor.yellow3Dark, FlyColor.yellow4Dark, FlyColor.yellow5Dark, FlyColor.yellow6Dark, FlyColor.yellow7Dark, FlyColor.yellow8Dark, FlyColor.yellow9Dark, FlyColor.yellow10Dark, FlyColor.yellow11Dark, FlyColor.yellow12Dark][step - 1];
        case 'amber':
          return isLight
              ? [FlyColor.amber1, FlyColor.amber2, FlyColor.amber3, FlyColor.amber4, FlyColor.amber5, FlyColor.amber6, FlyColor.amber7, FlyColor.amber8, FlyColor.amber9, FlyColor.amber10, FlyColor.amber11, FlyColor.amber12][step - 1]
              : [FlyColor.amber1Dark, FlyColor.amber2Dark, FlyColor.amber3Dark, FlyColor.amber4Dark, FlyColor.amber5Dark, FlyColor.amber6Dark, FlyColor.amber7Dark, FlyColor.amber8Dark, FlyColor.amber9Dark, FlyColor.amber10Dark, FlyColor.amber11Dark, FlyColor.amber12Dark][step - 1];
        default:
          throw ArgumentError('Unknown color scale: $name');
      }
    }

    // Helper function to get contrast color
    Color getContrastColor(String name) {
      switch (name) {
        case 'gray': return isLight ? FlyColor.grayContrast : FlyColor.grayContrastDark;
        case 'mauve': return isLight ? FlyColor.mauveContrast : FlyColor.mauveContrastDark;
        case 'slate': return isLight ? FlyColor.slateContrast : FlyColor.slateContrastDark;
        case 'sage': return isLight ? FlyColor.sageContrast : FlyColor.sageContrastDark;
        case 'olive': return isLight ? FlyColor.oliveContrast : FlyColor.oliveContrastDark;
        case 'sand': return isLight ? FlyColor.sandContrast : FlyColor.sandContrastDark;
        case 'tomato': return isLight ? FlyColor.tomatoContrast : FlyColor.tomatoContrastDark;
        case 'red': return isLight ? FlyColor.redContrast : FlyColor.redContrastDark;
        case 'ruby': return isLight ? FlyColor.rubyContrast : FlyColor.rubyContrastDark;
        case 'crimson': return isLight ? FlyColor.crimsonContrast : FlyColor.crimsonContrastDark;
        case 'pink': return isLight ? FlyColor.pinkContrast : FlyColor.pinkContrastDark;
        case 'plum': return isLight ? FlyColor.plumContrast : FlyColor.plumContrastDark;
        case 'purple': return isLight ? FlyColor.purpleContrast : FlyColor.purpleContrastDark;
        case 'violet': return isLight ? FlyColor.violetContrast : FlyColor.violetContrastDark;
        case 'iris': return isLight ? FlyColor.irisContrast : FlyColor.irisContrastDark;
        case 'indigo': return isLight ? FlyColor.indigoContrast : FlyColor.indigoContrastDark;
        case 'blue': return isLight ? FlyColor.blueContrast : FlyColor.blueContrastDark;
        case 'cyan': return isLight ? FlyColor.cyanContrast : FlyColor.cyanContrastDark;
        case 'teal': return isLight ? FlyColor.tealContrast : FlyColor.tealContrastDark;
        case 'jade': return isLight ? FlyColor.jadeContrast : FlyColor.jadeContrastDark;
        case 'green': return isLight ? FlyColor.greenContrast : FlyColor.greenContrastDark;
        case 'grass': return isLight ? FlyColor.grassContrast : FlyColor.grassContrastDark;
        case 'brown': return isLight ? FlyColor.brownContrast : FlyColor.brownContrastDark;
        case 'orange': return isLight ? FlyColor.orangeContrast : FlyColor.orangeContrastDark;
        case 'sky': return isLight ? FlyColor.skyContrast : FlyColor.skyContrastDark;
        case 'mint': return isLight ? FlyColor.mintContrast : FlyColor.mintContrastDark;
        case 'lime': return isLight ? FlyColor.limeContrast : FlyColor.limeContrastDark;
        case 'yellow': return isLight ? FlyColor.yellowContrast : FlyColor.yellowContrastDark;
        case 'amber': return isLight ? FlyColor.amberContrast : FlyColor.amberContrastDark;
        default: throw ArgumentError('Unknown color scale: $name');
      }
    }

    // Helper function to get surface color
    Color getSurfaceColor(String name) {
      switch (name) {
        case 'gray': return isLight ? FlyColor.graySurface : FlyColor.graySurfaceDark;
        case 'mauve': return isLight ? FlyColor.mauveSurface : FlyColor.mauveSurfaceDark;
        case 'slate': return isLight ? FlyColor.slateSurface : FlyColor.slateSurfaceDark;
        case 'sage': return isLight ? FlyColor.sageSurface : FlyColor.sageSurfaceDark;
        case 'olive': return isLight ? FlyColor.oliveSurface : FlyColor.oliveSurfaceDark;
        case 'sand': return isLight ? FlyColor.sandSurface : FlyColor.sandSurfaceDark;
        case 'tomato': return isLight ? FlyColor.tomatoSurface : FlyColor.tomatoSurfaceDark;
        case 'red': return isLight ? FlyColor.redSurface : FlyColor.redSurfaceDark;
        case 'ruby': return isLight ? FlyColor.rubySurface : FlyColor.rubySurfaceDark;
        case 'crimson': return isLight ? FlyColor.crimsonSurface : FlyColor.crimsonSurfaceDark;
        case 'pink': return isLight ? FlyColor.pinkSurface : FlyColor.pinkSurfaceDark;
        case 'plum': return isLight ? FlyColor.plumSurface : FlyColor.plumSurfaceDark;
        case 'purple': return isLight ? FlyColor.purpleSurface : FlyColor.purpleSurfaceDark;
        case 'violet': return isLight ? FlyColor.violetSurface : FlyColor.violetSurfaceDark;
        case 'iris': return isLight ? FlyColor.irisSurface : FlyColor.irisSurfaceDark;
        case 'indigo': return isLight ? FlyColor.indigoSurface : FlyColor.indigoSurfaceDark;
        case 'blue': return isLight ? FlyColor.blueSurface : FlyColor.blueSurfaceDark;
        case 'cyan': return isLight ? FlyColor.cyanSurface : FlyColor.cyanSurfaceDark;
        case 'teal': return isLight ? FlyColor.tealSurface : FlyColor.tealSurfaceDark;
        case 'jade': return isLight ? FlyColor.jadeSurface : FlyColor.jadeSurfaceDark;
        case 'green': return isLight ? FlyColor.greenSurface : FlyColor.greenSurfaceDark;
        case 'grass': return isLight ? FlyColor.grassSurface : FlyColor.grassSurfaceDark;
        case 'brown': return isLight ? FlyColor.brownSurface : FlyColor.brownSurfaceDark;
        case 'orange': return isLight ? FlyColor.orangeSurface : FlyColor.orangeSurfaceDark;
        case 'sky': return isLight ? FlyColor.skySurface : FlyColor.skySurfaceDark;
        case 'mint': return isLight ? FlyColor.mintSurface : FlyColor.mintSurfaceDark;
        case 'lime': return isLight ? FlyColor.limeSurface : FlyColor.limeSurfaceDark;
        case 'yellow': return isLight ? FlyColor.yellowSurface : FlyColor.yellowSurfaceDark;
        case 'amber': return isLight ? FlyColor.amberSurface : FlyColor.amberSurfaceDark;
        default: throw ArgumentError('Unknown color scale: $name');
      }
    }

    // Define all color families
    final colorFamilies = [
      'gray',
      'mauve',
      'slate',
      'sage',
      'olive',
      'sand',
      'tomato',
      'red',
      'ruby',
      'crimson',
      'pink',
      'plum',
      'purple',
      'violet',
      'iris',
      'indigo',
      'blue',
      'cyan',
      'teal',
      'jade',
      'green',
      'grass',
      'brown',
      'orange',
      'sky',
      'mint',
      'lime',
      'yellow',
      'amber',
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category labels row
          Row(
            children: [
                SizedBox(
                  width: 80,
                  child: const Text(
                    '',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      // Backgrounds (steps 1-2)
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Text(
                            'Backgrounds',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                      // Interactive components (steps 3-5)
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: Text(
                            'Interactive components',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                      // Borders and separators (steps 6-8)
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: Text(
                            'Borders and separators',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                      // Solid colors (steps 9-10)
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Text(
                            'Solid colors',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                      // Accessible text (steps 11-12)
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Text(
                            'Accessible text',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                      // Contrast and Surface
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Text(
                            'Contrast & Surface',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Step numbers row
            Row(
              children: [
                SizedBox(
                  width: 80,
                  child: const Text(
                    '',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      // Step numbers 1-12
                      ...List.generate(12, (index) {
                        return Expanded(
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                        );
                      }),
                      // Contrast column
                      Expanded(
                        child: Center(
                          child: Text(
                            'C',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                      // Surface column
                      Expanded(
                        child: Center(
                          child: Text(
                            'S',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Color family rows
            ...colorFamilies.map((family) {
              final name = family;
              final contrastColor = getContrastColor(name);
              final surfaceColor = getSurfaceColor(name);
              return Padding(
                padding: const EdgeInsets.only(bottom: 2.0),
                child: Row(
                  children: [
                    // Color name
                    SizedBox(
                      width: 80,
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    ),
                    // Color swatches (12 steps + contrast + surface)
                    Expanded(
                      child: Row(
                        children: [
                          // 12 step colors
                          ...List.generate(12, (index) {
                            final step = index + 1;
                            final color = _showAlpha ? getAlphaColor(name, step) : getColor(name, step);
                            final checkerboardColor1 = isLight ? const Color(0xFFE0E0E0) : const Color(0xFF404040);
                            final checkerboardColor2 = isLight ? const Color(0xFFF5F5F5) : const Color(0xFF505050);
                            return Expanded(
                              child: RepaintBoundary(
                                child: GestureDetector(
                                  onTap: () => _showColorInfoDialog(
                                    context,
                                    color,
                                    name,
                                    step,
                                    _showAlpha,
                                  ),
                                  child: _showAlpha
                                      ? Container(
                                          height: 50,
                                          child: CustomPaint(
                                            painter: _CheckerboardPainter(
                                              color1: checkerboardColor1,
                                              color2: checkerboardColor2,
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () => _showColorInfoDialog(
                                                  context,
                                                  color,
                                                  name,
                                                  step,
                                                  _showAlpha,
                                                ),
                                                child: Container(color: color),
                                              ),
                                            ),
                                          ),
                                        )
                                      : Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () => _showColorInfoDialog(
                                              context,
                                              color,
                                              name,
                                              step,
                                              _showAlpha,
                                            ),
                                            child: Container(height: 50, color: color),
                                          ),
                                        ),
                                ),
                              ),
                            );
                          }),
                          // Contrast color
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showColorInfoDialog(
                                context,
                                contrastColor,
                                '$name Contrast',
                                null,
                                false,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _showColorInfoDialog(
                                    context,
                                    contrastColor,
                                    '$name Contrast',
                                    null,
                                    false,
                                  ),
                                  child: Container(height: 50, color: contrastColor),
                                ),
                              ),
                            ),
                          ),
                          // Surface color
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showColorInfoDialog(
                                context,
                                surfaceColor,
                                '$name Surface',
                                null,
                                false,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _showColorInfoDialog(
                                    context,
                                    surfaceColor,
                                    '$name Surface',
                                    null,
                                    false,
                                  ),
                                  child: Container(height: 50, color: surfaceColor),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
    );
  }

}

/// Custom painter for checkerboard pattern background
class _CheckerboardPainter extends CustomPainter {
  static const _squareSize = 10.0;
  final Color color1;
  final Color color2;

  _CheckerboardPainter({
    Color? color1,
    Color? color2,
  })  : color1 = color1 ?? const Color(0xFFE0E0E0),
        color2 = color2 ?? const Color(0xFFF5F5F5);

  @override
  void paint(Canvas canvas, Size size) {
    // Optimize: Pre-calculate paints and use integer math
    final paint1 = Paint()..color = color1;
    final paint2 = Paint()..color = color2;

    // Calculate number of squares needed
    final rows = (size.height / _squareSize).ceil();
    final cols = (size.width / _squareSize).ceil();

    // Draw alternating pattern more efficiently
    for (int row = 0; row < rows; row++) {
      final y = row * _squareSize;
      final isEvenRow = row % 2 == 0;
      
      for (int col = 0; col < cols; col++) {
        final x = col * _squareSize;
        final isEvenCol = col % 2 == 0;
        final shouldUseColor1 = (isEvenRow && isEvenCol) || (!isEvenRow && !isEvenCol);
        
        canvas.drawRect(
          Rect.fromLTWH(x, y, _squareSize, _squareSize),
          shouldUseColor1 ? paint1 : paint2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is _CheckerboardPainter) {
      return oldDelegate.color1 != color1 || oldDelegate.color2 != color2;
    }
    return false;
  }
}
