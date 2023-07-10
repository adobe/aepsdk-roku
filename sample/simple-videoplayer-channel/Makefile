clean:
	(rm -rf ./out)
	(rm -rf ./output)
	(rm -rf ./source/AdobeEdge.brs)
	(rm -rf ./components/adobe)

install-sdk: clean
	(cp -R ../../out .)
	(test -f ./out/AdobeEdge-*.zip)
	(unzip ./out/AdobeEdge-*.zip)
	(test -f ./output/components/adobe/AdobeEdgeTask.brs)
	(test -f ./output/components/adobe/AdobeEdgeTask.xml)
	(test -f ./output/AdobeEdge.brs)
	(cp -R ./output/components/adobe ./components/adobe)
	(cp ./output/AdobeEdge.brs ./source/AdobeEdge.brs)


# bsc: https://github.com/rokucommunity/brighterscript
install-bsc:
	(npm install brighterscript -g)

build:
	(bsc)