#!/bin/bash

# Check if exactly one argument is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <machine_id>"
    exit 1
fi

# Run the vast search command with the provided machine ID

./vast  create instance "$1"  --image nvidia/cuda:12.4.1-runtime-ubuntu22.04   --jupyter   --direct  --env '-e TZ=PDT -e XNAME=XX4 -p 22:22 -p 8080:8080 -p 5000:5000 -e JUPYTER_DIR=/ -h hostname  -e OPEN_BUTTON_TOKEN=1 -e OPEN_BUTTON_PORT=8080' --disk 40
