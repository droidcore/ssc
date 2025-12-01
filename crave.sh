#!/bin/bash

  # ================================
  # Clean old manifests
  # ================================
  rm -rf .repo/local_manifests
  rm -rf device/xiaomi/peridot
  rm -rf out/target/product/peridot
  
  # ================================
  # Clone local manifests
  # ================================
  echo '>>> Cloning local manifests'
  git clone https://github.com/droidcore/manifest_peridot.git -b lineage-23.0 .repo/local_manifests/

  # ================================
  # Sync sources
  # ================================
  echo '>>> Syncing sources'
  /opt/crave/resync.sh

  # ================================
  # Setup build environment
  # ================================
  . build/envsetup.sh
  export BUILD_USERNAME=BLU
  export BUILD_HOSTNAME=crave
  export TZ=Asia/Jakarta

  # ================================
  # Build
  # ================================
  echo '>>> Starting build'
  lunch lineage_peridot-bp3a-user
  make installclean
  m evolution 
"
