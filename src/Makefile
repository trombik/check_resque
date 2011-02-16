INSTALL_CMD?=	/usr/bin/install
INSTALL_ARGS?=	-C -o root -g wheel -m 0755
INSTALL=	${INSTALL_CMD} ${INSTALL_ARGS}
PLUGINS=	check_resque \
			check_resque_failed

all:	${PLUGINS}

install:
.for P in ${PLUGINS}
	${INSTALL} ${P} ${PLUGINS_DIR}
.endfor

check_resque:
	cp check_resque.pl check_resque
	chmod +x check_resque

check_resque_failed:
	cp check_resque_failed.pl check_resque_failed
	chmod +x check_resque_failed

clean:
.for P in ${PLUGINS}
	rm -f ${P}
.endfor
