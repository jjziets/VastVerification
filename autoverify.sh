#!/bin/bash

# Specify the remote server IP address
REMOTE_SERVER_IP="94.155.194.99" # Change to your remote server IP address
REMOTE_PORT="40146"
while true; do
    # Connect to the remote server and get the status
    STATUS=$(nc $REMOTE_SERVER_IP $REMOTE_PORT)

    # Check the status
    if [[ $STATUS == *"DONE"* ]]; then
        echo "ALL GOOD"
        exit 0
    elif [[ $STATUS == *"ERROR"* ]]; then
        echo "TEST FAILED"
        exit 1
    elif [[ $STATUS == *"STARTED"* ]]; then
        echo "Test is still running..."
    else
        echo "Unknown status: $STATUS retry"
        #exit 1
    fi

    # Sleep for a while before checking again
    sleep 5
done
