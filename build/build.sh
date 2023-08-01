#!/bin/bash

echo "######################################################################"
echo "##### Building AdobeEdge SDK"
echo "######################################################################"

# Get the max number of lines could include license header
line_max=$1

# Check if the input exists
if [ -z $line_max ]; then
    echo "Input is empty."
    exit 1
fi

# Create the output directory if not exists
mkdir -p output
rm -rf ./output/AdobeEdge.brs
rm -rf ./output/components

# Copy the task node files to output directory
cp -r ./code/components ./output

# Merge the souce files to one SDK file under output directory
cat ./code/AdobeEdge.brs > ./output/AdobeEdge.brs

core_array=(`find ./code/main/core -maxdepth 2 -name "*.brs"`)
edge_array=(`find ./code/main/edge -maxdepth 2 -name "*.brs"`)
task_array=(`find ./code/main/task -maxdepth 2 -name "*.brs"`)
services_array=(`find ./code/main/services -maxdepth 2 -name "*.brs"`)
common_array=(`find ./code/main/common -maxdepth 2 -name "*.brs"`)

brs_array=("${core_array[@]}" "${edge_array[@]}" "${task_array[@]}" "${services_array[@]}" "${common_array[@]}")

unordered_brs_array=(`find ./code/main -maxdepth 2 -name "*.brs"`)

if [ "${#brs_array[@]}" -ne "${#unordered_brs_array[@]}" ]; then
    echo "Error: miss some brs files when merging."
    exit 1
fi

for file in ${brs_array[@]}; do
# each *.brs should include a moulde name line, like: 
# ********************************** MODULE: constants ************************************
# find the line number of the module name line.
    line=(`grep -n "MODULE: " $file | cut -d':' -f1`)
    if [ -z $line ]; then
        echo "Did not find the MODULE line in: $file"
        exit 1
    fi
    if [  $line -gt $line_max ]; then
        echo "Error: $file has license header more than $line_max lines"
        exit 1
    fi
    
    echo "" >> ./output/AdobeEdge.brs
    echo "" >> ./output/AdobeEdge.brs

    tail +$line $file >> ./output/AdobeEdge.brs
done

# Add some meta data to the info.txt file
touch ./output/info.txt

MD5_HASH=$(md5 ./output/AdobeEdge.brs | awk -F '=' '{print $2}' | xargs)
GIT_HASH=$(git rev-parse --short HEAD)
SDK_VERSION=$(cat ./output/AdobeEdge.brs | egrep '\s*VERSION\s*=\s*\"(.*)\"' | sed -e 's/.*= //; s/,//g; s/"//g')

echo "git-hash=$GIT_HASH" >> ./output/info.txt
echo "version=$SDK_VERSION" >> ./output/info.txt
echo "md5-hash(AdobeEdge.brs)=$MD5_HASH" >> ./output/info.txt