#!/bin/bash

function is_instance {
  id=$1
  retry_count=0
  max_retries=3

  while [ $retry_count -lt $max_retries ]; do
    # Run the command and save the output
    json_output=$(./vast show instances --raw 2>/dev/null)

    # Check the return status of the command
    if [ $? -eq 0 ]; then
      break
    fi

    # Increment the retry count
    ((retry_count++))

    # If we've exhausted our retries, exit
    if [ $retry_count -eq $max_retries ]; then
      # You can uncomment any of the below lines or add more as per your requirements
      #echo "unknown"
      #echo "$machine_id status is unknown" >> Error_testresults.log
      #./vast destroy instance  $instances_id
      return
    fi
  done

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
    echo "$machine_id usage error " >> Error_testresults.log
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

# Attempt to acquire the lock
if flock -n "$lock_file" -c "true"; then
    SECONDS=0  # reset the SECONDS counter

    while true; do
# Check if script has been running for longer than 5 minutes
    if [ $SECONDS -gt 300 ]; then
        echo "$machine_id Time out while stress testing " >> Error_testresults.log
        ./vast destroy instance  $instances_id
        exit 1
    fi

    # Send an 'EOT' message and receive response
    message=$(echo "EOT" | nc $IP $PORT)
#    echo "instances_id:$instances_id machine_id:$machine_id  $message" 
    # If the message is 'DONE' or starts with 'ERROR', exit the loop
    if [[ "$message" == "DONE" ]]; then
        echo "$machine_id" >> Pass_testresults.log
        ./vast destroy instance  $instances_id
	break
    elif [[ "$message" == ERROR* ]]; then
       echo "$machine_id $message" >> Error_testresults.log
        ./vast destroy instance  $instances_id
        break
    fi
    sleep 1
    done

    # Check if the instance is still running
    while [ "$(is_instance "$instances_id")" = "true" ]; do
        sleep 60
        ./vast destroy instance "$instances_id"
    done

    # Remove the lock file
    rm "$lock_file"
else
    echo "Lock file exists. Exiting..."
    echo "$machine_id Lock file exists. Exiting... " >> Error_testresults.log
    exit 1
fi

echo "Machine: $machine_id Done with testing remote.sh results $message"
