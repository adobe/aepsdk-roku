clean:
	(rm -rf ./out)
	(rm -rf ./AEPRokuSDK)
	(rm -rf ./source/AEPSDK.brs)
	(rm -rf ./components/adobe)

install-sdk: clean
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
	(npm install brighterscript -g)

build:
	(bsc)
