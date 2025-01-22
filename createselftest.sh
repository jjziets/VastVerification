#!/bin/bash

# Check if exactly one argument is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <machine_id>"
    exit 1
fi

# Run the vast search command with the provided machine ID

./vast  create instance "$1"  --image vastai/test:selftest --direct --onstart-cmd 'python3 remote.py' --env '-e TZ=PDT -e XNAME=XX4 -p 5000:5000' --disk 40
