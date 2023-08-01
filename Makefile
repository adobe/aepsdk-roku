GIT_HASH:=$(shell git rev-parse --short HEAD)
SDK_VERSION:=$(shell cat ./code/main/common/version.brs | egrep '\s*VERSION\s*=\s*\"(.*)\"' | sed -e 's/.*= //; s/,//g; s/"//g')

# bsc: https://github.com/rokucommunity/brighterscript
install-bsc:
	(npm install brighterscript -g)

clean:
	(rm -rf ./output)
	(rm -rf ./AEPRokuSDK)
	(rm -rf ./out)

archive:clean build-sdk
	@echo "######################################################################"
	@echo "##### Archiving AEP Roku SDK"
	@echo "######################################################################"
	@echo git-hash=$(GIT_HASH)
	@echo version=$(SDK_VERSION)

	mkdir -p ./out

	test -f ./output/components/adobe/AdobeEdgeTask.brs
	test -f ./output/components/adobe/AdobeEdgeTask.xml
	test -f ./output/AdobeEdge.brs
	test -f ./output/info.txt

	mv ./output ./AEPRokuSDK

	zip -r ./out/AEPRoku.zip ./AEPRokuSDK/* -x '**/.DS_Store'

version:
	@echo $(SDK_VERSION)

# Each *.brs should include a moulde name line as below:
# *************** MODULE: {module name} ****************
# This line will be used to generate the final SDK file.
# The module line should be placed before line 15.
MODULE_LINE_SHOULD_BEFORE_LINE_NUMBER = 15
build-sdk:
	./build/build.sh ${MODULE_LINE_SHOULD_BEFORE_LINE_NUMBER}

# usage: make check-version VERSION=1.0.0
check-version:
	sh ./build/version.sh $(VERSION)
