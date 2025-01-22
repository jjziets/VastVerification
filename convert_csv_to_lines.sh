#!/bin/bash

# Input file
input_file="passed_machines.txt"
# Output file
output_file="machines_per_line.txt"

# Ensure the output file is empty or create it
> "$output_file"

# Read the input file line by line
while IFS= read -r line; do
    # Skip the timestamp line
    if [[ $line =~ ^[0-9]+, ]]; then
        # Replace commas with newlines and append to the output file
        echo "$line" | tr ',' '\n' >> "$output_file"
    fi
done < "$input_file"

# Notify the user
echo "Conversion complete. Entries are written to $output_file."
