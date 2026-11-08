#!/system/bin/sh
# Release the UVC gadget so the USB HAL resumes normal function switching.
CONFIGFS=/config/usb_gadget/g1
echo "" > "$CONFIGFS/UDC" 2>/dev/null
rm -f "$CONFIGFS/configs/b.1/f1"
rm -rf "$CONFIGFS/functions/uvc.0"
echo "uvc gadget released; usb hal will rediscover"
