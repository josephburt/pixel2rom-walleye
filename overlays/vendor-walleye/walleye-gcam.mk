# Stock Google Camera + GCS + Photos (pixel2rom appliance additions)
# Sources: extracted from walleye RP1A.201005.004.A1 factory image (sha-anchored)
PRODUCT_COPY_FILES += \
    vendor/google/walleye/proprietary/product/app/GoogleCamera/GoogleCamera.apk:$(TARGET_COPY_OUT_PRODUCT)/app/GoogleCamera/GoogleCamera.apk \
    vendor/google/walleye/proprietary/product/app/GoogleCamera/GoogleCamera.apk.prof:$(TARGET_COPY_OUT_PRODUCT)/app/GoogleCamera/GoogleCamera.apk.prof \
    vendor/google/walleye/proprietary/product/priv-app/GCS/GCS.apk:$(TARGET_COPY_OUT_PRODUCT)/priv-app/GCS/GCS.apk \
    vendor/google/walleye/proprietary/product/app/Photos/Photos.apk:$(TARGET_COPY_OUT_PRODUCT)/app/Photos/Photos.apk
