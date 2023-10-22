#!/usr/bin/env bash

#. /path/to/sync-utils.sh || {
#    echo Failed to load sync-utils.sh >&2
#    exit 1
#}
. "$(dirname -- "$0")"/sync-utils.sh || {
    echo Failed to load sync-utils.sh >&2
    exit 1
}

URL=rsync://example.com/example
DST=/path/to/sync/dir
TEMP_DIR=/path/to/temp/dir

# The following one job is interruptible. For example, killed by tunasync when
# `tunasync stop job-name` is run by user manually.
run-sync-job rsync --temp-dir="$TEMP_DIR" some-other-args "$SRC" "$DST"

# using the exit status to tell caller whether the job success is IMPORTANT!
ret=$?

# If rsync failed, it might leave some temporary files.
if [ $ret != 0 ]; then
    # with signals blocked, it should not run for too long.
    rm -rf "$TEMP_DIR"
    # If we are unsure that whether time needed by the cleanup is short enough,
    # we can use the following one instead:
    #timeout 1 rm -rf "$TEMP_DIR"
fi

# return the status of sync
exit $ret
