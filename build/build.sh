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