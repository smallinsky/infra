up: | certs
	@echo "Running Oracle docker"
	docker run  --rm --name oracle-db -p 1521:1521  -p 2484:2484  \
		--entrypoint=/opt/oracle/entrypoint.sh \
		-e ENABLE_TCPS=false -e ORACLE_PWD=pass \
		-v ${PWD}/certs:/certs \
		-v ${PWD}/scripts:/opt/oracle/scripts/startup  \
		-v ${PWD}/setupTcpsCustom.sh:/opt/oracle/setupTcpsCustom.sh \
		-v ${PWD}/entrypoint.sh:/opt/oracle/entrypoint.sh \
		container-registry.oracle.com/database/express:21.3.0-xe

down:
	docker kill oracle-db

certs:
	@echo "Generating Server certs"
	mkdir -p $@
	tctl  auth sign --format=oracle --host=localhost --out=certs/server --ttl=2190h | tee certs/tctl.result


.PHONY: clean
clean:
	rm -rf certs


.PHONY: build
build: certs
	docker build  --no-cache -t teleport-oracle-test .

.PHONY: up-custom
up-custom:
	docker run -it --rm -p 1521:1521 -p 2484:2484 \
        -e ENABLE_TCPS=false -e ORACLE_PWD=pass \
        --entrypoint=/opt/oracle/entrypoint.sh \
     teleport-oracle-test
