SHELL=/bin/bash
NAME=postgresql
DOCKER=docker
DOCKER_PRESENT=$(shell docker version | wc -l)
CONTAINER_RUN=$(shell docker ps | grep ${NAME} | grep paintedfox/postgresql | wc -l)
CID=$(shell docker ps | grep ${NAME} | grep paintedfox/postgresql | awk '{print $$1}')
CID_ALL=$(shell docker ps -a | grep ${NAME} | grep paintedfox/postgresql | awk '{print $$1}')
CLONETO=/var/tmp/repo
REPO=https://github.com/TenderPro/test-sql-2017.git

DB_NAME=$(shell head -1 config.txt | awk '{print $$1}')
DB_USER=$(shell head -1 config.txt | awk '{print $$4}')
DB_CHARSET=$(shell head -1 config.txt | awk '{print $$2}')
DB_TEMPLATE=$(shell head -1 config.txt | awk '{print $$3}')
DB_PASS=$(shell head -1 config.txt | awk '{print $$5}')

help:
	@echo ""
	@echo "	make db			for first up database"
	@echo "	make reup		for re-up database"
	@echo ""
	@echo "	make stop		stop container"
	@echo "	make rm			remove conteiner"
	@echo "	make start		staop container"
	@echo ""
	@echo "===="
	@echo ""
	@echo "- used container name is ${NAME}, port for postgres is 5433"
	@echo "- used repo from github for run Makefile and up database dump"
	@echo "  this repo clones to ${CLONETO}"
	@echo "- started container uses path /srv/${NAME}-cnt/9.3-data on HOST!!!"
	@echo "  this is make postgres faster"
	@echo "- this makefile must be RUN AS ROOT"
	@echo ""

db: deps run
	$(MAKE) wait_for_up
	rm -rf ${CLONETO}
	git clone https://github.com/TenderPro/test-sql-2017.git ${CLONETO}
	$(MAKE) config_get

stop:
	${DOCKER} stop ${CID}

start:
	${DOCKER} start ${CID_ALL}
	$(MAKE) wait_for_up
	${DOCKER} exec -i ${CID_ALL} pg_ctlcluster 9.3 main2 start

rm:
	${DOCKER} rm ${CID_ALL}

run: repo
ifeq (${CONTAINER_RUN},0)
	${DOCKER} pull paintedfox/postgresql
	mkdir -p /srv/${NAME}-cnt/9.3-data
	${DOCKER} run -d --name="${NAME}" \
             -p 127.0.0.1:5433:5433 \
             -v /srv/${NAME}-cnt/9.3-data:/var/db \
             paintedfox/postgresql
else
	@echo "Container already run"
endif

deps:
	apt-get install git

repo:
ifeq (${DOCKER_PRESENT},0)
	echo "deb http://apt.dockerproject.org/repo debian-jessie main" > /etc/apt/sources.list.d/docker.list
	apt-key update
	apt-get update
	apt-get install -y --force-yes docker-engine
else
	@echo "Docker already installed"
endif

config_get:
	$(MAKE) add_db
	cp add_port.patch ${CLONETO}
	cd ${CLONETO}; git apply ./add_port.patch
	cd ${CLONETO}; $(MAKE) PG_HOST=localhost DB_NAME=${DB_NAME} DB_USER=${DB_USER} DB_PASS=${DB_PASS} DB_PORT=5433

add_db:
	${DOCKER} exec -i  ${CID} pg_createcluster -e ${DB_CHARSET} -d /var/db -p 5433 --start 9.3 main2
	${DOCKER} exec -i  ${CID} bash -c 'echo "host    all    all    0.0.0.0/0    md5" >> /etc/postgresql/9.3/main2/pg_hba.conf'
	${DOCKER} exec -i  ${CID} bash -c "echo listen_addresses = \\'*\\' >> /etc/postgresql/9.3/main2/postgresql.conf"
	${DOCKER} exec -i  ${CID} sudo -i -u postgres  createuser --port 5433 -r -l ${DB_USER}
	${DOCKER} exec -i  ${CID} pg_ctlcluster 9.3 main2 restart
	echo "ALTER USER ${DB_USER} WITH PASSWORD '${DB_PASS}'" | ${DOCKER} exec -i  ${CID} sudo -i -u postgres psql --port 5433
	${DOCKER} exec -i  ${CID} sudo -i -u postgres createdb --port 5433 -E ${DB_CHARSET} -T ${DB_TEMPLATE} -O ${DB_USER} ${DB_NAME}

wait_for_up:
	while true; do \
	    if [ "`echo "select 5;" | ${DOCKER} exec -i  ${CID} sudo -i -u postgres psql postgres | grep  "(1 row)" | wc -l`" == "1" ]; then \
		break; \
	    else \
		echo "Wait for database UP..."; \
		sleep 3; \
	    fi \
	done

reup:
	make stop
	make rm
	rm -rf /srv/postgresql-cnt/9.3-data/*
	make
