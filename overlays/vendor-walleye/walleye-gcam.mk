# camera appliance additions — stock camera + gallery + GCS, regen-proof overlay
# Sources: walleye RP1A.201005.004.A1 factory image (sha256-anchored), see README.
# APKs install via android_app_import modules (proprietary/product/Android.bp).
PRODUCT_COPY_FILES += \
    vendor/google/walleye/proprietary/product/app/GoogleCamera/GoogleCamera.apk.prof:$(TARGET_COPY_OUT_PRODUCT)/app/GoogleCameraStock/GoogleCameraStock.apk.prof

PRODUCT_PACKAGES += GoogleCameraStock GcsStock PhotosStock
