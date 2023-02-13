## Teleport Oracle Testing Env

### Steps: 
1) Get access to oracle official docker repository [container-registry.oracle](https://container-registry.oracle.com/ords/f?p=113:10::::::)
2) `docker login container-registry.oracle.com`
3) `docker pull container-registry.oracle.com/database/express:21.3.0-xe`
4) `make certs`
5) `make oracle`
6) The TCPS listener setup takes a while ~2 min.
7) For local CLI client install: 
    ```bash
        brew install --cask sqlcl 
        # Add sql to your #PATH variable
        export PATH=$PATH:/usr/local/Caskroom/sqlcl/22.4.0.342.1212/sqlcl/bin
    ```
8) Add Teleport Oracle resource:
    ```yaml
      databases:
      - name: "oracle"
        protocol: "oracle"
        uri: "localhost:2484"
        static_labels:
          env: dev
    ```
9) Connect from CLI:
    ```bash
    $ tsh db connect --db-user=alice --db-name=XE oracle


    SQLcl: Release 22.4 Production on Fri Mar 17 13:59:32 2023

    Copyright (c) 1982, 2023, Oracle.  All rights reserved.

    Connected to:
    Oracle Database 21c Express Edition Release 21.0.0.0.0 - Production
    Version 21.3.0.0.0

    SQL>

    ```
10) Connect from GUI client:
    ```bash
    $ tsh proxy db oracle --tunnel
    Started authenticated tunnel for the Oracle database "oracle" in cluster "ice-berg.dev" on 127.0.0.1:51060.
    To avoid port randomization, you can choose the listening port using the --port flag.

    Use the following command to connect to the Oracle database server using CLI:
    $ sql -L jdbc:oracle:thin:@tcps://localhost:51060/XE?TNS_ADMIN=/Users/marek/.tsh/keys/ice-berg.dev/marek-db/ice-berg.dev/oracle-wallet

    or using following Oracle JDBC connection string in order to connect with other GUI/CLI clients:
    jdbc:oracle:thin:@tcps://localhost:51060/XE?TNS_ADMIN=/Users/marek/.tsh/keys/ice-berg.dev/marek-db/ice-berg.dev/oracle-wallet
    ```
