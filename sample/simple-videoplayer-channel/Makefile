link-sdk:
	(rm -f ./source/AdobeEdge.brs)
	(rm -f ./components/adobe)
	(ln -s ../../../code/components/adobe ./components/adobe)
	(ln -s ../../../code/AdobeEdge.brs ./source/AdobeEdge.brs)

link-tests:
	(ln -s ../../../code/tests ./source/tests)
	(ln -s ../../../code/testFramework ./source/testFramework)


# bsc: https://github.com/rokucommunity/brighterscript
install-bsc:
	(npm install brighterscript -g)

build:
	(bsc)

unit-tests:
	(curl -d '' http://192.168.1.144:8060/launch/dev?RunTests=true)
	# (curl -d '' 'http://192.168.1.144:8060/launch/dev?RunTests=true')