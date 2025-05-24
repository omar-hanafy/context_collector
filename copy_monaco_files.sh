#!/bin/bash

# Create directories if they don't exist
mkdir -p assets/monaco/vs/editor

# Copy essential files from the original location
echo "Copying Monaco files from simple-monaco-editor to assets/monaco/vs..."

# Copy loader.js
cp -f simple-monaco-editor/monaco-editor/min/vs/loader.js assets/monaco/vs/loader.js
echo "Copied loader.js"

# Create editor directory
mkdir -p assets/monaco/vs/editor

# Copy editor files
cp -f simple-monaco-editor/monaco-editor/min/vs/editor/editor.main.js assets/monaco/vs/editor/editor.main.js
cp -f simple-monaco-editor/monaco-editor/min/vs/editor/editor.main.css assets/monaco/vs/editor/editor.main.css
echo "Copied editor.main.js and editor.main.css"

# Verify the files exist
if [ -f assets/monaco/vs/loader.js ]; then
  echo "✅ loader.js exists"
else
  echo "❌ loader.js is missing"
fi

if [ -f assets/monaco/vs/editor/editor.main.js ]; then
  echo "✅ editor.main.js exists"
else
  echo "❌ editor.main.js is missing"
fi

if [ -f assets/monaco/vs/editor/editor.main.css ]; then
  echo "✅ editor.main.css exists"
else
  echo "❌ editor.main.css is missing"
fi

echo "Done copying Monaco files" 