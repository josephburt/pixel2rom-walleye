#!/system/bin/sh
# Bind the f_uvc gadget function (configfs). Takes the single UDC; adb drops while active.
CONFIGFS=/config/usb_gadget/g1
F=$CONFIGFS/functions/uvc.0
mkdir -p "$F" 2>/dev/null || { echo "mkdir uvc.0 failed"; exit 1; }
mkdir -p "$F/streams/0/fullscreen/1920x1080@30" 2>/dev/null
mkdir -p "$CONFIGFS/configs/b.1" 2>/dev/null
ln -s "$F" "$CONFIGFS/configs/b.1/f1" 2>/dev/null
UDC=$(ls /sys/class/udc | head -1)
[ -n "$UDC" ] && echo "$UDC" > "$CONFIGFS/UDC"
echo "uvc gadget bound to $UDC"
