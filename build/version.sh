#!/usr/bin/env bash
#
# Copyright 2023 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

set -e

NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'

# Check if target version is passed as argument
if [ -z "$1" ]; then
    echo "${RED}[Error]${NC} Target version is not provided!"
    echo "${YELLOW}Hint:${NC} Please provide a version number as an argument."
    echo "${YELLOW}Hint:${NC} Usage: \"make check-version VERSION=1.0.0\""
    exit 1
fi

echo "Target version - ${BLUE}$1${NC}"
SOURCE_CODE_VERSION=$(cat ./AEPRokuSDK/AEPSDK.brs | egrep '\s*VERSION\s*=\s*\"(.*)\"' | sed -e 's/.*= //; s/,//g; s/"//g')
echo "Souce code version - ${BLUE}${SOURCE_CODE_VERSION}${NC}"

if [[ "$1" == "$SOURCE_CODE_VERSION" ]]; then
    echo "${GREEN}Pass!${NC} Version matches $1"
else
    echo "${RED}[Error]${NC} Version do not match: $1 != $SOURCE_CODE_VERSION"
    exit -1
fi
exit 0
