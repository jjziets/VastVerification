#!/bin/bash

# Create or clear the log file and write "STARTED"
echo "STARTED" > progress.log

# Start the background process
while true; do
    # Start nc and set it to respond with the content of progress.log
    # The -k option makes it listen indefinitely for new connections
    # The -l option makes it listen for inbound connections
    # The -p option specifies the port it will listen to
    # Use -c to keep alive and reload the file on each connection
    nc -lp 5000 -c 'cat progress.log'
done &

# Calculate the initial MD5 hash of the log file
prev_md5=$(md5sum progress.log)

# Execute the next command
# Run the Python script and capture its exit status
python3 testAllGpusResNet50.py
exit_status=$?

# Check if the MD5 hash of progress.log has changed
curr_md5=$(md5sum progress.log)
if [ "$prev_md5" != "$curr_md5" ]; then
    # If the MD5 hash has changed, print the content of progress.log
    cat progress.log
fi


# Once the command completes, append its exit status to progress.log
if [ $exit_status -eq 0 ]
then
  echo "DONE" > progress.log
else
  echo "ERROR" > progress.log
fi
