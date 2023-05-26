## Teleport ClickHouse Testing Env

### Steps:
1) Generate ClickHouse Server certs (You need to be logged into Teleport cluster)
    ```bash
    $ make certs
    Generating Server certs
    mkdir -p certs
    tctl auth sign --format=db --host=localhost --out=certs/server --ttl=2190h
    Database credentials have been written to certs/server.key, certs/server.crt, certs/server.cas.

    To enable mutual TLS on your PostgreSQL server, add the following to its postgresql.conf configuration file:

    ssl = on
    ssl_cert_file = '/path/to/certs/server.crt'
    ssl_key_file = '/path/to/certs/server.key'
    ssl_ca_file = '/path/to/certs/server.cas'

    To enable mutual TLS on your MySQL server, add the following to its mysql.cnf configuration file:

    [mysqld]
    require_secure_transport=ON
    ssl-cert=/path/to/certs/server.crt
    ssl-key=/path/to/certs/server.key
    ssl-ca=/path/to/certs/server.cas
    ```
2) Starting ClickHouse Server
    ```bash
    $ make up
    Running Clickhouse docker
    docker run --rm -p 8443:8443 -p 8123:8123 -p 9000:9000 -p 9440:9440 --name clickhouse  \
    -v /Users/marek/infra/clickhouse/config.xml:/etc/clickhouse-server/config.xml       \
    -v /Users/marek/infra/clickhouse/users.xml:/etc/clickhouse-server/users.xml         \
    -v /Users/marek/infra/clickhouse/certs:/certs                                       \
    clickhouse/clickhouse-server:latest
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
3) Add Teleport ClickHouse Teleport resource:
    ```yaml
    databases:
    - name: "clickhouse-http"
      protocol: "clickhouse-http"
      uri: "https://localhost:8443"
      static_labels:
      env: dev
    - name: "clickhouse-native"
      protocol: "clickhouse"
      uri: "clickhouse://localhost:9440"
      static_labels:
      env: dev
    ```
4) Install Native ClickHouse Client:
    ```bash
    brew install altinity/clickhouse/clickhouse
    ```
5) Connect to `clickhouse-native` DB using ClickHouse Native Protocol by CLI:
    ```bash
    $ tsh db connect --db-name=alice clickhouse-native
    ClickHouse client version 22.7.2.1.
    Connecting to localhost:49329 as user default.
    Connected to ClickHouse server version 23.4.2 revision 54462.

    ClickHouse client version is older than ClickHouse server. It may lack support for new features.

    Warnings:
    * Table system.session_log is enabled. It's unreliable and may contain garbage. Do not use it for any kind of security monitoring.

    5e8565b224d2 :) select event_time,initial_user,query from system.query_log

    ```
6) Connect With HTTP Client:
    * Start Local Proxy
       ```bash
       $ tsh proxy db --db-user=alice clickhouse-http  -p 9999 --tunnel
       ```
    * Run ClickHouse query over HTTP protocol via CURL:
        ```bash
        $ echo 'SELECT event_time,initial_user,query FROM system.query_log' | curl 'http://localhost:9999/'  --data-binary @-
        ```
    * Connect with Datagrip GUI Client using jdbc clickhouse driver:
      ![datagrip-clickhouse](https://user-images.githubusercontent.com/22402974/226206085-34dcdded-7329-458d-8493-f9ed88346176.png)

