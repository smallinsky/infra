.PHONY: certs
certs:
	mkdir -p $@
	tctl  auth sign --format=oracle --host=localhost --out=certs/server --ttl=2190h | tee certs/tctl.result

.PHONY: oracle
oracle: 
	docker run  --rm --name oracle-db -p 1521:1521  -p 2484:2484  \
		--entrypoint=/opt/oracle/entrypoint.sh \
		-e ENABLE_TCPS=true -e ORACLE_PWD=pass \
		-v ${PWD}/certs:/certs \
		-v ${PWD}/scripts:/opt/oracle/scripts/startup  \
		-v ${PWD}/setupTcps.sh:/opt/oracle/configTcps.sh \
		-v ${PWD}/entrypoint.sh:/opt/oracle/entrypoint.sh \
		container-registry.oracle.com/database/express:21.3.0-xe

.PHONY: clean
clean:
	rm -rf certs
