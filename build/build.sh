#!/bin/bash

echo "######################################################################"
echo "##### merging AdobeEdge SDK"
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
rm -rf /output/AdobeEdge.brs

cat ./code/AdobeEdge.brs > ./output/AdobeEdge.brs

brs_array=(`find ./code/main -maxdepth 2 -name "*.brs"`)

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