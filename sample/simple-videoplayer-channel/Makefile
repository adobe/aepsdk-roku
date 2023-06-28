link-sdk:
	(rm -f ./source/AdobeEdge.brs)
	(rm -f ./components/adobe)
	(ln -s ../../../code/components/adobe ./components/adobe)
	(ln -s ../../../code/AdobeEdge.brs ./source/AdobeEdge.brs)

link-tests:
	(ln -s ../../../code/tests ./source/tests)

link-test-framework:
	(ln -s ../../../code/testFramework ./source/testFramework)


# bsc: https://github.com/rokucommunity/brighterscript
install-bsc:
	(npm install brighterscript -g)

build:
	(bsc)