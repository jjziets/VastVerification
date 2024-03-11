#!/bin/bash

# Run the vast search command and capture its output
output=$(./vast search offers --limit 65535 'verified=false cuda_vers>=12.0 reliability>0.90 direct_port_count>3 pcie_bw>3 inet_down>10 inet_up>10 gpu_ram>7' -o 'dlperf-')

# Extract the lines containing the IDs, then count them
# Assuming IDs are numerical and appear at the beginning of each line in the output
id_count=$(echo "$output" | grep -c '^[0-9]')

# Print the count of IDs
echo "Number of IDs: $id_count"
