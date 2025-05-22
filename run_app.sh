#!/bin/bash

# Context Collector - Flutter Desktop App Runner

echo "Context Collector - Drag & Drop File Collection App"
echo "=================================================="

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "Error: Flutter is not installed or not in PATH"
    echo "Please install Flutter from https://flutter.dev"
    exit 1
fi

echo "Flutter version:"
flutter --version

echo ""
echo "Installing dependencies..."
flutter pub get

echo ""
echo "Available platforms:"
flutter devices

echo ""
echo "To run the app:"
echo "  For macOS:   flutter run -d macos"
echo "  For Windows: flutter run -d windows"
echo "  For Linux:   flutter run -d linux"

echo ""
echo "To build the app:"
echo "  For macOS:   flutter build macos --release"
echo "  For Windows: flutter build windows --release"
echo "  For Linux:   flutter build linux --release"

echo ""
echo "Running the app on the default desktop platform..."
flutter run -d desktop
