#!/system/bin/sh
# pixel2rom appliance boot policy (airplane default, Wi-Fi on, no lock, stay awake plugged)
sleep 45
settings put global airplane_mode_on 1
settings put global stay_on_while_plugged_in 7
settings put secure lockscreen.disabled 1
settings put global wifi_scan_always_enabled 1
svc wifi enable
pm set-home-activity com.pixel2rom.launcher/.MainActivity
