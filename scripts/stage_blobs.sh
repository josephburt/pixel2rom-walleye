#!/bin/bash
set -u
STAGE="$HOME/factory/extracted-src"
VROOT="$HOME/factory/sys-tree/vendor-root"
SROOT="$HOME/factory/sys-tree/system-root"
PROD="$HOME/factory/sys-tree/product"
 DBGFS=/sbin/debugfs
IMGDIR="$HOME/factory/walleye-rp1a.201005.004.a1"

# vendor tree (rdump once) -- vendor.raw's root IS the vendor tree itself
if [ ! -d "$VROOT/bin" ]; then
  mkdir -p "$VROOT"
  $DBGFS -R "rdump / $VROOT" "$IMGDIR/vendor.raw" 2>&1 | tail -1
fi

# system_other raw for last-ditch candidates
[ -f "$IMGDIR/system_other.raw" ] || python3 "$HOME/tools/simg2img.py" "$IMGDIR/system_other.img" "$IMGDIR/system_other.raw"

mkdir -p "$STAGE"
FOUND=0; MISS=0; : > /tmp/staging-missing.txt
stage_one() {
  local tok="$1"
  tok="${tok#-}"
  tok="${tok%%|*}"; tok="${tok%%;*}"
  tok="${tok# }"; tok="$(printf '%s' "$tok" | sed 's/[[:space:]]*$//')"
  case "$tok" in ""|\[*) return;; esac
  case "$tok" in \#*) return;; esac
  local src=""
  local vstrip="${tok#vendor/}"
  for cand in "$VROOT/$vstrip" "$VROOT/$tok" "$SROOT/$tok" "$SROOT/system/$tok" "$PROD/$tok" "$SROOT/product/$tok"; do
    if [ -f "$cand" ]; then src="$cand"; break; fi
  done
  if [ -z "$src" ] && [ -f "$IMGDIR/system_other.raw" ]; then
    for p in "$tok" "system/$tok" "product/$tok"; do
      rm -f "$STAGE/$tok"
      mkdir -p "$STAGE/$(dirname "$tok")" 2>/dev/null
      $DBGFS -R "dump /$p $STAGE/$tok" "$IMGDIR/system_other.raw" > /dev/null 2>&1
      if [ -s "$STAGE/$tok" ]; then src="debugfs:$p"; break; fi
    done
  fi
  if [ -z "$src" ]; then
    # last resort: live device (fused layout) via adb
    for ap in "/vendor/$vstrip" "/$tok" "/system/$tok" "/product/$tok"; do
      rm -f "$STAGE/$tok"
      mkdir -p "$STAGE/$(dirname "$tok")" 2>/dev/null
      adb -s FA79G1A06233 pull "$ap" "$STAGE/$tok" > /dev/null 2>&1
      if [ -s "$STAGE/$tok" ]; then src="adb:$ap"; break; fi
    done
  fi
  if [ -z "$src" ]; then echo "$tok" >> /tmp/staging-missing.txt; MISS=$((MISS+1)); return; fi
  mkdir -p "$STAGE/$(dirname "$tok")" 2>/dev/null
  if [ "${src#adb:}" = "$src" ]; then cp "$src" "$STAGE/$tok"; fi
  FOUND=$((FOUND+1))
}
for f in /tmp/pf-main.txt /tmp/pf-vendor.txt; do
  while IFS= read -r line; do stage_one "$line"; done < "$f"
done
echo "staged=$FOUND missing=$MISS"
echo "--- missing list (max 25):"
tail -25 /tmp/staging-missing.txt
echo "--- sync:"; du -sh "$HOME/android/.repo" 2>/dev/null
