# configurations

OUTPUT_DIR = ./output
OUT_DIR = ./out
INFO_TXT_FILE = info.txt

SDK_COMPONENTS_DIR = ./code/components

GIT_HASH:=$(shell git show --name-status | grep commit | awk '{print $$2}' | head -c6)
VERSION:=$(shell grep "VERSION = " ./output/AdobeEdge.brs | sed -e 's/.*= //; s/,//g; s/"//g')

# bsc: https://github.com/rokucommunity/brighterscript
install-bsc:
	(npm install brighterscript -g)

clean:
	(rm -rf $(OUTPUT_DIR))
	(rm -rf $(OUT_DIR))
	
archive:clean build-sdk
	@echo "######################################################################"
	@echo "##### Archiving AdobeEdge SDK"
	@echo "######################################################################"
	@echo git-hash=$(GIT_HASH)
	@echo version=$(VERSION)

	mkdir -p $(OUT_DIR)

	touch $(OUTPUT_DIR)/$(INFO_TXT_FILE)
	@echo git-hash=$(GIT_HASH) >> $(OUTPUT_DIR)/$(INFO_TXT_FILE)
	@echo version=$(VERSION) >> $(OUTPUT_DIR)/$(INFO_TXT_FILE)
	cp -r $(SDK_COMPONENTS_DIR) $(OUTPUT_DIR)

	zip -r ./$(OUT_DIR)/AdobeEdge-$(VERSION).zip $(OUTPUT_DIR)/*

version:
	echo $(VERSION)

# Each *.brs should include a moulde name line as below: 
# *************** MODULE: {module name} ****************
# This line will be used to generate the final SDK file.
# The module line should be placed before line 15.
MODULE_LINE_SHOULD_BEFORE_LINE_NUMBER = 15
build-sdk:
	./build/build.sh ${MODULE_LINE_SHOULD_BEFORE_LINE_NUMBER}