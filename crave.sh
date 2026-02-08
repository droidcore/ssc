#!/bin/bash
set -e

# ================================
# Project Configuration
# ================================
export PROJECTFOLDER="aosp"
export PROJECTID="35"
export REPO_INIT="repo init -u https://android.googlesource.com/platform/manifest"
export BUILD_DIFFERENT_ROM="repo init --no-repo-verify --git-lfs -u https://github.com/ProjectInfinity-X/manifest -b 16 -g default,-mips,-darwin,-notdefault" # Change this if you'd like to build something else

# ================================
# Destroy Old Clones
# ================================
echo ">>> Cleaning old clone"
if (grep -q "$PROJECTFOLDER" <(crave clone list --json | jq -r '.clones[]."Cloned At"')) || [ "${DCDEVSPACE}" == "1" ]; then
  crave clone destroy -y /crave-devspaces/$PROJECTFOLDER || echo "Error removing $PROJECTFOLDER"
else
  rm -rf $PROJECTFOLDER || true
fi

# ================================
# Create New Clone
# ================================
echo ">>> Creating new clone"
if [ "${DCDEVSPACE}" == "1" ]; then
  crave clone create --projectID $PROJECTID /crave-devspaces/$PROJECTFOLDER || echo "Crave clone create failed!"
  cd /crave-devspaces/$PROJECTFOLDER
else
  mkdir $PROJECTFOLDER && cd $PROJECTFOLDER
  echo "Running $REPO_INIT"
  $REPO_INIT
fi

# ================================
# Run inside Crave devspace
# ================================
crave run --no-patch -- "
  # ================================
  # Clean old manifests
  # ================================
  rm -rf .repo/local_manifests
  rm -rf device/xiaomi/peridot
  rm -rf out/target/product/peridot
  
  # ================================
  # Initialize InfinityX repo
  # ================================
  echo '>>> Initializing InfinityX repo'
  $BUILD_DIFFERENT_ROM

  # ================================
  # Clone local manifests
  # ================================
  echo '>>> Cloning local manifests'
  git clone https://github.com/ryznstk/manifest_peridot.git -b lineage-23.0 .repo/local_manifests/

  # ================================
  # Sync sources
  # ================================
  echo '>>> Syncing sources'
  /opt/crave/resync.sh

  # ================================
  # Setup build environment
  # ================================
  . build/envsetup.sh

  # ================================
  # Build
  # ================================
  echo '>>> Starting build'
  lunch infinity_peridot-user
  make installclean
  m bacon 
"
