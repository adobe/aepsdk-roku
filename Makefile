GIT_HASH:=$(shell git show --name-status | grep commit | awk '{print $$2}' | head -c6)
SDK_VERSION:=$(shell ./build/sdkversion.sh)
# bsc: https://github.com/rokucommunity/brighterscript
install-bsc:
	(npm install brighterscript -g)

clean:
	(rm -rf ./output)
	(rm -rf ./out)

archive:clean build-sdk
	@echo "######################################################################"
	@echo "##### Archiving AdobeEdge SDK"
	@echo "######################################################################"

	chmod u+r+x ./build/sdkversion.sh
	@echo git-hash=$(GIT_HASH)
	@echo version=  $(SDK_VERSION)


	mkdir -p ./out

	touch ./output/info.txt
	@echo git-hash=$(GIT_HASH) >> ./output/info.txt
	@echo version=$(SDK_VERSION) >> ./output/info.txt

	test -f ./output/components/adobe/AdobeEdgeTask.brs
	test -f ./output/components/adobe/AdobeEdgeTask.xml
	test -f ./output/AdobeEdge.brs
	test -f ./output/info.txt

	zip -r ./out/AEPRoku.zip ./output/*

version:
	echo $(SDK_VERSION)

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
