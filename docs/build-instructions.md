# Build instructions (walleye appliance, lineage-18.1)

This walkthrough was executed on Debian GNU/Linux 13 (trixie), 12 cores,
11 GiB RAM + 11 GiB swap, 456 GB disk. Adjust RAM/disk to taste; builds are
bandwidth- and CPU-bound, not RAM-bound (ccache + swap carry it).

## 0. Host packages

```sh
sudo apt-get update
sudo apt-get install -y zip ccache git-lfs libxml2-utils xsltproc bc flex bison \
  gperf build-essential g++-multilib gcc-multilib libc6-dev-i386 zlib1g-dev \
  libncurses-dev libssl-dev lz4 lzop pngcrush schedtool squashfs-tools \
  imagemagick libgl1-mesa-dev lib32z1-dev lib32stdc++6 \
  lib32readline-dev lib32ncurses-dev libsqlite3-dev libffi-dev
```

Notes (Debian 13 specifics):
- `liblz4-tool` and `lib32sqlite3-dev` DO NOT EXIST on trixie (renamed
  `lz4` / dropped). One bad name aborts the whole `apt` transaction — split
  the lists or double-check names.

## 1. JDK 11 (AOSP 11 requirement; the system JDK 21 is NOT used by the build)

```sh
mkdir -p ~/tools && cd ~/tools
curl -fsSL "https://api.adoptium.net/v3/binary/latest/11/ga/linux/x64/jdk/hotspot/normal/eclipse" -o jdk11.tgz
mkdir -p jdk11-temurin && tar -xzf jdk11.tgz -C jdk11-temurin --strip-components=1 && rm jdk11.tgz
```

## 2. repo launcher

```sh
mkdir -p ~/bin && curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo -o ~/bin/repo && chmod +x ~/bin/repo
git config --global user.name  "envy-builder"
git config --global user.email "envy@localhost"
```

## 3. Tree init + local manifest

LineageOS pruned walleye from the `lineage-18.1` snippet manifest; declare it
back in `.repo/local_manifests/walleye.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
  <remote name="los-walleye" fetch="https://github.com/LineageOS" />
  <project path="device/google/walleye" name="android_device_google_walleye" remote="los-walleye" revision="lineage-18.1" />
  <project path="device/google/muskie"   name="android_device_google_muskie"   remote="los-walleye" revision="lineage-18.1" />
  <project path="device/google/wahoo"    name="android_device_google_wahoo"    remote="los-walleye" revision="lineage-18.1" />
  <project path="kernel/google/wahoo"    name="android_kernel_google_wahoo"    remote="los-walleye" revision="lineage-18.1" />
</manifest>
```

```sh
mkdir -p ~/android && cd ~/android
repo init -u https://github.com/LineageOS/android.git -b lineage-18.1 --git-lfs
repo sync -c -j6          # ~150-200 GB, hours
repo sync -c device/google/muskie   # if added after the big sync started
```

## 4. Factory image (blob source) — hash-anchored

| File | sha256 |
| --- | --- |
| walleye-rp1a.201005.004.a1-factory-0c23f6cf.zip | `0c23f6cf9e2194a3e72b1288f65c5a7f2f6c020080af49c8a494ee99ab3eb543` |
| GoogleCamera.apk (extracted, 81,156,397 B) | `23962c409b7a22588f6c68fc34102bc2e9bbab6f3e004f3e5369d1e6a6f16578` |
| Photos.apk (75,247,133 B) | `291f2f0d013fd8d8b0ed57ee86379f2ebe9c937d64bb065d1a97a696eb040752` |
| GCS.apk (4,298,231 B) | `cd5183413a9acf3b6d1827d6d1956e5a4bf9d46237570969d37a4d1b79ca4695` |

```sh
mkdir -p ~/factory && cd ~/factory
curl -fSL -o walleye-factory.zip "https://dl.google.com/dl/android/aosp/walleye-rp1a.201005.004.a1-factory-0c23f6cf.zip"
sha256sum walleye-factory.zip     # must match the anchor above
unzip -oq walleye-factory.zip && cd walleye-rp1a.201005.004.a1
unzip -oq image-walleye-rp1a.201005.004.a1.zip
python3 ~/tools/simg2img.py system.img       system.raw
python3 ~/tools/simg2img.py vendor.img       vendor.raw
python3 ~/tools/simg2img.py system_other.img system_other.raw
/sbin/debugfs -R "rdump /system /home/$USER/factory/sys-tree/system-root"  system.raw
/sbin/debugfs -R "rdump /       /home/$USER/factory/sys-tree/vendor-root"  vendor.raw
/sbin/debugfs -R "rdump /system/product /home/$USER/factory/sys-tree/product" system.raw
```

Note: `vendor.raw`'s filesystem root IS the vendor tree — `rdump /`, not
`rdump /vendor`. `rdump` needs the destination dir to pre-exist and chowns as
root, so warnings about ownership from a non-root run are harmless.

## 5. Stage blob sources + extract

```sh
bash ~/tools/stage_blobs.sh      # resolves 974 list paths into ~/factory/extracted-src
cd ~/android/device/google/muskie
./extract-files.sh ~/factory/extracted-src
```

(`stage_blobs.sh` also applies the carrier-bloat strip before extraction —
see `strip_carrier_bloat.sh`; the strip cuts the lists 975 → 830 rows.)

## 6. ROM-side additions (this repo)

- `overlays/vendor-walleye/walleye-gcam.mk` → embeds GCam/GCS/Photos
- `overlays/vendor-walleye/walleye-appliance.mk` → appliance layer (syncthing, boot policy, UVC scripts, launcher)
- both are inherited from `device/google/muskie/walleye/lineage_walleye.mk`
  (two `$(call inherit-product, …)` lines after the stock `walleye-vendor.mk`)
- `overlays/device/README.md` — the exact device-tree edits
- `docs/kernel-uvc.md` — kernel defconfig UVC patch

## 7. Build

```sh
cd ~/android
source build/envsetup.sh
lunch lineage_walleye-userdebug
croot && mka -j6 bacon
```

Build outputs: `out/target/product/walleye/{boot,system,vendor,dtbo,vbmeta}.img`
plus the flashable zip.

## 8. Flash

Bootloader must first be unlocked (Developer options → OEM unlocking needs one
internet check-in to persist; then `adb reboot bootloader`,
`fastboot flashing unlock` — **wipes the device** and needs on-device volume
key confirmation). Then flash from the LineageOS recovery flow or the
per-partition fastboot sequence in the main README.
