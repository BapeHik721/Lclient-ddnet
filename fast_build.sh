#!/bin/bash

# Fast Build Script for Rushie Client (Debian/Arch)
# Optimized for speed using Ninja and disabling heavy features

set -e

# Function to install dependencies
install_deps() {
    if [ -f /etc/arch-release ]; then
        echo "Detected Arch Linux. Installing dependencies..."
        sudo pacman -S --needed --noconfirm base-devel cmake ninja glu glew sdl2 libpng freetype2 libnotify sqlite ffmpeg opus opusfile wavpack libx264 unzip curl vulkan-headers libwebsockets mold
    elif [ -f /etc/debian_version ] || [ -f /etc/lsb-release ]; then
        echo "Detected Debian/Ubuntu. Installing dependencies..."
        sudo apt-get update
        sudo apt-get install -y build-essential cmake ninja-build libglib2.0-dev libfreetype6-dev libnotify-dev libsdl2-dev libsqlite3-dev libavcodec-dev libavformat-dev libavutil-dev libswresample-dev libswscale-dev libx264-dev libpng-dev libglew-dev libwavpack-dev libopus-dev libopusfile-dev unzip curl libvulkan-dev libwebsockets-dev mold
    else
        echo "Unknown OS. Please install dependencies manually (cmake, ninja, sdl2, etc.)"
    fi
}

 # Function to download Discord SDK if missing
 download_discord_sdk() {
     if [ ! -f "ddnet-libs/discord/linux/lib64/discord_game_sdk.so" ]; then
         echo "Discord SDK not found. Downloading from GitHub mirror..."
         mkdir -p ddnet-libs/discord/linux/lib64
         mkdir -p ddnet-libs/discord/include
         
         # Downloading directly from DDNet-libs GitHub to avoid DNS issues with discordapp.net
         # Correct path for DDNet CMake: ddnet-libs/discord/linux/lib64/
         curl -L -o ddnet-libs/discord/linux/lib64/discord_game_sdk.so https://raw.githubusercontent.com/ddnet/ddnet-libs/master/discord/linux/lib64/discord_game_sdk.so
         curl -L -o ddnet-libs/discord/include/discord_game_sdk.h https://raw.githubusercontent.com/ddnet/ddnet-libs/master/discord/include/discord_game_sdk.h
         
         echo "Discord SDK downloaded successfully."
     fi
 }

# Ask to install dependencies
read -p "Install/Update dependencies? (y/N): " install_choice
if [[ "$install_choice" =~ ^[Yy]$ ]]; then
    install_deps
fi

# Ensure Discord SDK is present
download_discord_sdk

# Build process
mkdir -p build_fast
cd build_fast

echo "Configuring Ultra Fast Build (No LTO, using mold)..."
# Using mold linker and disabling LTO for near-instant linking
cmake -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_CXX_FLAGS="-O3 -march=native" \
      -DCMAKE_C_FLAGS="-O3 -march=native" \
      -DCMAKE_EXE_LINKER_FLAGS="-fuse-ld=mold" \
      -DDISCORD=ON \
      -DDISCORD_DYNAMIC=ON \
      -DWEBSOCKETS=OFF \
      -DPREFER_BUNDLED_LIBS=ON \
      -DSERVER=OFF \
      -DTOOLS=OFF \
      ..

echo "Starting build..."
ninja DDNet

echo "----------------------------------------"
echo "Build finished! Executable is in build_fast/DDNet"
echo "To run: ./build_fast/DDNet"
