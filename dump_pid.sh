#!/bin/zsh -f
#
# $Header$

setopt NO_UNSET
setopt ERR_EXIT

SCRIPTNAME=`basename "$0"`
DEBUG=
QUIET=
DO_NOTHING=

PID=

Usage () {
    echo >&2 "Usage: $SCRIPTNAME [options]"
    echo >&2 ""
    echo >&2 "  Options:"
    echo >&2 "    --pid (-p)         - pid to use"
    echo >&2 "    --help             - show the usage"
    echo >&2 "    --do-nothing (-n)  - log what would be done, but don't actually do it"
    echo >&2 "    --quiet (-q)       - work silently"
    exit 1
}

while [ $# -gt 0 ]
do
    case "$1" in
    --)
        shift
        break;;
    --help|-h)
        Usage;;
    --debug|-d)
        set -x
        DEBUG=$1;;
    --quiet|-q)
        QUIET=$1;;
    --do-nothing|-n)
        DO_NOTHING=$1;;
    --pid|-p)
        PID=$2
        shift;;
    -*)
        Usage;;
    *)
        Usage;;
    esac
    shift
done

# set variables
TMP_FOLDER="/tmp/"
HEAP_FILENAME=$PID.heap
HEAP_PATH=$TMP_FOLDER$HEAP_FILENAME
VMMAP_FILENAME=$PID.vmmap
VMMAP_PATH=$TMP_FOLDER$VMMAP_FILENAME
LOG_FILENAME=$PID.log
LOG_PATH=$TMP_FOLDER$LOG_FILENAME
SAMPLE_FILENAME=$PID.sample
SAMPLE_PATH=$TMP_FOLDER$SAMPLE_FILENAME
TAR_FILENAME=$PID.dump.tar.gz
TAR_PATH=$TAR_FOLDER$TAR_FILENAME


# check PID
if [ "$PID" = "" ]; then
    echo "PID (-p) required, please use '$SCRIPTNAME --help' for options"
fi

# Check elevated access
# If the user's id is zero,
if [[ "${EUID}" -eq 0 ]]; then
    # they are root and all is good
    if [ "$QUIET" = "" ]; then
        echo " Sudo Check passed"
    fi
# Otherwise,
else
    # They do not have enough privileges, so let the user know
    echo -e "Please run as sudo"
    exit 1
fi

# Heap
if [ "$QUIET" = "" ]; then
    echo " dumping heap"
fi

sudo heap -addresses all -noContent -guessNonObjects $PID > $HEAP_PATH

# VMMAP
if [ "$QUIET" = "" ]; then
    echo " dumping vmmap"
fi

sudo vmmap $PID > $VMMAP_PATH

# LOG
if [ "$QUIET" = "" ]; then
    echo " dumping log"
fi

sudo log show --predicate "processID = $PID" --info --last 1h > $LOG_PATH

# SAMPLE
if [ "$QUIET" = "" ]; then
    echo " taking sample"
fi

sudo sample 13274 10 -file $SAMPLE_FILENAME

# Archive
if [ "$QUIET" = "" ]; then
    echo " archiving and cleaning up"
fi

sudo tar -czvf $TAR_PATH -C $TMP_FOLDER $HEAP_FILENAME $VMMAP_FILENAME $LOG_FILENAME $SAMPLE_FILENAME

# Make sure anyone can do anything with it
sudo chmod 0777 $TAR_PATH

# Clean up individual files
sudo rm $HEAP_PATH
sudo rm $VMMAP_PATH
sudo rm $LOG_PATH
sudo rm $SAMPLE_PATH
