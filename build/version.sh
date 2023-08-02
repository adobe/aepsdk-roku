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

echo "Target version - ${BLUE}$1${NC}"
echo "------------------AEPRokuSDK-------------------"
SOURCE_CODE_VERSION=$(cat ./AEPRokuSDK/AEPSDK.brs | egrep '\s*VERSION\s*=\s*\"(.*)\"' | sed -e 's/.*= //; s/,//g; s/"//g')
echo "Souce code version - ${BLUE}${SOURCE_CODE_VERSION}${NC}"

if [[ "$1" == "$SOURCE_CODE_VERSION" ]]; then
    echo "${GREEN}Pass!${NC}"
else
    echo "${RED}[Error]${NC} Version do not match!"
    exit -1
fi
exit 0
