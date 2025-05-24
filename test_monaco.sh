#!/bin/bash

# Monaco Editor Integration Test Script
# This script helps test the Monaco Editor integration

echo "🚀 Monaco Editor Integration Test"
echo "================================"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}Error: pubspec.yaml not found. Please run this script from the project root.${NC}"
    exit 1
fi

echo -e "${BLUE}1. Cleaning previous builds...${NC}"
flutter clean

echo -e "${BLUE}2. Getting dependencies...${NC}"
flutter pub get

echo -e "${BLUE}3. Checking for issues...${NC}"
flutter analyze

if [ $? -ne 0 ]; then
    echo -e "${RED}There are analysis issues. Please fix them before running.${NC}"
    exit 1
fi

echo -e "${BLUE}4. Running the app...${NC}"
echo -e "${GREEN}The app will launch with Monaco Editor integrated.${NC}"
echo -e "${GREEN}Try dragging and dropping some code files to see syntax highlighting!${NC}"

# Run the app
flutter run -d macos

echo -e "${GREEN}✅ Test complete!${NC}"