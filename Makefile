# configurations

OUTPUT_DIR = ./output
INFO_TXT_FILE = info.txt

SDK_MAIN_FILE = ./code/AdobeEdge.brs
SDK_COMPONENTS_DIR = ./code/components

GIT_HASH:=$(shell git show --name-status | grep commit | awk '{print $$2}' | head -c6)
VERSION:=$(shell grep "VERSION = " ./code/AdobeEdge.brs | sed -e 's/.*= //; s/,//g; s/"//g')

# bsc: https://github.com/rokucommunity/brighterscript
install-bsc:
	(npm install brighterscript -g)

clean:
	(rm -rf $(OUTPUT_DIR))
	
archive:clean
	@echo "######################################################################"
	@echo "##### packing"
	@echo "######################################################################"
	@echo git-hash=$(GIT_HASH)

	mkdir -p $(OUTPUT_DIR)
	touch $(OUTPUT_DIR)/$(INFO_TXT_FILE)
	@echo git-hash=$(GIT_HASH) >> $(OUTPUT_DIR)/$(INFO_TXT_FILE)
	@echo version=$(VERSION) >> $(OUTPUT_DIR)/$(INFO_TXT_FILE)
	cp -r $(SDK_COMPONENTS_DIR) $(OUTPUT_DIR)
	cp $(SDK_MAIN_FILE) $(OUTPUT_DIR)/

	 zip -r ./out/AdobeEdge-$(VERSION).zip $(OUTPUT_DIR)/*

version:
	echo $(VERSION)