#!/bin/bash

function is_instance {
  id=$1

  # Run the command and save the output
  json_output=$(./vast show instances --raw 2>/dev/null)

  # Check the return status of the command
  if [ $? -ne 0 ]; then
    echo "unknown"
    return
  fi


  # Convert the JSON array to a Bash array
  mapfile -t instances < <(echo "$json_output" | jq -r '.[] | @base64')

  # Now we can loop over the instances array
  for instance in "${instances[@]}"; do
    # Decode the instance from base64 back to JSON
    instance_json=$(echo "$instance" | base64 --decode)

    # Extract the ID from the JSON
    instance_id=$(echo "$instance_json" | jq -r '.id')

    # If this is the instance we're looking for
    if [ "$instance_id" = "$id" ]; then
      # Extract and print true status
      status=$(echo "$instance_json" | jq -r 'if .id != null then "false" else "true" end')
      echo "$status"
      return
    fi
  done

  echo "false"
}

# Check if two arguments were provided
if [ "$#" -ne 4 ]; then
    echo "Usage: ./ <IP> <Port> <instances_id> <machine_id>"
    exit 1
fi

# Get the IP and port from command line arguments
IP=$1
PORT=$2
instances_id=$3
machine_id=$4

# Generate a unique lock file name based on the parameters
lock_file="/tmp/machine_tester_locks_second/lock_${IP}_${PORT}_${instances_id}_${machine_id}"
mkdir -p "/tmp/machine_tester_locks_second"
# Check if lock file already exists
if [ -f "$lock_file" ]; then
    echo "Lock file exists. Exiting..."
    exit 1
fi

# Create lock file
touch "$lock_file"

SECONDS=0  # reset the SECONDS counter

while true; do
    # ...
done

while [ "$(is_instance "$instance_id")" = "true" ]; do
    sleep 60
    ./vast destroy instance "$instances_id"
done

echo "Machine: $machine_id Done with testing remote.sh results $message"

# Remove lock file
rm "$lock_file"

echo "Machine: $machine_id Done with testeing remote.sh results $message"
