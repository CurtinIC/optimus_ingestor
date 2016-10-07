#!/bin/bash

# path to the nextflow executable
NXF_BIN=/usr/bin/nextflow

# path to the folder that has the extract nextflow scripts and configuration
EXTRACT_HOME=/opt/curtin/edX/extract

# path to the folder in which runtime files such as log files, timeline files, etc, should be stored
EXTRACT_WORK="$EXTRACT_HOME/work"

# variables exported for nextflow to use
export NXF_HOME="$EXTRACT_WORK/.nextflow"
export NXF_PID_FILE="$EXTRACT_WORK/extract.nf.pid"
export NXF_WORK="$EXTRACT_WORK/nextflow.work"

# set the value for PID to the PID as stored in the nextflow PID file, so long as it still seems to be running
function get_pid {
    PID=""
    if [ -f "$NXF_PID_FILE" ]; then
        PID=$(cat "$NXF_PID_FILE")
        if ! ps -p "$PID" > /dev/null; then
            rm "$NXF_PID_FILE"
            PID=""
        fi
    fi
}

# start the service, so long as it doesn't already appear to be running
function start {
    get_pid
    if [ -z "$PID" ]; then
        echo  "Starting service..."
        "$NXF_BIN" -bg -C "$EXTRACT_HOME/extract.config" run "$EXTRACT_HOME/extract.nf" > extract.nf.out
    else
        echo "Service is already running, PID=$PID."
    fi
}

# stop the service, if it appears to be running
function stop {
    get_pid
    if [ -z "$PID" ]; then
        echo "Service is not running."
    elif ! kill -0 "$PID" > /dev/null; then
        echo "Unable to stop service."
        exit 1
    else
        echo "Stopping service..."
        kill "$PID"
        while ps -p "$PID" > /dev/null; do
            sleep 1
        done
        rm "$NXF_PID_FILE"
    fi
}

# run the nextflow extract-setup script
function setup {
    echo "Setting up service..."
    $NXF_BIN -C "$EXTRACT_HOME/extract.config" run "$EXTRACT_HOME/extract-setup.nf" > extract-config.nf.out
}

# report on the status of the service
function status {
    get_pid
    if [ -z  "$PID" ]; then
        echo "Service is not running."
    else
        echo "Service is running, PID=$PID."
    fi
}

# main script block
case "$1" in
    start|stop|setup|status)
        if mkdir -p "$EXTRACT_WORK" && cd "$EXTRACT_WORK"; then
            if touch -a -c "$NXF_PID_FILE" > /dev/null; then
                "$1"
            else
                echo "Unable to access PID file $NXF_PID_FILE."
                exit 1
            fi
        else
            echo "Unable to change working directory to $EXTRACT_WORK."
            exit 1
        fi ;;
    *)
        echo "Usage: $0 {start|stop|setup|status}"
        exit 1
esac