#!/usr/bin/env bash

# Copyright 2023 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

NC='\033[0m'
RED='\033[0;31m'

# Get the max number of lines could include license header
line_max=$1

# Check if the input exists
if [ -z $line_max ]; then
    echo "${RED}[Error]${NC} Input is empty."
    exit 1
fi

echo "##### Creating the output directory"

# Create the output directory if not exists
mkdir -p output
rm -rf ./output/AEPSDK.brs
rm -rf ./output/components

echo "##### Merging & copying the SDK source code to output directory"
# Copy the task node files to output directory
cp -r ./code/components ./output

# Merge the souce files to one SDK file under output directory
cat ./code/AEPSDK.brs > ./output/AEPSDK.brs

core_array=(`find ./code/main/core -maxdepth 2 -name "*.brs"`)
edge_array=(`find ./code/main/edge -maxdepth 2 -name "*.brs"`)
consent_array=(`find ./code/main/consent -maxdepth 2 -name "*.brs"`)
task_array=(`find ./code/main/task -maxdepth 2 -name "*.brs"`)
services_array=(`find ./code/main/services -maxdepth 2 -name "*.brs"`)
common_array=(`find ./code/main/common -maxdepth 2 -name "*.brs"`)
media_array=(`find ./code/main/media -maxdepth 2 -name "*.brs"`)

brs_array=("${core_array[@]}" "${edge_array[@]}" "${consent_array[@]}" "${task_array[@]}" "${services_array[@]}" "${common_array[@]}" "${media_array[@]}")

unordered_brs_array=(`find ./code/main -maxdepth 2 -name "*.brs"`)

if [ "${#brs_array[@]}" -ne "${#unordered_brs_array[@]}" ]; then
    echo "${RED}[Error]${NC} Missed some brs files while merging."
    exit 1
fi

for file in ${brs_array[@]}; do
# each *.brs should include a moulde name line, like:
# ********************************** MODULE: constants ************************************
# find the line number of the module name line.
    line=(`grep -n "MODULE: " $file | cut -d':' -f1`)
    if [ -z $line ]; then
        echo "${RED}[Error]${NC} Did not find the MODULE line in: $file"
        exit 1
    fi
    if [  $line -gt $line_max ]; then
        echo "${RED}[Error]${NC} $file has license header more than $line_max lines"
        exit 1
    fi

    echo "" >> ./output/AEPSDK.brs
    echo "" >> ./output/AEPSDK.brs

    tail +$line $file >> ./output/AEPSDK.brs
done

echo "##### Adding the metadata file info.txt"

# Add some meta data to the info.txt file
touch ./output/info.txt

MD5_HASH=$(md5 ./output/AEPSDK.brs | awk -F '=' '{print $2}' | xargs)
GIT_HASH=$(git rev-parse --short HEAD)
SDK_VERSION=$(cat ./output/AEPSDK.brs | egrep '\s*VERSION\s*=\s*\"(.*)\"' | sed -e 's/.*= //; s/,//g; s/"//g')

echo "git-hash=$GIT_HASH" >> ./output/info.txt
echo "version=$SDK_VERSION" >> ./output/info.txt
echo "md5-hash(AEPSDK.brs)=$MD5_HASH" >> ./output/info.txt
