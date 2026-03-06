# [
_LOG() { if $DEBUG; then LOGW "$1"; else ABORT "$1"; fi }

LOG_MISSING_PATCHES()
{
    local MESSAGE="Missing SPF patches for condition ($1: [${!1}], $2: [${!2}])"

    if $DEBUG; then
        LOGW "$MESSAGE"
    else
        ABORT "${MESSAGE}. Aborting"
    fi
}
# ]

SOURCE_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$SOURCE_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$SOURCE_FIRMWARE")"
TARGET_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$TARGET_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$TARGET_FIRMWARE")"

DELETE_FROM_WORK_DIR "system" "system/cameradata/portrait_data"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/cameradata/portrait_data" 0 0 755 "u:object_r:system_file:s0"
if [ -f "$SRC_DIR/target/$TARGET_CODENAME/camera/singletake/service-feature.xml" ]; then
    LOG "- Adding /system/system/cameradata/singletake/service-feature.xml"
    EVAL "cp -a \"$SRC_DIR/target/$TARGET_CODENAME/camera/singletake/service-feature.xml\" \"$WORK_DIR/system/system/cameradata/singletake/service-feature.xml\""
else
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" \
        "system" "system/cameradata/singletake/service-feature.xml" 0 0 644 "u:object_r:system_file:s0"
fi
if [ -f "$SRC_DIR/target/$TARGET_CODENAME/camera/aremoji-feature.xml" ]; then
    LOG "- Adding /system/system/cameradata/aremoji-feature.xml"
    EVAL "cp -a \"$SRC_DIR/target/$TARGET_CODENAME/camera/aremoji-feature.xml\" \"$WORK_DIR/system/system/cameradata/aremoji-feature.xml\""
else
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" \
        "system" "system/cameradata/aremoji-feature.xml" 0 0 644 "u:object_r:system_file:s0"
fi
if [ -f "$SRC_DIR/target/$TARGET_CODENAME/camera/camera-feature.xml" ]; then
    LOG "- Adding /system/system/cameradata/camera-feature.xml"
    EVAL "cp -a \"$SRC_DIR/target/$TARGET_CODENAME/camera/camera-feature.xml\" \"$WORK_DIR/system/system/cameradata/camera-feature.xml\""
elif [[ "$SOURCE_PLATFORM_SDK_VERSION" == "$TARGET_PLATFORM_SDK_VERSION" ]]; then
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" \
        "system" "system/cameradata/camera-feature.xml" 0 0 644 "u:object_r:system_file:s0"
else
    _LOG "File not found: $SRC_DIR/target/$TARGET_CODENAME/camera/camera-feature.xml"
fi

    DELETE_FROM_WORK_DIR "system" "system/lib64/libAEBHDR_wrapper.camera.samsung.so"
    DELETE_FROM_WORK_DIR "system" "system/lib64/libae_bracket_hdr.arcsoft.so"
    DELETE_FROM_WORK_DIR "system" "system/lib64/libDualCamBokehCapture.camera.samsung.so"
    DELETE_FROM_WORK_DIR "system" "system/lib64/libarcsoft_dualcam_portraitlighting.so"
    DELETE_FROM_WORK_DIR "system" "system/lib64/libdualcam_refocus_image.so"
    DELETE_FROM_WORK_DIR "system" "system/lib64/libFaceRecognition.arcsoft.so"
    DELETE_FROM_WORK_DIR "system" "system/lib64/libfrtracking_engine.arcsoft.so"
    DELETE_FROM_WORK_DIR "system" "system/lib64/libhybridHDR_wrapper.camera.samsung.so"
    DELETE_FROM_WORK_DIR "system" "system/lib64/libhybrid_high_dynamic_range.arcsoft.so"
    DELETE_FROM_WORK_DIR "system" "system/lib64/libAIQSolution_MPI.camera.samsung.so"
    DELETE_FROM_WORK_DIR "system" "system/lib64/libLocalTM_pcc.camera.samsung.so"
    DELETE_FROM_WORK_DIR "system" "system/lib64/libMultiFrameProcessing30.camera.samsung.so"
    DELETE_FROM_WORK_DIR "system" "system/lib64/libMultiFrameProcessing30.snapwrapper.camera.samsung.so"
    DELETE_FROM_WORK_DIR "system" "system/lib64/libMultiFrameProcessing30Tuning.camera.samsung.so"
    DELETE_FROM_WORK_DIR "system" "system/lib64/libSwIsp_core.camera.samsung.so"
    DELETE_FROM_WORK_DIR "system" "system/lib64/libSwIsp_wrapper_v1.camera.samsung.so"
    DELETE_FROM_WORK_DIR "system" "system/lib64/libDeepDocRectify.camera.samsung.so"

