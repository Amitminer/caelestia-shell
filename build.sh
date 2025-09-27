#!/usr/bin/env bash
set -e

echo "🔧 Configuring project with CMake (Ninja, Release mode)..."
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/cmake

echo "⚡ Building project..."
cmake --build build

echo "📦 Installing project..."
sudo cmake --install build

echo "✅ Build and installation completed successfully!"
