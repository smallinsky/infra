FROM container-registry.oracle.com/database/express:21.3.0-xe
ENV ORACLE_PWD=pass
COPY --chmod=777 *.sh /opt/oracle/
COPY --chmod=777 scripts/ /opt/oracle/scripts/startup/
COPY --chmod=777 certs/ /certs/
ENTRYPOINT ["/opt/oracle/entrypoint.sh"]

