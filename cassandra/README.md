### Docker compose Cassandra setup


#### Create Cassandra config and generate Teleport Cassandra certs
Make sure that you are login into Teleport cluster with a user that has right permission to sign database credential by running the `tctl auth sign`

Run
```sh
cd cassandra
./bootstrap.sh
```



#### Starting cassandra container: 
```sh
docker-compose -f docker-compose.yaml up
```


#### Adding Cassandra database to Teleport config:
```
db_service:
  enabled: true
  databases:
  - name: "cassandra"
    protocol: "cassandra"
    uri: "localhost:9042"
```



#### Connecting to Cassandra DB
If you don't have yet cqlsh Cassandra client installed in our env you can install it by running following commnad:
```bash
brew install cassandra
```


```sh
tsh db connect --db-user=cassandra cassandra
Password:
```

and use the default docker cassandra password: `cassandra` to connect to cassandra database