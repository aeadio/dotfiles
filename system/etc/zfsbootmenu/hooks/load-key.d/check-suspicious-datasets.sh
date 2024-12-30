#!/bin/bash

## Suppose you have an encrypted root on ZFS setup. Typically, the zpool root 
## is encrypted, and all child datasets inherit its encryptionroot.
## 
## ZFS allows for unencrypted datasets, or datasets with other encryptionroots, 
## to be children of encrypted datasets. Imagine an "evil maid" gets access to 
## your laptop while it is powered off. They may boot up a Linux live CD with 
## ZFS support, and insert a new child dataset onto the zroot, which mounts 
## over a key directory such as /bin or /etc, containing their own maliciously 
## modified binaries or system configuration.
## 
## This hook will attempt to detect such intrusions, and provide a warning to 
## the user on bootup, before ZBM collects the password to unlock the rootfs.
## Note that in order to be effective, this script should be baked into the 
## ZFS Boot Menu image, which should be further verified by SecureBoot with, 
## custom-enrolled keys unique to the machine, to ensure an unbroken chain of 
## trust from EFI -> ZBM -> the unencrypted rootfs. Otherwise, an attacker can 
## simply replace the copy of ZBM with one which doesn't perform this check,
## or otherwise tampers with the loaded operating system in other ways.
## 
## To use, install as a `load-key.d` hook in ZBM's configured hook directory
## (typically, `/etc/zfsbootmenu/load-key.d`) and ensure it is executable.
##  
## See: https://docs.zfsbootmenu.org/en/latest/man/zfsbootmenu.7.html#user-hooks

# Configure with directories which you wish to protect
# You may consider the defaults overbroad, or too narrow
DENIED_LOCATIONS=(
  "/bin"
  "/dev"
  "/etc"
  "/lib"
  "/lib32"
  "/lib64"
  "/proc"
  "/run"
  "/sbin"
  "/sys"
  "/usr"
  "/var"
)

[[ -z "$ZBM_ENCRYPTION_ROOT" ]] && exit

suspicious_datasets=()

while IFS=$'\t' read -r name encryption encryptionroot canmount mountpoint; do
  # We only care about datasets that ZBM is about to mount on our behalf.
  case "$canmount" in
    off)    continue ;;
    noauto) continue ;;
  esac
  # NOTE: Initially I believed it was sufficient to block unencrypted datasets. 
  # However, consider the scenario where I place a new encrypted dataset on the 
  # pool with a separate encryptionroot, using a known throwaway key that is 
  # accessible to the zbm image, such as any old file in the initrd. That would 
  # bypass the check for suspicious _unencrypted_ datasets.
  if [[ "$encryption" != "off" && "$encryptionroot" == "$ZBM_ENCRYPTION_ROOT" ]]; then
    # We assume anything under the primary encryptionroot is under the control 
    # of the machine operator, and sufficiently protected by ZFS's AEAD 
    # encryption.
    continue
  fi
  
  # We have a child dataset which is either unencrypted, or is encrypted with a 
  # different encryptionroot than the rootfs. Determine if it will overlay a 
  # sensitive directory.
  for prefix in "${DENIED_LOCATIONS[@]}"; do
    if [[ "$mountpoint" == "$prefix" || "$mountpoint" == "$prefix"/* ]]; then
      suspicious_datasets+=( "$name" )
      break
    fi
  done
  
# NOTE: Check children of ZBM_ENCRYPTION_ROOT, not ZBM_LOCKED_FS. It's not
# children of the rootfs we are concerned about (of which there may be none in 
# a typical boot-environment style setup with zroot/ROOT/...), but rather all 
# children of the encryptionroot which will be implicitly unlocked and mounted 
# with the provided key.
done < <(zfs list -r -H -o name,encryption,encryptionroot,canmount,mountpoint "$ZBM_ENCRYPTION_ROOT")

if [[ ${#suspicious_datasets[@]} -gt 0 ]]; then
  printf '%s\n' "WARNING! Suspicious child datasets found!"
  printf '%s\n' ''
  for name in "${suspicious_datasets[@]}"; do
    if [[ "$(zfs get -H -o value encryption "$name")" == "off" ]]; then
      printf '%s\n'   "$name (unencrypted)"
      printf '\t%s\n' "mountpoint: $(zfs get -H -o value mountpoint "$name")"
    else
      printf '%s\n'   "$name (alternate encryptionroot)"
      printf '\t%s\n' "mountpoint: $(zfs get -H -o value mountpoint "$name")"
      printf '\t%s\n' "keylocation: $(zfs get -H -o value keylocation "$name")"
    fi
    printf '%s\n' ''
  done
  
  while true; do
    read -r -p "Do you want to continue booting? [y/N]: " confirm
    case "$confirm" in
      [Yy])
        exit 0
        ;;
      [Nn]|'')
        if source /lib/zfsbootmenu-core.sh >/dev/null 2>&1; then
          emergency_shell "suspicious datasets found"
        else
          reboot
        fi
        ;;
    esac
  done
fi
