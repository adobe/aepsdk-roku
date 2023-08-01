# bsc: https://github.com/rokucommunity/brighterscript
install-bsc:
	(npm install brighterscript -g)

clean:
	(rm -rf ./out)

archive:clean build-sdk
	@echo "######################################################################"
	@echo "##### Archiving AdobeEdge SDK"
	@echo "######################################################################"

	mkdir -p ./out

	test -f ./output/components/adobe/AdobeEdgeTask.brs
	test -f ./output/components/adobe/AdobeEdgeTask.xml
	test -f ./output/AdobeEdge.brs

	zip -r ./out/AEPRoku.zip ./output/*

# Each *.brs should include a moulde name line as below:
# *************** MODULE: {module name} ****************
# This line will be used to generate the final SDK file.
# The module line should be placed before line 15.
MODULE_LINE_SHOULD_BEFORE_LINE_NUMBER = 15
build-sdk:
	./build/build.sh ${MODULE_LINE_SHOULD_BEFORE_LINE_NUMBER}

# usage: make check-version VERSION=1.0.0
check-version:
	sh ./Script/version.sh $(VERSION)
