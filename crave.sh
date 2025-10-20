#!/bin/bash

# ================================
# Clean old manifests
# ================================
rm -rf .repo/local_manifests/

# ================================
# Initialize Lunaris-AOSP repo
# ================================
echo ">>> Initializing RisingOS repository"
repo init -u https://github.com/Lunaris-AOSP/android -b 16 --git-lfs

# ================================
# Clone device/vendor/kernel trees
# ================================
echo ">>> Cloning Device Trees"
git clone https://github.com/droidcore/device_xiaomi_peridot.git -b lineage-23.0 device/xiaomi/peridot

# ================================
# Sync remaining sources
# ================================
echo ">>> Syncing repo"
/opt/crave/resync.sh

# ================================
# Setup build environment
# ================================
. b*/env*
export BUILD_USERNAME=BLU
export BUILD_HOSTNAME=crave
export TZ=Asia/Jakarta

# ================================
# Start build
# ================================
echo ">>> Starting RisingOS Build"
lunch lineage_peridot-bp2a-user
m lunaris
