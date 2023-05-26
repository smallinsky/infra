up: | certs
	@echo "Running Clickhouse docker"
	docker run --rm -p 8443:8443 -p 8123:8123 -p 9000:9000 -p 9440:9440 --name clickhouse  \
	-v $(PWD)/config.xml:/etc/clickhouse-server/config.xml       \
	-v $(PWD)/users.xml:/etc/clickhouse-server/users.xml         \
	-v $(PWD)/certs:/certs                                       \
	clickhouse/clickhouse-server:latest

down:
	docker kill clickhouse

certs:
	@echo "Generating Server certs"
	mkdir -p $@
	tctl auth sign --format=db --host=localhost --out=certs/server --ttl=2190h 

.PHONY: clean
clean:
	rm -rf certs
