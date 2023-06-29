#!/bin/bash
#to be used with vastcli in a shell. it will sreach for all the systems  unverified systems that meets the createare and starts the docker image jjziets/vasttest:latest
# in it will run a scrypt remote.sh that will test the system and report on port 5000
# once the instance is running it will is start local.sh  scrypt detatched with the machineID, IP and Port. local.sh will talk to remote.sh on the system that is being tested and save the result to Pass_testresults.log  as machine_id:done or to Error_testresults.log machine_id: error and message
# local.sh  has 5min to get a responce from remote.sh if it does not it will write to progress.log  machineID: no responce from direct port 
# if the instance status_msg show error or if the instance don't start in 10min time autoverify.sh will destory the instance and write the reason to the Error_testresults.log
# ./vast create instance 6298306 --image  jjziets/vasttest:latest  --jupyter --direct --env '-e TZ=PDT -e XNAME=XX4 -p 5000:5000' --disk 20 --onstart-cmd './remote.sh'

declare -A machine_ids
declare -A public_ipaddrs
declare -a active_instance_id

function update_machine_id_and_ipaddr {
  # Run the command and save the output
  json_output=$(./vast show instances --raw)

  # Convert the JSON array to a Bash array
  mapfile -t instances < <(echo "$json_output" | jq -r '.[] | @base64')

  # Now we can loop over the instances array
  for instance in "${instances[@]}"; do
    # Decode the instance from base64 back to JSON
    instance_json=$(echo "$instance" | base64 --decode)

    # Extract the instance_id, machine_id, and public_ipaddr from the JSON
    instance_id=$(echo "$instance_json" | jq -r '.id')
    machine_id=$(echo "$instance_json" | jq -r '.machine_id')
    public_ipaddr=$(echo "$instance_json" | jq -r '.public_ipaddr')

    # Add the machine_id and public_ipaddr to the associative arrays
    machine_ids["$instance_id"]="$machine_id"
    public_ipaddrs["$instance_id"]="$public_ipaddr"
    active_instance_id+=("$instance_id") # Adding the instance_id to the array
  done
}

pause () {
	echo "Press any key to continue"
	while [ true ] ; do
	read -t 1 -n 1
	if [ $? = 0 ] ; then
		return
	fi
	done
}

function get_machine_id {
  local instance_id=$1

  # Check if the machine_id is in the associative array
  if [ -z "${machine_ids[$instance_id]}" ]; then
    # If not, update the associative arrays
    update_machine_id_and_ipaddr
  fi

  # Now the machine_id should be in the associative array, so we can return it
  echo "${machine_ids[$instance_id]}"
}

function get_public_ipaddr {
  local instance_id=$1

  # Check if the public_ipaddr is in the associative array
  if [ -z "${public_ipaddrs[$instance_id]}" ]; then
    # If not, update the associative arrays
    update_machine_id_and_ipaddr
  fi

  # Now the public_ipaddr should be in the associative array, so we can return it
  echo "${public_ipaddrs[$instance_id]}"
}


function get_status_msg {
  id=$1

  # Run the command and save the output
  json_output=$(./vast show instances --raw)

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
      # Extract and print the status message
      status_msg=$(echo "$instance_json" | jq -r '.status_msg')
      echo "$status_msg"
      return
    fi
  done

  echo "No instance with ID $id found."
}

function get_actual_status {
  id=$1

  # Run the command and save the output
  json_output=$(./vast show instances --raw 2>error.log)

  # Check the return status of the command
  if [ $? -ne 0 ]; then
    echo "unknown"
    return
  fi

  if [[ -z "$json_output" ]]; then
    echo "No JSON output from command"
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
      # Extract and print the actual_status
      actual_status=$(echo "$instance_json" | jq -r 'if .actual_status != null then .actual_status else "unknown" end')
      echo "$actual_status"
      return
    fi
  done

  echo "unknown"
}


#****************************** start of main prcess ********

# create all the instances as needed
#Offers=($(./vast search offers 'verified=false cuda_vers>=12.0  gpu_frac=1 reliability>0.90 direct_port_count>3 pcie_bw>3 inet_down>30 inet_up>30 gpu_ram>7'  -o 'dlperf-'  | sed 's/|/ /'  | awk '{print $1}' )) # get all the instanses number from vast
#unset Offers[0] #delte the first index as it contains the title

