ALTER SESSION SET "_ORACLE_SCRIPT"=true;  
CREATE USER alice IDENTIFIED EXTERNALLY AS 'CN=alice';
GRANT CREATE SESSION TO alice;
GRANT CREATE SESSION TO alice;
GRANT CREATE PROCEDURE TO alice;
GRANT CREATE VIEW TO alice;
GRANT CREATE TABLE TO alice;
GRANT CREATE SEQUENCE TO alice;
GRANT CREATE TRIGGER TO alice;
