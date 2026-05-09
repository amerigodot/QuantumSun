#!/bin/bash

# Configuration
APP_NAME="QuantumSun"
EXECUTABLE_NAME="quantum-sun"
OUTPUT_DIR="."
BUNDLE_NAME="${APP_NAME}.app"
BUNDLE_PATH="${OUTPUT_DIR}/${BUNDLE_NAME}"

echo "Building ${APP_NAME}..."
swift build -c release

if [ $? -ne 0 ]; then
    echo "Build failed."
    exit 1
fi

echo "Creating bundle structure..."
# Create directory structure
mkdir -p "${BUNDLE_PATH}/Contents/MacOS"
mkdir -p "${BUNDLE_PATH}/Contents/Resources"

# Copy executable
cp ".build/release/${EXECUTABLE_NAME}" "${BUNDLE_PATH}/Contents/MacOS/"

# Process Icon
if [ -f "AppIcon.png" ]; then
    echo "Creating AppIcon..."
    ICONSET="AppIcon.iconset"
    mkdir -p "$ICONSET"
    
    # Generate various sizes
    sips -z 16 16     AppIcon.png --setProperty format png --out "${ICONSET}/icon_16x16.png" > /dev/null
    sips -z 32 32     AppIcon.png --setProperty format png --out "${ICONSET}/icon_16x16@2x.png" > /dev/null
    sips -z 32 32     AppIcon.png --setProperty format png --out "${ICONSET}/icon_32x32.png" > /dev/null
    sips -z 64 64     AppIcon.png --setProperty format png --out "${ICONSET}/icon_32x32@2x.png" > /dev/null
    sips -z 128 128   AppIcon.png --setProperty format png --out "${ICONSET}/icon_128x128.png" > /dev/null
    sips -z 256 256   AppIcon.png --setProperty format png --out "${ICONSET}/icon_128x128@2x.png" > /dev/null
    sips -z 256 256   AppIcon.png --setProperty format png --out "${ICONSET}/icon_256x256.png" > /dev/null
    sips -z 512 512   AppIcon.png --setProperty format png --out "${ICONSET}/icon_256x256@2x.png" > /dev/null
    sips -z 512 512   AppIcon.png --setProperty format png --out "${ICONSET}/icon_512x512.png" > /dev/null
    sips -z 1024 1024 AppIcon.png --setProperty format png --out "${ICONSET}/icon_512x512@2x.png" > /dev/null
    
    # Convert to icns
    iconutil -c icns "$ICONSET"
    
    if [ $? -eq 0 ]; then
        # Copy to bundle
        cp "AppIcon.icns" "${BUNDLE_PATH}/Contents/Resources/"
        # Cleanup
        rm -rf "$ICONSET" "AppIcon.icns"
    else
        echo "Error: iconutil failed."
    fi
else
    echo "Warning: AppIcon.png not found."
fi

# Copy Info.plist
cp "Info.plist" "${BUNDLE_PATH}/Contents/"

# Set permissions
chmod +x "${BUNDLE_PATH}/Contents/MacOS/${EXECUTABLE_NAME}"

echo "${APP_NAME} packaged successfully at ${BUNDLE_PATH}"
echo "You can move it to /Applications or run it directly."