# Fetch data from the system
tempOffers=($(./vast search offers 'verified=false cuda_vers>=12.0  reliability>0.90 direct_port_count>3 pcie_bw>3 inet_down>30 inet_up>30 gpu_ram>7'  -o 'dlperf-'  | sed 's/|/ /'  | awk '{print $1,$10,$17,$18}'))
# Delete the first index as it contains the title
unset tempOffers[0]
unset tempOffers[1]
unset tempOffers[2]
unset tempOffers[3]

#for element in "${tempOffers[@]}"; do
#    echo $element
#done
#pause

#for ((i=0; i<${#tempOffers[@]}; i+=4)); do
#    echo ${tempOffers[i]} ${tempOffers[i+1]} ${tempOffers[i+2]} ${tempOffers[i+3]}
#done

#pause

# Declare associative arrays
declare -A maxDLPs
declare -A maxIDsWithMaxDLPs

# Parse the tempOffers array
for ((i=0; i<${#tempOffers[@]}; i+=4)); do
    id=${tempOffers[i]}
    dlp=${tempOffers[i+1]}
    mach_id=${tempOffers[i+2]}
    status=${tempOffers[i+3]}

    # Skip if mach_id is empty
    if [[ -z "$mach_id" ]]; then
        continue
    fi

#    echo "Current mach_id: $mach_id"

    # Skip if status is "verified"
    if [[ "$status" == "verified" ]]; then
        continue
    fi

    # If the current DLP is higher than the stored one or if mach_id doesn't exist in maxDLPs array
    if [[ -z ${maxDLPs[$mach_id]} || $(bc <<< "$dlp > ${maxDLPs[$mach_id]}") -eq 1 ]]; then
        maxDLPs[$mach_id]=$dlp
        maxIDsWithMaxDLPs[$mach_id]=$id
    fi
done

# Now, we only need IDs. Let's move them to the Offers array.
Offers=("${maxIDsWithMaxDLPs[@]}")

echo "There are ${#Offers[@]} systems to verify starting"

	echo "There are ${#Offers[@]} systems to verify starting"
        for index in "${!Offers[@]}"; do
		./vast create instance "${Offers[index]}"  --image  jjziets/vasttest:latest  --jupyter --direct --env '-e TZ=PDT -e XNAME=XX4 -p 5000:5000' --disk 20 --onstart-cmd './remote.sh'
        done

#*********************** Get all the instance
sleep 10
echo "Logging all the instance progress"
update_machine_id_and_ipaddr  ## update the machine_id and the ip address
start_time=$(date +%s) #store the time so that it can be checked
active_instance_id=($(printf "%s\n" "${active_instance_id[@]}" | sort -u)) # This line prints each element of active_instance_id on its own line, sorts the output (removing duplicates with -u), and assigns the result back to active_instance_id.
echo "$start_time: Error logs for machine_id. Tested  ${#active_instance_id[@]} instances" > Error_testresults.log
echo "$start_time: Pass logs for machine_id. Tested  ${#active_instance_id[@]} instances" > Pass_testresults.log
echo "There are ${#active_instance_id[@]} active instances"

# Lock file base directory
lock_dir="/tmp/machine_tester_locks"

mkdir -p "$lock_dir"
shopt -s nocasematch

## recreate the instance array

while (( ${#active_instance_id[@]} > 0 )); do
  for i in "${!active_instance_id[@]}"; do
    instance_id="${active_instance_id[$i]}"
    actual_status=$(get_actual_status "$instance_id")
    echo "instance=$instance_id $actual_status"
    current_time=$(date +%s)
    if [ "$actual_status" == "running" ]; then
        machine_id=$(get_machine_id "$instance_id")
        public_port=$(python3 get_port_from_instance_id.py  "$instance_id")
        exit_code=$?
        if [ $exit_code -eq 2 ]; then
            echo "$machine_id:No Direct Ports found $(get_status_msg "$instance_id")" >> Error_testresults.log
            ./vast destroy instance "$instance_id" #destroy the instance
            unset 'active_instance_id[$i]'
            active_instance_id=("${active_instance_id[@]}") # reindex the array
            break  # We've modified the array in the loop, so we break and start the loop anew
        elif [ $exit_code -eq 0 ] && [ "$public_port" != "" ]; then
                public_ip=$(get_public_ipaddr "$instance_id")
                lock_file="$lock_dir/lock_${public_ip}_${public_port}_${instance_id}_${machine_id}"
                if [ ! -f "$lock_file" ]; then
                   touch "$lock_file"
                   trap "rm -f '$lock_file'" EXIT # Add a trap to remove the lock file when the script exits
                   ./machinetester.sh "$public_ip" "$public_port" "$instance_id" "$machine_id" && rm -f "$lock_file" &
                   echo "$instance_id starting ./machinetester.sh $public_ip $public_port $instance_id $machine_id"
                else
                    echo "$instance_id already running ./machinetester.sh $public_ip $public_port $instance_id $machine_id"
                fi
                unset 'active_instance_id[$i]' #delete this Instance from the list
                active_instance_id=("${active_instance_id[@]}") # reindex the array
                break  # We've modified the array in the loop, so we break and start the loop anew
        elif (( current_time - start_time > 900 )); then #check if it has been waiting for more than 15min
            echo "$machine_id:Time exceeded $(get_status_msg "$instance_id")" >> Error_testresults.log
            ./vast destroy instance "$instance_id" #destroy the instance
            unset 'active_instance_id[$i]'
            active_instance_id=("${active_instance_id[@]}") # reindex the array
            break  # We've modified the array in the loop, so we break and start the loop anew
        fi
    elif [ "$actual_status" == "loading" ]; then
        if (( current_time - start_time > 900 )); then #check if it has been waiting for more than 15min
            echo "$machine_id:Time exceeded $(get_status_msg "$instance_id")" >> Error_testresults.log
            ./vast destroy instance "$instance_id" #destroy the instance
            unset 'active_instance_id[$i]'
            active_instance_id=("${active_instance_id[@]}") # reindex the array
            break  # We've modified the array in the loop, so we break and start the loop anew
        fi
        #Status: Error response from daemon: failed to create task for container: failed to create shim task: OCI runtime create failed
        status_msg=$(get_status_msg "$instance_id")
        if [[ $status_msg == "Error"* ]]; then
            echo "$machine_id: $status_msg" >> Error_testresults.log
            ./vast destroy instance "$instance_id" #destroy the instance
            unset 'active_instance_id[$i]'
            active_instance_id=("${active_instance_id[@]}") # reindex the array
            break  # We've modified the array in the loop, so we break and start the loop anew
        fi
    elif [ "$actual_status" == "created" ]; then
        #Status: Error response from daemon: failed to create task for container: failed to create shim task: OCI runtime create failed
        status_msg=$(get_status_msg "$instance_id")
        if [[ $status_msg == "Error"* ]]; then
            echo "$machine_id: $status_msg" >> Error_testresults.log
            ./vast destroy instance "$instance_id" #destroy the instance
            unset 'active_instance_id[$i]'
            active_instance_id=("${active_instance_id[@]}") # reindex the array
            break  # We've modified the array in the loop, so we break and start the loop anew
        elif (( current_time - start_time > 900 )); then #check if it has been waiting for more than 10min
            echo "$machine_id:Time exceeded $(get_status_msg "$instance_id")" >> Error_testresults.log
            ./vast destroy instance "$instance_id" #destroy the instance
            unset 'active_instance_id[$i]'
            active_instance_id=("${active_instance_id[@]}") # reindex the array
            break  # We've modified the array in the loop, so we break and start the loop anew
        fi
    elif [ "$actual_status" == "offline" ]; then
            echo "$machine_id: went offline $(get_status_msg "$instance_id")" >> Error_testresults.log
            ./vast destroy instance "$instance_id" #destroy the instance
            unset 'active_instance_id[$i]'
            active_instance_id=("${active_instance_id[@]}") # reindex the array
            break  # We've modified the array in the loop, so we break and start the loop anew
    fi
  done

  if (( ${#active_instance_id[@]} == 0 )); then
    echo "done with all instances"
    break
  fi
  sleep 1
done


while (( $(pgrep -fc machinetester.sh) > 0 ))
do
    echo -n "Number of machinetester.sh processes still running: $(pgrep -fc machinetester.sh)"
    sleep 1
done

echo "Exit: done with all instances"
