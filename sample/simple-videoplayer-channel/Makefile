clean:
	@echo "############################### Sample App: Removing AEP Roku SDK ###############################"
	(rm -rf ./out)
	(rm -rf ./AEPRokuSDK)
	(rm -rf ./source/AEPSDK.brs)
	(rm -rf ./components/adobe)

install-sdk: clean
	@echo "############################### Sample App: Installing AEP Roku SDK ###############################"
	(cp -R ../../out .)
	(test -f ./out/AEPRokuSDK.zip)
	(unzip ./out/AEPRokuSDK.zip)
	(test -f ./AEPRokuSDK/components/adobe/AEPSDKTask.brs)
	(test -f ./AEPRokuSDK/components/adobe/AEPSDKTask.xml)
	(test -f ./AEPRokuSDK/AEPSDK.brs)
	(cp -R ./AEPRokuSDK/components/adobe ./components)
	(cp ./AEPRokuSDK/AEPSDK.brs ./source/AEPSDK.brs)
	(rm -rf ./out)
	(rm -rf ./AEPRokuSDK)

# bsc: https://github.com/rokucommunity/brighterscript
install-bsc:
	@echo "############################### Sample App: Installing BrighterScript Compiler ###############################"
	(npm install brighterscript -g)

build:
	@echo "############################### Sample App: Building simple-videoplayer-channel ###############################"
	(bsc)
