#! /usr/bin/env bash

# Debugging script for Linux.
#
# This script must be run on the host.
#
# Collect various logs that may impact Terrateam.  This script may need to be
# modified depending on the specifics of the host system.


timestamp="$(date "+%Y%m%d-%H%M%S")"

if [ "$(whoami)" != "root" ]; then
  echo "run as root"
  exit 1
fi

echo "Collecting debug information for Terrateam..."

# Define output directory
DEBUG_DIR="/tmp/terrateam_debug_$timestamp"
mkdir -p "$DEBUG_DIR"

# Check for segfaults
echo "Checking for segfaults..."
dmesg | grep -i segfault > "$DEBUG_DIR/dmesg_segfaults.log" 2>&1

# Check open file descriptors
if pgrep terrat > /dev/null; then
    echo "Inspecting file descriptors for all terrat processes..."
    for PID in $(pgrep terrat); do
        echo "Processing PID: $PID"
        lsof -p "$PID" > "$DEBUG_DIR/lsof_terrat_$PID.log" 2>&1
        ls -l /proc/"$PID"/fd > "$DEBUG_DIR/proc_fd_list_$PID.log" 2>&1
    done
else
    echo "terrat process not running. Skipping file descriptor check."
fi

# Check AppArmor denials
echo "Checking AppArmor denials..."
aa-status > "$DEBUG_DIR/apparmor_status.log" 2>&1
journalctl -xe | grep DENIED > "$DEBUG_DIR/apparmor_denials.log" 2>&1 || true

# Check resource limits
echo "Checking resource limits..."
ulimit -a > "$DEBUG_DIR/ulimit.log" 2>&1

# Capture last logs from Terrateam
echo "Fetching recent logs..."
journalctl --no-pager > "$DEBUG_DIR/terrateam_logs.log" 2>&1

# Check running processes
echo "Checking running processes..."
ps aux --sort=-%mem | head -20 > "$DEBUG_DIR/top_memory_processes.log" 2>&1
ps aux --sort=-%cpu | head -20 > "$DEBUG_DIR/top_cpu_processes.log" 2>&1

# Run strace on all terrat processes
if pgrep terrat > /dev/null; then
    echo "Running strace on all terrat processes..."
    for PID in $(pgrep terrat); do
        echo "Tracing PID: $PID"
        strace -p "$PID" -o "$DEBUG_DIR/strace_terrat_$PID.log" -s 500 -f -tt -T &
    done
    echo "Strace is running in the background. Check logs in $DEBUG_DIR after execution."
else
    echo "terrat process not running. Skipping strace."
fi

echo "Debug information collected in: $DEBUG_DIR"
echo
echo "*****************************************************************"
echo "DO NOT RESTART TERRATEAM UNTIL YOU HAVE REPRODUCED THE ISSUE AGAIN AFTER RUNNING THIS SCRIPT"
echo
echo "WHEN THE ISSUE HAS BEEN REPRODUCED DO THE FOLLOWING:"
echo
echo "1. Restart terrateam"
echo "2. Execute tar -zcvf /tmp/terrateam_debug_$timestamp.tar.gz -C /tmp $(basename "$DEBUG_DIR")"
echo "3. Upload /tmp/terrateam_debug_$timestamp.tar.gz to the Terrateam Slack"
echo
echo "*****************************************************************"
