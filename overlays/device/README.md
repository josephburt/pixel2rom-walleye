# Device-tree edits (LineageOS Android device repos)

All upstream LineageOS repos stay unmodified except the files below. Re-runs
of `extract-files.sh` regenerate its own outputs; the additions here live in
separate, regeneration-proof files.

## device/google/muskie/walleye/lineage_walleye.mk

Two lines appended after the stock vendor include:

```make
$(call inherit-product, vendor/google/walleye/walleye-gcam.mk)
$(call inherit-product, vendor/google/walleye/walleye-appliance.mk)
```

## arch/arm64/configs/wahoo_defconfig (kernel/google/wahoo)

Two appended lines — see `docs/kernel-uvc.md`.

## device/google/muskie/lineage-proprietary-files*.txt

Carrier/telephony rows stripped before extraction (appliance has no cellular
use): verizon/vzw/sprint/uscc/videotron/OBDM/ConnMO/DCMO/DiagMon/DMAgent/
DMService/Carrier*/MyVerizon/VZWAPN/HotwordEnrollment/datastatusnotification/
uceShim/QtiTelephonyService/ModemService/wahoo_gfxdrv/TimeService/ims apps +
qti-vzw-ims jars. 975 → 830 rows. The strip is scripted in
`scripts/strip_carrier_bloat.sh` and is re-appliable after any `repo sync`.

## Why separate .mk files?

`extract-files.sh` regenerates `walleye-vendor.mk` (marked
`DO NOT MODIFY`) on every run and `CLEAN_VENDOR=true` wipes
`proprietary/` between runs. The gcam/appliance makefiles and their
payload copies are re-applied after regeneration (see
`scripts/strip_carrier_bloat.sh` tail).
