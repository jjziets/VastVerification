#!/bin/bash

# Check if an argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <instance-argument>"
  exit 1
fi

# Assign the argument to a variable
INSTANCE_ARG=$1

# Use the argument in the vast create instance command
./vast create instance $INSTANCE_ARG --image jjziets/vasttest:latest --jupyter --direct --env '-e TZ=PDT -e XNAME=XX4 -p 5000:5000' --disk 20
