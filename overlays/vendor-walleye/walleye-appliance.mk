# pixel2rom appliance layer: syncthing daemon, boot policy, UVC gadget scripts, launcher
PRODUCT_COPY_FILES += \
    vendor/google/walleye/proprietary/bin/syncthing:$(TARGET_COPY_OUT_SYSTEM)/bin/syncthing \
    vendor/google/walleye/proprietary/bin/appliance-boot.sh:$(TARGET_COPY_OUT_VENDOR)/bin/appliance-boot.sh \
    vendor/google/walleye/proprietary/bin/uvc-gadget-init.sh:$(TARGET_COPY_OUT_VENDOR)/bin/uvc-gadget-init.sh \
    vendor/google/walleye/proprietary/bin/uvc-gadget-off.sh:$(TARGET_COPY_OUT_VENDOR)/bin/uvc-gadget-off.sh \
    vendor/google/walleye/proprietary/etc/init/appliance.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/appliance.rc \
    vendor/google/walleye/proprietary/product/etc/permissions/privapp-permissions-pixel2rom.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/permissions/privapp-permissions-pixel2rom.xml \
    vendor/google/walleye/proprietary/product/etc/permissions/privapp-permissions-pixel2rom.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/permissions/privapp-permissions-pixel2rom.xml

PRODUCT_PACKAGES += PixelCamLauncher
