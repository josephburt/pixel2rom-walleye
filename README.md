# Pixel 2 (walleye) Camera + UVC Webcam Appliance ROM

Turn a Google Pixel 2 into a dedicated point-and-shoot camera and plug-and-play
UVC webcam, powered by a locally-built LineageOS 18.1 ROM.

The appliance boots straight into the stock Google Camera viewfinder, keeps a
persistent side-docked pill menu for Camera / Gallery / UVC mode, ships with
cellular radios soft-disabled (strict Airplane Mode with Wi-Fi functional), and
runs a baked-in Syncthing daemon that pushes the DCIM folder to a homelab
server over Wi-Fi.

## Repository layout

```
scripts/               Tooling used during setup and extraction
  simg2img.py            Android sparse-image -> raw-ext4 decoder (no deps)
  stage_blobs.sh         Builds extract-utils' SRC tree from factory images
  strip_carrier_bloat.sh Curates the muskie proprietary-files lists
overlays/
  device/                Device-tree makefile additions (muskie/walleye)
  vendor-walleye/        walleye-gcam.mk + walleye-appliance.mk
  appliance/             init rc, boot policy + UVC configfs scripts
  launcher/              PixelCamLauncher Android app (tree packages/apps)
docs/
  build-instructions.md  Full build + flash walkthrough
  kernel-uvc.md          Kernel defconfig UVC patch + status
```

## How the blob set is produced

1. Download the last walleye factory image
   (`walleye-rp1a.201005.004.a1-factory-0c23f6cf.zip`,
   sha256 `0c23f6cf9e2194a3e72b1288f65c5a7f2f6c020080af49c8a494ee99ab3eb543`).
2. Sparse-convert `system`/`vendor`/`system_other` img, then stage the exact
   paths listed in LineageOS' `device/google/muskie/lineage-proprietary-files*`
   from the unpacked image roots (`scripts/stage_blobs.sh` resolves each path
   against the product/system/vendor trees and, as a last resort, the live
   device over adb).
3. Run `extract-files.sh` **from the muskie dir** (running it through the
   `device/google/walleye` symlink breaks `BASH_SOURCE` path resolution).
4. Strip carrier/telephony bloat from the lists and re-extract
   (`scripts/strip_carrier_bloat.sh`) — the appliance has no SIM purpose.
5. Embed the stock Google Camera (`product/app/GoogleCamera`, 81 MB,
   sha256 `23962c40…` on the RP1A build we used), the GCS services APK
   and Photos via `overlays/vendor-walleye/walleye-gcam.mk` — a separate,
   regeneration-proof makefile that re-runs of `extract-files` cannot wipe.

## ROM modifications

| Area | Change |
| --- | --- |
| Kernel | `CONFIG_USB_CONFIGFS_F_UVC=y` + `CONFIG_VIDEO_DEV=y` appended to `arch/arm64/configs/wahoo_defconfig` (f_uvc.c exists in the msm-4.4 wahoo tree). |
| Camera | Stock GCam + GCS + Photos embedded as product apps (`walleye-gcam.mk`). |
| Appliance | `walleye-appliance.mk` installs Syncthing (static arm64 binary), the boot-policy script (airplane-on, stay-awake-while-plugged, lockscreen disabled, Wi-Fi up) and the UVC configfs gadget bind/release scripts. |
| Launcher | PixelCamLauncher: platform-signed privileged HOME app; boots to the camera via `com.google.android.GoogleCamera/com.android.camera.CameraLauncher`; side-docked overlay pill (`SYSTEM_ALERT_WINDOW` priv-app permission). |
| Init | `appliance.rc`: boot policy service at `sys.boot_completed`, Syncthing `late_start` service, UVC gadget start/stop on `pixel2rom.uvc.enable` property. |

## Build

```sh
cd ~/android
export JAVA_HOME=~/tools/jdk11-temurin
export USE_CCACHE=1 CCACHE_EXEC=$(command -v ccache)
source build/envsetup.sh
lunch lineage_walleye-userdebug
mka -j6 bacon        # ~4-8 h on 12 cores w/ ccache 40GB
```

Requires a full JDK 11 (Debian 13 does not ship one; Temurin 11 tarball works),
`repo`, `zip`, `ccache`, `git-lfs` and the standard AOSP host packages.

## Flash

```sh
adb reboot bootloader
fastboot flashing unlock          # WIPES the device (authorized per-project)
# after unlock + reboot to bootloader:
fastboot flash boot   out/target/product/walleye/boot.img
fastboot -w flash system out/target/product/walleye/system.img
fastboot flash vbmeta out/target/product/walleye/vbmeta.img \
  --disable-verity --disable-verification
fastboot flash dtbo   out/target/product/walleye/dtbo.img
fastboot -w flashall  # or per-partition flow from the LineageOS docs
```

Bootloader must be unlocked first: enable *Developer options → OEM unlocking*
(it needs one successful internet check-in to persist), then
`fastboot flashing unlock` from bootloader mode.

## Known limits (honest ledger)

- **UVC Phase A**: the gadget function binds and enumerates as a webcam, but
  the camera→gadget frame feed (Camera2 capture → JNI → `/dev/video` writer)
  is the Phase B development item; toggling UVC shows no picture yet.
- Appliance init services run under the `su` domain on `userdebug` builds —
  a personal appliance trade-off; a hardened deployment would give each
  service its own SELinux domain.
- Syncthing ships unconfigured; point it at your homelab either via the web
  GUI (`http://192.168.4.105:8384` from the device's LAN IP) or by pushing a
  config to `/data/vendor/syncthing/`.
- Bootloader unlock + flashing wipes the device. Verified: walleye
  RP1A.201005.004.A1 build anchors (factory + GCam sha256 above).

## Provenance / verification

- REA (Reverse Engineering Anything) verified the extracted APK identity and
  the presence of HDR+/Visual Core stack blobs in the vendor image
  (`libhdrplusclient.so`, `libgcs-calwrapper.so`, `libgcs-ipc.so`,
  `adsp_camera/libhalide_hexagon_remote_skel.so`, chromatix XMLs).
- All artifact hashes are recorded in `docs/build-instructions.md`.

License: Apache-2.0 (see LICENSE).
