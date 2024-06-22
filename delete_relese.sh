#!/bin/bash

# Define your repository owner and name
OWNER="jjziets"
REPO="VastVerification"
RELEASE_TAG="0.1-beta"

# List the assets for the release and get their IDs
ASSET_IDS=$(gh api "repos/$OWNER/$REPO/releases/tags/$RELEASE_TAG" --jq '.assets[].id')

# Check if there are any assets to delete
if [ -n "$ASSET_IDS" ]; then
    echo "Deleting existing assets for release $RELEASE_TAG..."
    # Loop through each asset ID and delete it
    for asset_id in $ASSET_IDS; do
        gh api --method DELETE "repos/$OWNER/$REPO/releases/assets/$asset_id"
        if [ $? -eq 0 ]; then
            echo "Deleted asset with ID $asset_id."
        else
            echo "Failed to delete asset with ID $asset_id."
            exit 1
        fi
    done
else
    echo "No assets to delete for release $RELEASE_TAG."
fi

# Re-upload the new files
echo "Uploading new files to release $RELEASE_TAG..."
gh release upload $RELEASE_TAG ./check_machine_requirements.sh ./machinetester.sh ./autoverify_machineid.sh ./get_port_from_instance_id.py ./https_client.py ./destroy_all_instances.sh

if [ $? -eq 0 ]; then
    echo "Files uploaded successfully."
else
    echo "Failed to upload files."
    exit 1
fi
