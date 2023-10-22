#!/usr/bin/env bash

#. /path/to/sync-utils.sh || {
#    echo Failed to load sync-utils.sh >&2
#    exit 1
#}
. "$(dirname -- "$0")"/sync-utils.sh || {
    echo Failed to load sync-utils.sh >&2
    exit 1
}

URL=https://github.com/rust-lang/crates.io-index.git
#DST=/path/to/sync/dir/
DST="$(dirname -- "$0")"/crates.io-index.git
mkdir -p "$DST" 
cd "$DST" || {
    echo Failed to cd "$DST" >&2
    exit 1
}

repo_init() {
    run-sync-job git clone --mirror "$URL" "$DST"
}

update_git() {
    # The following two job is interruptible. For example, killed by tunasync when
    # `tunasync stop job-name` is run by user manually.
    run-sync-job timeout 3600 git remote -v update
    ret=$?
    [ $ret != 0 ] && echo "git sync failed, status code $ret." >&2
    # Assume that we want to run this cleanup even if sync failed.
    ## If someone want to stop sync, just don't do the long-time cleanup!
    for s in $pendding_signals $handled_signals; do
        ## Check whether it is killed.
        ## Notice that if we didn't use `timeout` command, we could check the
        ## value of status code, which should be "128 + signal number" when
        ## the process was killed by the signal. There are also some programs
        ## returning different code: for example, rsync returns 20 after
        ## killed by INT/TERM.
        if [ $s = SIGTERM -o $s = SIGINT ]; then
            echo "killed. don't do git repack." >&2
            return $ret
        fi
    done
    echo "git repack" >&2
    run-sync-job git repack -a -b -d || echo "git repack failed!" >&2
    return $ret
}
# Here is a more simple version if we do cleanup only after rync is successful:
#update_git() {
#    run-sync-job timeout 3600 git remote -v update &&
#    run-sync-job git repack -a -b -d
#}

if [ ! -f "$DST/HEAD" ]; then
    repo_init
    exit $?
fi

update_git
