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
  set -e
  # ================================
  # Clean old manifests
  # ================================
  rm -rf .repo/local_manifests

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
  source build/envsetup.sh
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

  # ================================
  # Upload build ZIP
  # ================================
  echo '>>> Uploading final build ZIP to GoFile'
  cd out/target/product/peridot || exit 1
  BUILD_ZIP=\$(ls *.zip 2>/dev/null | tail -n 1)
  if [ -n \"\$BUILD_ZIP\" ]; then
    curl -sLo upload.sh https://raw.githubusercontent.com/Sushrut1101/GoFile-Upload/refs/heads/master/upload.sh
    chmod +x upload.sh
    ./upload.sh \"\$BUILD_ZIP\" | tee upload_link.txt
    echo '>>> Upload complete. Link saved to upload_link.txt'
  else
    echo 'No build ZIP found to upload.'
  fi
"
