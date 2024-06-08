#!/bin/bash

# Port to listen on
PORT=5000
echo "RUNNING" > progress.log

# Start the Python server in the background
python3 remote.py &
bg_pid=$!
bg_pid=$!

# Set a trap to kill the background job when this script exits
trap "kill $bg_pid" EXIT

# First Test
python3 systemreqtest.py
exit_status=$?

if [ $exit_status -eq 0 ]; then
    echo "TESTED : System requirements test passed." > progress.log
else
    echo "ERROR 1: System requirements test failed." > progress.log
    exit 1
fi

# Second Test
python3 testAllGpusResNet50.py
exit_status=$?

if [ $exit_status -eq 0 ]; then
    echo "DONE" > progress.log
else
    echo "ERROR 2: Test All GPU ResNet50 failed." > progress.log
    exit 2
fi

wait 3600
