#!/bin/bash

# Check if two arguments were provided
if [ "$#" -ne 2 ]; then
    echo "Usage: ./local.sh <IP> <Port>"
    exit 1
fi

# Get the IP and port from command line arguments
IP=$1
PORT=$2

while true; do
    # Send an 'EOT' message and receive response
    message=$(echo "EOT" | nc $IP $PORT)
    echo $message > remoteprogress.log
    # If the message is 'DONE' or starts with 'ERROR', exit the loop
    if [[ "$message" == "DONE" || "$message" == ERROR* ]]; then
        break
    fi
    sleep 1
done

echo "Remote testing completed. message: $message  Final status is saved in remoteprogress.log " 
