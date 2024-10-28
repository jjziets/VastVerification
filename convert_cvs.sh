#!/bin/bash

# List of files to convert
files=("Pass_testresults.log")

for file in "${files[@]}"; do
    # Checking if the file exists
    if [ ! -f "$file" ]
    then
        echo "File $file does not exist."
        continue
    fi

    # Reading the file and replacing new lines with commas
    sed ':a;N;$!ba;s/\n/,/g' "$file" > "${file%.*}_comma.log"
done
