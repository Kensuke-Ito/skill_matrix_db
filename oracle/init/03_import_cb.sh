#!/usr/bin/env bash
set -euo pipefail

echo "[init] Importing CB schema from /dumps/cb/cb.dmp"

if [[ -f /dumps/cb/EXPORT_SCHEMA.DMP ]]; then
  echo "[init] Data Pump dump detected: /dumps/cb/EXPORT_SCHEMA.DMP"

  sqlplus -s "sys/${ORACLE_PASSWORD}@//localhost:1521/XEPDB1 as sysdba" <<'SQL_EOF'
CREATE OR REPLACE DIRECTORY DPDIR_CB AS '/dumps/cb';
CREATE OR REPLACE DIRECTORY DPDIR_TMP AS '/tmp';
GRANT READ ON DIRECTORY DPDIR_CB TO SYSTEM;
GRANT READ, WRITE ON DIRECTORY DPDIR_TMP TO SYSTEM;
SQL_EOF

  impdp \
    "system/${ORACLE_PASSWORD}@//localhost:1521/XEPDB1" \
    directory=DPDIR_CB \
    dumpfile=EXPORT_SCHEMA.DMP \
    schemas=CB \
    exclude=OBJECT_GRANT \
    exclude=ROLE_GRANT \
    exclude=SYSTEM_GRANT \
    logfile=DPDIR_TMP:impdp_CB.log \
    metrics=y || true

  # Data Pump can finish with non-zero when optional grants fail. Guard with required-object existence.
  has_pkg_body=$(sqlplus -s "sys/${ORACLE_PASSWORD}@//localhost:1521/XEPDB1 as sysdba" <<'SQL_EOF'
set heading off feedback off pages 0 verify off
select count(*) from dba_objects
 where owner='CB' and object_name='CBP_PRMI_ACS_GET' and object_type='PACKAGE BODY';
exit
SQL_EOF
)
  has_pkg_body=$(echo "${has_pkg_body}" | tr -d '[:space:]')
  if [[ "${has_pkg_body}" != "1" ]]; then
    echo "[init][error] required object CB.CBP_PRMI_ACS_GET(PACKAGE BODY) is missing after impdp."
    echo "[init][error] See /tmp/impdp_CB.log"
    exit 1
  fi
elif [[ -f /dumps/cb/cb.dmp ]]; then
  if ! imp \
    "userid='sys/${ORACLE_PASSWORD}@localhost:1521/XEPDB1 as sysdba'" \
    file=/dumps/cb/cb.dmp \
    fromuser=CB \
    touser=CB \
    log=/tmp/imp_CB.log; then
    # imp can return non-zero for non-fatal import issues. Continue and re-apply core grants.
    echo "[init][warn] CB import returned non-zero. Continue to privilege reconciliation."
  fi

  # If export file is truncated/corrupt, import may finish with warnings but leave critical objects missing.
  if grep -Eq 'IMP-00009|IMP-00098' /tmp/imp_CB.log; then
    echo "[init][error] CB import log indicates broken dump (IMP-00009/IMP-00098)."
    echo "[init][error] Please replace /dumps/cb/cb.dmp and re-initialize DB."
    exit 1
  fi
else
  echo "[init] /dumps/cb/EXPORT_SCHEMA.DMP と /dumps/cb/cb.dmp の両方が見つからないため CB import をスキップします"
  exit 0
fi

sqlplus -s "sys/${ORACLE_PASSWORD}@//localhost:1521/XEPDB1 as sysdba" <<'SQL_EOF' || true
ALTER USER CB DEFAULT TABLESPACE USERS TEMPORARY TABLESPACE TEMP;
ALTER USER CB QUOTA UNLIMITED ON USERS;
GRANT CREATE SESSION TO CB;
GRANT EXECUTE ON DBMS_CRYPTO TO CB;
SQL_EOF