#!/bin/bash

# repo init rom
repo init -u https://github.com/Lunaris-AOSP/android -b 16 --git-lfs
# sync
/opt/crave/resync.sh || repo sync
# Clone Trees
git clone https://github.com/droidcore/device_xiaomi_peridot.git -b lineage-23.0 device/xiaomi/peridot

git clone https://github.com/AbuRider/priv_keys -b main vendor/lineage-priv/keys
# Export
export BUILD_USERNAME=BLU
export BUILD_HOSTNAME=crave
export TZ=Asia/Jakarta
# initiate build setup
. b*/env*
lunch lineage_peridot-bp2a-user
m lunaris -j$(nproc --all)
