#!/bin/bash
# pixel2rom Directive 6: strip carrier/telephony bloat from the blob lists,
# re-run extract-files (CLEAN_VENDOR), and re-embed the camera/photos apps.
set -e
MUSKIE=~/android/device/google/muskie
V=~/android/vendor/google/walleye
PAT='vzw|verizon|uscc|sprint|videotron|obdm|ConnMO|DCMO|DiagMon|DMAgent|DMService|CarrierMetrics|CarrierServices|CarrierSettings|CarrierWifi|CarrierConfig|MyVerizon|VZWAPN|Hotword|datastatusnotification|uceShim|QtiTelephonyService|ModemService|wahoo_gfxdrv|TimeService|data_status|/ims/|qti-vzw-ims|HotwordEnrollment'

echo "=BEFORE="; wc -l "$MUSKIE/lineage-proprietary-files.txt" "$MUSKIE/lineage-proprietary-files-vendor.txt"
for f in "$MUSKIE/lineage-proprietary-files.txt" "$MUSKIE/lineage-proprietary-files-vendor.txt"; do
  grep -ivE "$PAT" "$f" > "$f.stripped" || true
  if [ -s "$f.stripped" ]; then mv "$f.stripped" "$f"; else rm -f "$f.stripped"; fi
done
echo "=AFTER="; wc -l "$MUSKIE/lineage-proprietary-files.txt" "$MUSKIE/lineage-proprietary-files-vendor.txt"

cd ~/android/device/google/muskie
./extract-files.sh ~/factory/extracted-src 2>&1 | tail -3

echo "=RE-EMBED="
mkdir -p "$V/proprietary/product/priv-app/GCS" "$V/proprietary/product/app/GoogleCamera" "$V/proprietary/product/app/Photos"
cp ~/factory/extracted/GCS.apk "$V/proprietary/product/priv-app/GCS/GCS.apk"
cp ~/factory/extracted/GoogleCamera.apk "$V/proprietary/product/app/GoogleCamera/GoogleCamera.apk"
cp ~/factory/extracted/GoogleCamera.apk.prof "$V/proprietary/product/app/GoogleCamera/GoogleCamera.apk.prof" 2>/dev/null || cp ~/factory/sys-tree/product/app/GoogleCamera/GoogleCamera.apk.prof "$V/proprietary/product/app/GoogleCamera/GoogleCamera.apk.prof"
cp ~/factory/extracted/Photos.apk "$V/proprietary/product/app/Photos/Photos.apk"
echo "gcam hash verify:"; sha256sum "$V/proprietary/product/app/GoogleCamera/GoogleCamera.apk" | cut -c1-16
echo "=VENDOR-SIZE="; du -sh "$V"
grep -q walleye-gcam.mk ~/android/device/google/muskie/walleye/lineage_walleye.mk && echo "gcam hook intact"
REMOTE