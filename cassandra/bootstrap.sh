
#!/usr/bin/env bash
set -eo pipefail

mkdir -p certs
tctl auth sign --format=cassandra --host=localhost,127.0.0.1,cassandra --out=certs/cassandra --ttl=2190h > tctl.result
password=$(cat tctl.result | grep keystore_password | cut -d \" -f2)



cat <<EOF > cassandra-auth.yaml
client_encryption_options:
   enabled: true
   optional: false
   keystore: /certs/cassandra.keystore
   keystore_password: "${password}"

   require_client_auth: true
   truststore: /certs/cassandra.truststore
   truststore_password: "${password}"
   protocol: TLS
   algorithm: SunX509
   store_type: JKS
   cipher_suites: [TLS_RSA_WITH_AES_256_CBC_SHA]
EOF

[ -e file ] && rm cassandra-tel.yaml
cat cassandra.yaml cassandra-auth.yaml > cassandra-config.yaml
