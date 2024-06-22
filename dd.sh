#!/bin/bash

# Get list of instances in raw format
INSTANCES=$(./vast show instances --raw --api-key $1
)

# Extract IDs using jq (a lightweight JSON processor) and iterate over them
echo "$INSTANCES" | jq -r '.[].id' | while read -r ID; do
    echo "Destroying instance with ID: $ID"
    ./vast destroy instance $ID --api-key $1
done
