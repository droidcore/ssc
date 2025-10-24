#!/bin/bash
set -e

# ================================
# Project Configuration
# ================================
export PROJECTFOLDER="LOS"
export PROJECTID="93"
export REPO_INIT="repo init -u https://github.com/accupara/los22.git -b lineage-22.1 --git-lfs --depth=1"
export BUILD_DIFFERENT_ROM="repo init -u https://github.com/Lunaris-AOSP/android -b 16 --git-lfs" # Change this if you'd like to build something else

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
  rm -rf device/Xiaomi/peridot
  rm -rf out/target/product/peridot
  # ================================
  # Initialize Lunaris-AOSP repo
  # ================================
  echo '>>> Initializing Lunaris-AOSP repo'
  $BUILD_DIFFERENT_ROM

  # ================================
  # Clone local manifests
  # ================================
  echo '>>> Cloning local manifests'
  git clone https://github.com/droidcore/local_manifest.git --depth 1 -b lineages-23.0 .repo/local_manifests

  # ================================
  # Sync sources
  # ================================
  echo '>>> Syncing sources'
  /opt/crave/resync.sh

  # ================================
  # Setup build environment
  # ================================
  . b*/env*
  export BUILD_USERNAME=BLU
  export BUILD_HOSTNAME=crave
  export TZ=Asia/Jakarta

  # ================================
  # Build
  # ================================
  echo '>>> Starting build'
  lunch lineage_peridot-bp2a-user
  make installclean
  m lunaris
"
