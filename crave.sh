#!/bin/bash

set -e
#Credit to Meghthedev for the initial script 

export PROJECTFOLDER="LOS22.1"
export PROJECTID="93"
export REPO_INIT="repo init -u https://github.com/accupara/los22.git -b lineage-22.1 --git-lfs --depth=1"
export BUILD_DIFFERENT_ROM="repo init -u https://github.com/Lunaris-AOSP/android -b 16 --git-lfs" # Change this if you'd like to build something else

# Destroy Old Clones
if (grep -q "$PROJECTFOLDER" <(crave clone list --json | jq -r '.clones[]."Cloned At"')) || [ "${DCDEVSPACE}" == "1" ]; then   
   crave clone destroy -y /crave-devspaces/$PROJECTFOLDER || echo "Error removing $PROJECTFOLDER"
else
   rm -rf $PROJECTFOLDER || true
fi

# Create New clone
if [ "${DCDEVSPACE}" == "1" ]; then
   crave clone create --projectID $PROJECTID /crave-devspaces/$PROJECTFOLDER || echo "Crave clone create failed!"
   cd /crave-devspaces/$PROJECTFOLDER
else
   mkdir $PROJECTFOLDER
   cd $PROJECTFOLDER
   echo "Running $REPO_INIT"
   $REPO_INIT
fi

# Run inside foss.crave.io devspace
# Remove existing local_manifests
crave run --no-patch -- "rm -rf .repo/local_manifests && \

# Init Manifest
$BUILD_DIFFERENT_ROM && \

# Clone local_manifests repository
git clone https://github.com/droidcore/local_manifest.git --depth 1 -b lineages-23.0 .repo/local_manifests && \

 # Sync the repositories
 /opt/crave/resync.sh && \ 

# Set up build environment
source build/envsetup.sh && \

# Lunch configuration
lunch lineage_peridot-user && \

# Build the ROM
mka bacon"

OUT_DIR="/crave-devspaces/$PROJECTFOLDER/out/target/product/$DEVICE"

ROM_ZIP=$(find "$OUT_DIR" -type f -name "*.zip" | head -n 1)
BOOT_IMG="$OUT_DIR/boot.img"
DTBO_IMG="$OUT_DIR/dtbo.img"
VENDOR_BOOT_IMG="$OUT_DIR/vendor_boot.img"

wget https://raw.githubusercontent.com/GustavoMends/go-up/master/go-up
chmod +x go-up

./go-up "$ROM_ZIP"
./go-up "$BOOT_IMG"
./go-up "$DTBO_IMG"
if [ -f "$VENDOR_BOOT_IMG" ]; then
    ./go-up "$VENDOR_BOOT_IMG"
fi

# Clean up
if grep -q "$PROJECTFOLDER" <(crave clone list --json | jq -r '.clones[]."Cloned At"') || [ "${DCDEVSPACE}" == "1" ]; then
  crave clone destroy -y /crave-devspaces/$PROJECTFOLDER || echo "Error removing $PROJECTFOLDER"
else  
  rm -rf $PROJECTFOLDER || true
fi
