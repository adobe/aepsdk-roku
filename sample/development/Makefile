link-sdk:
	(rm -rf ./source/adobe)
	(rm -rf ./components/adobe/AEPSDKTask.brs)
	(mkdir -p ./source/adobe)
	(ln -s ../../../../code/components/adobe/AEPSDKTask.brs ./components/adobe/AEPSDKTask.brs)
	(ln -s ../../../../code/AEPSDK.brs ./source/adobe/AEPSDK.brs)
	(ln -s ../../../../code/main/common ./source/adobe/common)
	(ln -s ../../../../code/main/edge ./source/adobe/edge)
	(ln -s ../../../../code/main/services ./source/adobe/services)
	(ln -s ../../../../code/main/task ./source/adobe/task)
	(ln -s ../../../../code/main/core ./source/adobe/core)


link-tests:
	(ln -s ../../../code/tests ./source/tests)

link-test-framework:
	(ln -s ../../../code/testFramework ./source/testFramework)


# bsc: https://github.com/rokucommunity/brighterscript
install-bsc:
	(npm install brighterscript -g)

build:
	(bsc)
