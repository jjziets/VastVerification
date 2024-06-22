#!/bin/bash

# Function to check if the machine meets the requirements
function check_requirements {
  machine_id=$1

  # Initialize an array to hold reasons why the machine does not meet the requirements
  unmet_reasons=()

  # Perform the search for the specified machine_id
  result=$(./vast search offers "machine_id=$machine_id verified=any rentable=true" --raw)

  # Check if the machine_id was found
  if [ "$result" == "[]" ]; then
    unmet_reasons+=("Machine ID $machine_id not found or not rentable. Please ensure the machine is listed and not rented on demand.")
  else
    # Extract the relevant fields from the JSON result
    cuda_version=$(echo "$result" | jq -r '.[0].cuda_max_good // 0')
    reliability=$(echo "$result" | jq -r '.[0].reliability // 0')
    direct_ports=$(echo "$result" | jq -r '.[0].direct_port_count // 0')
    pcie_bandwidth=$(echo "$result" | jq -r '.[0].pcie_bw // 0')
    inet_down_speed=$(echo "$result" | jq -r '.[0].inet_down // 0')
    inet_up_speed=$(echo "$result" | jq -r '.[0].inet_up // 0')
    gpu_ram=$(echo "$result" | jq -r '.[0].gpu_ram // 0')
    verified_status=$(echo "$result" | jq -r '.[0].verified // "unknown"')

    # Check each requirement and add to the array if not met
    if (( $(echo "$cuda_version < 12.4" | bc -l) )); then
      unmet_reasons+=("CUDA version is $cuda_version (required >= 12.4)")
    fi
    if (( $(echo "$reliability <= 0.90" | bc -l) )); then
      unmet_reasons+=("Reliability is $reliability (required > 0.90)")
    fi
    if (( direct_ports <= 3 )); then
      unmet_reasons+=("Direct port count is $direct_ports (required > 3)")
    fi
    if (( $(echo "$pcie_bandwidth <= 3" | bc -l) )); then
      unmet_reasons+=("PCIe bandwidth is $pcie_bandwidth (required > 3)")
    fi
    if (( $(echo "$inet_down_speed <= 10" | bc -l) )); then
      unmet_reasons+=("Internet download speed is $inet_down_speed Mb/s (required > 10 Mb/s)")
    fi
    if (( $(echo "$inet_up_speed <= 10" | bc -l) )); then
      unmet_reasons+=("Internet upload speed is $inet_up_speed Mb/s (required > 10 Mb/s)")
    fi
    if (( $(echo "$gpu_ram <= 7" | bc -l) )); then
      unmet_reasons+=("GPU RAM is $gpu_ram GB (required > 7 GB)")
    fi
  fi

  # Check if all requirements are met or if there are any unmet reasons
  if [ ${#unmet_reasons[@]} -eq 0 ]; then
    echo "Machine ID $machine_id meets all the requirements."
    exit 0
  else
    echo "Machine ID $machine_id does not meet the requirements:"
    for reason in "${unmet_reasons[@]}"; do
      echo "- $reason"
    done
    exit 1
  fi
}

# Main script execution
if [ $# -ne 1 ]; then
  echo "Usage: $0 <machine_id>"
  exit 1
fi

machine_id=$1
check_requirements $machine_id