# Fix object capture
if [[ "$TARGET_OS_SINGLE_SYSTEM_IMAGE" == "essi" ]]; then
    if {
        [[ "$(GET_PROP "system" "ro.product.device")" =~ r0|g0|b0 ]] && \
            ! [[ "$(GET_PROP "vendor" "ro.product.vendor.device")" =~ r0|g0|b0 ]]
    } || {
        [[ "$(GET_PROP "system" "ro.product.device")" == "a56"* ]] && \
            [[ "$(GET_PROP "vendor" "ro.product.vendor.device")" != "a56"* ]]
    }; then
        HEX_PATCH "$WORK_DIR/system/system/lib64/libobjectcapture_jni.arcsoft.so" \
            "e503162a47020094e022009121008052e203162a" "8500805247020094e02200912100805282008052"
    elif ! [[ "$(GET_PROP "system" "ro.product.device")" =~ r0|g0|b0 ]] && \
            [[ "$(GET_PROP "vendor" "ro.product.vendor.device")" =~ r0|g0|b0 ]]; then
        HEX_PATCH "$WORK_DIR/system/system/lib64/libobjectcapture_jni.arcsoft.so" \
            "e503162a47020094e022009121008052e203162a" "4500805247020094e02200912100805242008052"
    elif [[ "$(GET_PROP "system" "ro.product.device")" != "a56"* ]] && \
            [[ "$(GET_PROP "vendor" "ro.product.vendor.device")" == "a56"* ]]; then
        HEX_PATCH "$WORK_DIR/system/system/lib64/libobjectcapture_jni.arcsoft.so" \
            "e503162a47020094e022009121008052e203162a" "c500805247020094e022009121008052c2008052"
    fi
fi

# Fix portrait mode

        SET_PROP "system" "ro.build.flavor" "$(GET_PROP "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/build.prop" "ro.build.flavor")"
        HEX_PATCH "$WORK_DIR/vendor/lib/libDualCamBokehCapture.camera.samsung.so" \
            "726f2e70726f647563742e6e616d6500" "726f2e756e6963612e63616d65726100"
        HEX_PATCH "$WORK_DIR/vendor/lib/liblivefocus_capture_engine.so" \
            "726f2e70726f647563742e6e616d6500" "726f2e756e6963612e63616d65726100"
        HEX_PATCH "$WORK_DIR/vendor/lib/liblivefocus_preview_engine.so" \
            "726f2e70726f647563742e6e616d6500" "726f2e756e6963612e63616d65726100"
        HEX_PATCH "$WORK_DIR/vendor/lib64/libDualCamBokehCapture.camera.samsung.so" \
            "726f2e70726f647563742e6e616d6500" "726f2e756e6963612e63616d65726100"
        HEX_PATCH "$WORK_DIR/vendor/lib64/liblivefocus_capture_engine.so" \
            "726f2e70726f647563742e6e616d6500" "726f2e756e6963612e63616d65726100"
        HEX_PATCH "$WORK_DIR/vendor/lib64/liblivefocus_preview_engine.so" \
            "726f2e70726f647563742e6e616d6500" "726f2e756e6963612e63616d65726100"
        LOG "- Patching /system/system/etc/selinux/plat_property_contexts"
        EVAL "echo \"ro.unica.camera u:object_r:build_prop:s0 exact string\"  >> \"$WORK_DIR/system/system/etc/selinux/plat_property_contexts\""
        SET_PROP "system" "ro.unica.camera" "$(GET_PROP "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/build.prop" "ro.product.system.name")"

# Enable camera cutout protection
# Skip patch if SystemUI RRO exists
if [ ! "$(find "$WORK_DIR/product/overlay" -maxdepth 1 -type f -name "SystemUI*" 2> /dev/null)" ]; then
    if [[ "$SOURCE_CAMERA_SUPPORT_CUTOUT_PROTECTION" != "$TARGET_CAMERA_SUPPORT_CUTOUT_PROTECTION" ]]; then
        DECODE_APK "system_ext" "priv-app/SystemUI/SystemUI.apk"
        if $TARGET_CAMERA_SUPPORT_CUTOUT_PROTECTION; then
            LOG "- Enabling camera cutout protection"
        else
            LOG "- Disabling camera cutout protection"
        fi
        EVAL "sed -i \"s/config_enableDisplayCutoutProtection\\\">$SOURCE_CAMERA_SUPPORT_CUTOUT_PROTECTION/config_enableDisplayCutoutProtection\\\">$TARGET_CAMERA_SUPPORT_CUTOUT_PROTECTION/\" \"$APKTOOL_DIR/system_ext/priv-app/SystemUI/SystemUI.apk/res/values/bools.xml\""
    fi
fi

unset SOURCE_FIRMWARE_PATH TARGET_FIRMWARE_PATH \
    SOURCE_CAMERA_CONFIG_ACTION_CLASSIFIER TARGET_CAMERA_CONFIG_ACTION_CLASSIFIER \
    SOURCE_CAMERA_CONFIG_GPPM_SOLUTIONS TARGET_CAMERA_CONFIG_GPPM_SOLUTIONS \
    SOURCE_GALLERY_CONFIG_PET_CLUSTER_VERSION TARGET_GALLERY_CONFIG_PET_CLUSTER_VERSION \
    SOURCE_SAIV_CONFIG_ARDOODLE_LIB TARGET_SAIV_CONFIG_ARDOODLE_LIB \
    SOURCE_CAMERA_CONFIG_VENDOR_LIB_INFO TARGET_CAMERA_CONFIG_VENDOR_LIB_INFO \
    SOURCE_CAMERA_DOCUMENTSCAN_SOLUTIONS TARGET_CAMERA_DOCUMENTSCAN_SOLUTIONS
unset -f _LOG LOG_MISSING_PATCHES

if $SOURCE_HAS_MASS_CAMERA_APP; then
    if ! $TARGET_HAS_MASS_CAMERA_APP; then
        ADD_TO_WORK_DIR "e2sxxx" "system" "system/priv-app/SamsungCamera/SamsungCamera.apk" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "e2sxxx" "system" "system/priv-app/SamsungCamera/oat"
    else
        LOG "- TARGET_HAS_MASS_CAMERA_APP is set. Ignoring."
    fi
else
    LOG "- SOURCE_HAS_MASS_CAMERA_APP is not set. Ignoring."
fi

