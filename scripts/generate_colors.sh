#!/bin/bash

# Script to generate color constants using FlyColorGenerator
# This script must be run with Flutter context (not plain dart run)

echo "🎨 Generating color constants..."
echo ""

# Run the script via flutter test (which has Flutter SDK access)
flutter test test/generator.dart

echo ""
echo "✅ Done! Color constants have been generated."

