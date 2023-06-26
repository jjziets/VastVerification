#!/bin/bash

# Port to listen on
PORT=5000
echo "RUNNING" > progress.log

# Start a detached netcat process listening on the specified port and responding with the content of progress.log
# Restart netcat if it ever exits
while true; do
    nc -lp $PORT -c 'cat progress.log'
done &

# Store the PID of the background job
bg_pid=$!

# Set a trap to kill the background job when this script exits
#trap "kill $bg_pid" EXIT

# First Test
python3 systemreqtest.py
exit_status=$?

if [ $exit_status -eq 0 ]
then
    echo "TESTED : System requirements test passed." > progress.log
else
    echo "ERROR 1: system requirements test failed."  > progress.log
    exit 1
fi

# Second Test
python3 testAllGpusResNet50.py
exit_status=$?

if [ $exit_status -eq 0 ]
then
    echo "DONE" > progress.log
else
    echo "ERROR 2: Test All GPU ResNet50 failed."  > progress.log
    exit 2
fi
