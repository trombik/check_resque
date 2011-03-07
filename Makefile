VERSION=	1.2
PROJECT_NAME=	check_resque
RELEASE_NAME=	${PROJECT_NAME}-${VERSION}
RELEASE_DIR?=	../${RELEASE_NAME}
RELEASE_HOST?=	dev.jp.reallyenglish.com
RELEASE_HOST_DIST_DIR=	/usr/local/www/dist

MAKE=		make
DESTDIR?=	/usr/local
PLUGINS_DIR?=	${DESTDIR}/libexec/nagios

all:
	${MAKE} -C src/${P} all

create-destdir:
	install -d ${PLUGINS_DIR}

install:	create-destdir
	${MAKE} -C src/${P} install PLUGINS_DIR=${PLUGINS_DIR}

clean:
	${MAKE} -C src/${P} clean

clean-release:
	rm -f ../${RELEASE_NAME}.tgz

release: clean-release clean
	mkdir -p ${RELEASE_DIR}
	tar cf - . | tar -C ${RELEASE_DIR} --exclude .git --exclude .orig --exclude .bak --exclude .rej -xf - 
	tar -C .. -czf ../${RELEASE_NAME}.tgz ${RELEASE_NAME}
	rm -rf ${RELEASE_DIR}

publish:	release
	scp ../${RELEASE_NAME}.tgz ${RELEASE_HOST}:
	ssh -t ${RELEASE_HOST} sudo mkdir -p ${RELEASE_HOST_DIST_DIR}/${PROJECT_NAME}
	ssh -t ${RELEASE_HOST} sudo cp ${RELEASE_NAME}.tgz ${RELEASE_HOST_DIST_DIR}/${PROJECT_NAME}/
