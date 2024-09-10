GIT_HASH:=$(shell git rev-parse --short HEAD)
SDK_VERSION:=$(shell cat ./code/main/common/version.brs | egrep '\s*VERSION\s*=\s*\"(.*)\"' | sed -e 's/.*= //; s/,//g; s/"//g')

# bsc: https://github.com/rokucommunity/brighterscript
install-bsc:
	@echo "############################### Installing BrighterScript Compiler ###############################"
	(npm install brighterscript -g)

clean:
	@echo "############################### Clean ###############################"
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

	test -f ./output/components/adobe/AEPSDKTask.brs
	test -f ./output/components/adobe/AEPSDKTask.xml
	test -f ./output/AEPSDK.brs
	test -f ./output/info.txt

	mv ./output ./AEPRokuSDK

	zip -r ./out/AEPRokuSDK.zip ./AEPRokuSDK/* -x '**/.DS_Store'

version:
	@echo $(SDK_VERSION)

# Each *.brs should include a moulde name line as below:
# *************** MODULE: {module name} ****************
# This line will be used to generate the final SDK file.
# The module line should be placed before line 15.
MODULE_LINE_SHOULD_BEFORE_LINE_NUMBER = 15
build-sdk:
	@echo "############################### Building AEP Roku SDK ###############################"
	./build/build.sh ${MODULE_LINE_SHOULD_BEFORE_LINE_NUMBER}

# usage: make check-version VERSION=1.0.0
check-version:
	@echo "############################### Check Version ###############################"
	@VERSION=$(VERSION) sh ./build/version.sh $(VERSION)
#sh ./build/version.sh $(VERSION)

all: install-bsc archive
	make -C ./sample/simple-videoplayer-channel install-sdk build
