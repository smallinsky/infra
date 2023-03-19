## Teleport ClickHouse Testing Env

### Steps:
1) Create local env via executing `make`
    ```bash
    $ make
    Running Clickhouse docker
    docker run --rm -p 8443:8443 -p 8123:8123 --name clickhouse  \
      -v /Users/marek/infra/clickhouse/config.xml:/etc/clickhouse-server/config.xml       \
      -v /Users/marek/infra/clickhouse/users.xml:/etc/clickhouse-server/users.xml         \
      -v /Users/marek/infra/clickhouse/certs:/certs                                       \
      clickhouse/clickhouse-server
    Processing configuration file '/etc/clickhouse-server/config.xml'.
    Merging configuration file '/etc/clickhouse-server/config.d/docker_related_config.xml'.
    Logging trace to /var/log/clickhouse-server/clickhouse-server.log
    Logging errors to /var/log/clickhouse-server/clickhouse-server.err.log
    Processing configuration file '/etc/clickhouse-server/config.xml'.
    Merging configuration file '/etc/clickhouse-server/config.d/docker_related_config.xml'.
    Saved preprocessed configuration to '/var/lib/clickhouse/preprocessed_configs/config.xml'.
    Processing configuration file '/etc/clickhouse-server/users.xml'.
    Saved preprocessed configuration to '/var/lib/clickhouse/preprocessed_configs/users.xml'.
    ```
2) Add Teleport ClickHouse Teleprot resource:
    ```yaml
      databases:
      - name: "clickhouse"
        protocol: "clickhouse"
        uri: "localhost:8443"
        static_labels:
          env: dev
    ```
3) Run ClickHouse Teleport local proxy:
    ```bash
    $ tsh proxy db --db-user=alice clickhouse --tunnel -p 9999
    ```
4) Run ClickHouse query over HTTP protocol via CURL:
    ```bash
    echo 'SELECT event_time,initial_user,query FROM system.query_log' | curl 'http://localhost:9999/'  --data-binary @-
    ```
5) Connect with Datagrip GUI Client using jdbc clickhouse driver:
  ![datagrip-clickhouse](https://user-images.githubusercontent.com/22402974/226206085-34dcdded-7329-458d-8493-f9ed88346176.png)

