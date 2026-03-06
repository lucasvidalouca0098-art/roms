EXTRACT_KERNEL_IMAGE() {
    if [ -d "$TMP_DIR" ]; then
        EVAL "rm -rf \"$TMP_DIR\""
    fi
    EVAL "mkdir -p \"$TMP_DIR\""
    EVAL "cp -a \"$WORK_DIR/kernel/boot.img\" \"$TMP_DIR/boot.img\""

    EVAL "unpack_bootimg --boot_img \"$TMP_DIR/boot.img\" --out \"$TMP_DIR/out\" 2>&1"

    EVAL "rm \"$TMP_DIR/boot.img\""

}

EXTRACT_KERNEL_MODULES() {
    if [ -d "$TMP_DIR" ]; then
        EVAL "rm -rf \"$TMP_DIR\""
    fi
    EVAL "mkdir -p \"$TMP_DIR\""
    EVAL "cp -a \"$WORK_DIR/kernel/vendor_boot.img\" \"$TMP_DIR/vendor_boot.img\""

    EVAL "unpack_bootimg --boot_img \"$TMP_DIR/vendor_boot.img\" --out \"$TMP_DIR/out\" 2>&1"

    EVAL "rm \"$TMP_DIR/vendor_boot.img\""

    while IFS= read -r f; do
        if [[ "$(READ_BYTES_AT "$f" "0" "4")" == "184c2102" ]]; then
            EVAL "cat \"$f\" | lz4 -d > \"$TMP_DIR/out/tmp\" && mv -f \"$TMP_DIR/out/tmp\" \"$f\""
        elif [[ "$(READ_BYTES_AT "$f" "0" "2")" == "8b1f" ]]; then
            EVAL "cat \"$f\" | gzip -d > \"$TMP_DIR/out/tmp\" && mv -f \"$TMP_DIR/out/tmp\" \"$f\""
        fi
    done < <(find "$TMP_DIR/out" -maxdepth 1 -type f -name "vendor_ramdisk*")
}

# Ensure Knox Matrix support
# - Check if target firmware runs on One UI 5.1.1 or above
TARGET_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$TARGET_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$TARGET_FIRMWARE")"
if [ "$(GET_PROP "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/build.prop" "ro.build.version.oneui")" -lt "50101" ]; then
    PATCHED=true
    DELETE_FROM_WORK_DIR "system" "system/bin/fabric_crypto"
    DELETE_FROM_WORK_DIR "system" "system/etc/init/fabric_crypto.rc"
    DELETE_FROM_WORK_DIR "system" "system/etc/permissions/FabricCryptoLib.xml"
    DELETE_FROM_WORK_DIR "system" "system/etc/permissions/privapp-permissions-com.samsung.android.kmxservice.xml"
    DELETE_FROM_WORK_DIR "system" "system/etc/vintf/manifest/fabric_crypto_manifest.xml"
    DELETE_FROM_WORK_DIR "system" "system/framework/FabricCryptoLib.jar"
    DELETE_FROM_WORK_DIR "system" "system/lib64/com.samsung.security.fabric.cryptod-V1-cpp.so"
    DELETE_FROM_WORK_DIR "system" "system/lib64/vendor.samsung.hardware.security.fkeymaster-V1-cpp.so"
    DELETE_FROM_WORK_DIR "system" "system/lib64/vendor.samsung.hardware.security.fkeymaster-V1-ndk.so"
    DELETE_FROM_WORK_DIR "system" "system/priv-app/KmxService"
fi

# Ensure KSMBD support in kernel
# - 4.19.x and below: unsupported
# - 5.4.x-5.10.x: backport (https://github.com/namjaejeon/ksmbd.git)
# - 5.15.x and above: supported
if [ -f "$WORK_DIR/system/system/priv-app/StorageShare/StorageShare.apk" ]; then
    EXTRACT_KERNEL_IMAGE
    if ! grep -q "ksmbd" "$TMP_DIR/out/kernel"; then
        PATCHED=true
        DELETE_FROM_WORK_DIR "system" "system/bin/ksmbd.addshare"
        DELETE_FROM_WORK_DIR "system" "system/bin/ksmbd.adduser"
        DELETE_FROM_WORK_DIR "system" "system/bin/ksmbd.control"
        DELETE_FROM_WORK_DIR "system" "system/bin/ksmbd.mountd"
        DELETE_FROM_WORK_DIR "system" "system/bin/ksmbd.tools"
        DELETE_FROM_WORK_DIR "system" "system/etc/default-permissions/default-permissions-com.samsung.android.hwresourceshare.storage.xml"
        DELETE_FROM_WORK_DIR "system" "system/etc/init/ksmbd.rc"
        DELETE_FROM_WORK_DIR "system" "system/etc/permissions/privapp-permissions-com.samsung.android.hwresourceshare.storage.xml"
        DELETE_FROM_WORK_DIR "system" "system/etc/sysconfig/preinstalled-packages-com.samsung.android.hwresourceshare.storage.xml"
        DELETE_FROM_WORK_DIR "system" "system/etc/ksmbd.conf"
        DELETE_FROM_WORK_DIR "system" "system/priv-app/StorageShare"
    fi
fi

# Ensure sbauth support in target firmware
TARGET_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$TARGET_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$TARGET_FIRMWARE")"
if [ -f "$WORK_DIR/system/system/bin/sbauth" ] && \
        [ ! -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/bin/sbauth" ]; then
    PATCHED=true
    DELETE_FROM_WORK_DIR "system" "system/bin/sbauth"
    DELETE_FROM_WORK_DIR "system" "system/etc/init/sbauth.rc"
fi

unset PATCHED TARGET_FIRMWARE_PATH
unset -f BACKPORT_SF_PROPS EXTRACT_KERNEL_IMAGE EXTRACT_KERNEL_MODULES
