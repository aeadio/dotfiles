#!/bin/bash

## A simple teardown hook to take a clean snapshot of the boot environment
## prior to launching the new kernel. This requires that your pool be read-write
## and will always export it.
##
## To use, put this script somewhere, make sure it is executable, and add the
## path to the `zfsbootmenu_teardown` space-separated list with, e.g.,
##
##     zfsbootmenu_teardown+=" <path to script> "
##
## in a dracut.conf(5) file inside the directory specified for the option
## `Global.DracutConfDir` in the ZFSBootMenu `config.yaml`.

# exit early if we're missing our env var
if [[ -z "$ZBM_SELECTED_BE" ]]; then
  printf '%s\n' "snapshot-teardown: warn: ZBM_SELECTED_BE is empty; cannot snapshot rootfs"
  exit
fi

for src in /lib/zfsbootmenu-core.sh /lib/kmsg-log-lib.sh ; do
  # shellcheck disable=SC1090
  if ! source "${src}"; then
    printf '%s\n' "snapshot-teardown: warn: could not source $src; exiting"
    exit
  fi
done

zpool="${ZBM_SELECTED_BE%%/*}"

if ! zpool list -H -o name "${zpool}" >/dev/null 2>&1 ; then
  read_write=true import_pool "${zpool}"
else
  set_rw_pool "${zpool}"
fi

TZ=UTC printf -v snapshot "${ZBM_SELECTED_BE}@boot_%(%Y-%m-%d_%H:%M:%S)T"
printf '%s\n' "snapshot-teardown: creating snapshot: $snapshot"
zfs snapshot -r "${snapshot}"
export_pool "${zpool}"
