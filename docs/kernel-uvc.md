# Kernel: UVC gadget enablement (wahoo / msm-4.4)

`drivers/usb/gadget/function/f_uvc.c` is present in the stock wahoo kernel
tree; only the configuration was missing. Applied to
`arch/arm64/configs/wahoo_defconfig` (appended after line 793):

```text
# UVC gadget - device-as-webcam appliance (pixel2rom project)
CONFIG_USB_CONFIGFS_F_UVC=y
CONFIG_VIDEO_DEV=y
```

Dependency check (upstream `drivers/usb/gadget/Kconfig`):

```text
config USB_CONFIGFS_F_UVC
    bool "USB Webcam function"
    depends on USB_CONFIGFS        # already =y in wahoo_defconfig
    depends on VIDEO_DEV           # absent before this patch
    select VIDEOBUF2_VMALLOC       # auto-selected
    select USB_F_UVC               # auto-selected
```

`CONFIG_MEDIA_SUPPORT=y` was already present in the defconfig.

## Userspace side

`overlays/appliance/vendor/bin/uvc-gadget-init.sh` binds the function through
configfs (`/config/usb_gadget/g1`), claims the UDC, and exposes the gadget
video node. `uvc-gadget-off.sh` releases the UDC back to the USB HAL.
Toggle with `setprop pixel2rom.uvc.enable 1|0` (handled by `appliance.rc`).

## Phase B (pending)

The camera→gadget frame feed: a small Camera2 capture service feeding the
gadget UVC video node (via JNI/v4l2 writer) so the host receives real
frames. Until then the device enumerates as a valid UVC webcam without
video.
