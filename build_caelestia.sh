#!/usr/bin/env bash
# build_caelestia.sh
# Simple script to build and install Caelestia using CMake + Ninja

set -e  # Exit immediately on error

# Go to the quickshell config directory
cd "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/caelestia" || {
    echo "❌ Directory not found: ${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/caelestia"
    exit 1
}

# Configure the project
echo "🔧 Configuring build..."
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/

# Build the project
echo "⚙️ Building..."
cmake --build build

# Install the project
echo "📦 Installing (requires sudo)..."
sudo cmake --install build

echo "✅ Build and installation complete!"
