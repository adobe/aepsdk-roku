clean:
	(rm -rf ./out)
	(rm -rf ./AEPRokuSDK)
	(rm -rf ./source/AdobeEdge.brs)
	(rm -rf ./components/adobe)

install-sdk: clean
	(cp -R ../../out .)
	(test -f ./out/AEPRoku.zip)
	(unzip ./out/AEPRoku.zip)
	(test -f ./AEPRokuSDK/components/adobe/AdobeEdgeTask.brs)
	(test -f ./AEPRokuSDK/components/adobe/AdobeEdgeTask.xml)
	(test -f ./AEPRokuSDK/AdobeEdge.brs)
	(cp -R ./AEPRokuSDK/components/adobe ./components)
	(cp ./AEPRokuSDK/AdobeEdge.brs ./source/AdobeEdge.brs)
	(rm -rf ./out)
	(rm -rf ./AEPRokuSDK)

# bsc: https://github.com/rokucommunity/brighterscript
install-bsc:
	(npm install brighterscript -g)

build:
	(bsc)
