#!/bin/bash
#
set -e

ORACLE_SID="$(grep "$ORACLE_HOME" /etc/oratab | cut -d: -f1)"
if [ "$ORACLE_SID" == "XE" ]; then
  export ORACLE_PDB="XEPDB1"
else
  export ORACLE_PDB=${ORACLE_PDB:-ORCLPDB1}
fi

ORACLE_PDB=${ORACLE_PDB^^}
WALLET_LOC="${ORACLE_BASE}/oradata/dbconfig/${ORACLE_SID}/.tls-wallet"
TCPS_PORT=${TCPS_PORT:-2484}

function connect() {
  echo "exit;" | sqlplus -L -S system/$ORACLE_PWD  > /dev/null
}


function ensure_db_avaiability() {
  while true
  do
      if connect; then echo "exiting"; return 0; fi;
      echo "Failed to login into oracle database - retrying";
      sleep 4;
  done
  sleep 2
}


function configure_netservices() {
   echo -e "\n\nConfiguring Oracle Net service for TCPS...\n"
   echo "WALLET_LOCATION = (SOURCE = (METHOD = FILE)(METHOD_DATA = (DIRECTORY = $WALLET_LOC)))
SSL_CLIENT_AUTHENTICATION = TRUE" | tee -a "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/{sqlnet.ora,listener.ora} > /dev/null

   # Add listener for TCPS
   sed -i "/TCP/a\
\ \ \ \ (ADDRESS = (PROTOCOL = TCPS)(HOST = 0.0.0.0)(PORT = ${TCPS_PORT}))
" "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/listener.ora

  echo "SQLNET.AUTHENTICATION_SERVICES = (TCPS)" | tee -a "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/sqlnet.ora > /dev/null
}

function reconfigure_listener() {
  lsnrctl stop
  lsnrctl start
}

function disable_tcps() {
  sed -i -e '/WALLET_LOCATION/d' -e '/SSL_CLIENT_AUTHENTICATION/d' "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/{sqlnet,listener}.ora
  sed -i "/TCPS/d" "$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/listener.ora
  echo -e "\nReconfiguring the Listener...\n"
  reconfigure_listener
  rm -rf "$WALLET_LOC" "$CLIENT_WALLET_LOC"
}


function crearteTeleportWallet() {
  if [[ -f "/certs/server/cwallet.sso" ]]; then
    cp -R /certs/server $WALLET_LOC
    return
  fi
  PASS=$(cat /certs/tctl.result | grep -o "pkcs12pwd\ .*" | cut -d' ' -f2)
  orapki wallet create -wallet $WALLET_LOC -auto_login_only
  orapki wallet import_pkcs12 -wallet $WALLET_LOC -auto_login_only -pkcs12file /certs/server.p12 -pkcs12pwd $PASS
  orapki wallet add -wallet $WALLET_LOC -trusted_cert -auto_login_only -cert /certs/server.crt

}

ensure_db_avaiability
configure_netservices
crearteTeleportWallet
reconfigure_listener


cat <<EOF > /tmp/create_user.sql
GRANT CREATE SESSION TO alice;
exit;
EOF


ensure_db_avaiability
sqlplus system/$ORACLE_PWD @/tmp/create_user.sql

