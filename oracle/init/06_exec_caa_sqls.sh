#!/usr/bin/env bash
set -euo pipefail

echo "[init] Importing CAA schema"

if [[ -f /dumps/caa/EXPORT_SCHEMA.DMP ]]; then
	echo "[init] Data Pump dump detected for CAA import: /dumps/caa/EXPORT_SCHEMA.DMP"

	sqlplus -s "sys/${ORACLE_PASSWORD}@//localhost:1521/XEPDB1 as sysdba" <<SQL_EOF
CREATE OR REPLACE DIRECTORY DPDIR_CAA AS '/dumps/caa';
CREATE OR REPLACE DIRECTORY DPDIR_TMP AS '/tmp';
GRANT READ ON DIRECTORY DPDIR_CAA TO SYSTEM;
GRANT READ, WRITE ON DIRECTORY DPDIR_TMP TO SYSTEM;
SQL_EOF

	impdp \
		"system/${ORACLE_PASSWORD}@//localhost:1521/XEPDB1" \
		directory=DPDIR_CAA \
		dumpfile=EXPORT_SCHEMA.DMP \
		schemas=CAA \
		exclude=OBJECT_GRANT \
		exclude=ROLE_GRANT \
		exclude=SYSTEM_GRANT \
		logfile=DPDIR_TMP:impdp_CAA.log \
		metrics=y || true
elif [[ -f /dumps/cb/EXPORT_SCHEMA.DMP ]]; then
	echo "[init] Data Pump dump detected for CAA import (shared dump): /dumps/cb/EXPORT_SCHEMA.DMP"

	sqlplus -s "sys/${ORACLE_PASSWORD}@//localhost:1521/XEPDB1 as sysdba" <<SQL_EOF
CREATE OR REPLACE DIRECTORY DPDIR_CB AS '/dumps/cb';
CREATE OR REPLACE DIRECTORY DPDIR_TMP AS '/tmp';
GRANT READ ON DIRECTORY DPDIR_CB TO SYSTEM;
GRANT READ, WRITE ON DIRECTORY DPDIR_TMP TO SYSTEM;
SQL_EOF

	impdp \
		"system/${ORACLE_PASSWORD}@//localhost:1521/XEPDB1" \
		directory=DPDIR_CB \
		dumpfile=EXPORT_SCHEMA.DMP \
		schemas=CAA \
		exclude=OBJECT_GRANT \
		exclude=ROLE_GRANT \
		exclude=SYSTEM_GRANT \
		logfile=DPDIR_TMP:impdp_CAA.log \
		metrics=y || true
elif [[ -f /dumps/caa/caa.dmp ]]; then
	echo "[init] legacy imp dump detected for CAA import: /dumps/caa/caa.dmp"

	imp \
		"userid='sys/${ORACLE_PASSWORD}@localhost:1521/XEPDB1 as sysdba'" \
		file=/dumps/caa/caa.dmp \
		fromuser=CAA \
		touser=CAA \
		log=/tmp/imp_CAA.log

	# imp がユーザー定義を上書きして権限を消去する場合に備え、再付与
	sqlplus -s "sys/${ORACLE_PASSWORD}@//localhost:1521/XEPDB1 as sysdba" <<SQL_EOF || true
ALTER USER CAA DEFAULT TABLESPACE USERS TEMPORARY TABLESPACE TEMP;
ALTER USER CAA QUOTA UNLIMITED ON USERS;
GRANT DBA TO CAA;
GRANT CREATE SESSION TO CAA;
EXIT
SQL_EOF
else
	echo "[init] /dumps/caa/EXPORT_SCHEMA.DMP, /dumps/cb/EXPORT_SCHEMA.DMP, /dumps/caa/caa.dmp が見つからないため CAA import をスキップします"
fi

echo "[init] Executing CAA SQL scripts"

CAA1_FILE=""
if [[ -f /sql/caa/CAA1.sql ]]; then
	CAA1_FILE="/sql/caa/CAA1.sql"
elif [[ -f /sql/caa/CAA1.SQL ]]; then
	CAA1_FILE="/sql/caa/CAA1.SQL"
fi

CAA2_FILE=""
if [[ -f /sql/caa/CAA2.SQL ]]; then
	CAA2_FILE="/sql/caa/CAA2.SQL"
elif [[ -f /sql/caa/CAA2.sql ]]; then
	CAA2_FILE="/sql/caa/CAA2.sql"
fi

CAA3_FILE=""
if [[ -f /sql/caa/CAA3.SQL ]]; then
	CAA3_FILE="/sql/caa/CAA3.SQL"
elif [[ -f /sql/caa/CAA3.sql ]]; then
	CAA3_FILE="/sql/caa/CAA3.sql"
fi

RUN_FILE=/tmp/run_caa.sql
{
	echo "WHENEVER SQLERROR CONTINUE"
	if [[ -n "${CAA1_FILE}" ]]; then
		echo "@${CAA1_FILE}"
	else
		echo "PROMPT [warn] CAA1 が見つかりません。"
	fi

	if [[ -n "${CAA2_FILE}" ]]; then
		echo "@${CAA2_FILE}"
		echo "@${CAA2_FILE}"
	else
		echo "PROMPT [warn] CAA2 が見つかりません。"
	fi

	if [[ -n "${CAA3_FILE}" ]]; then
		echo "@${CAA3_FILE}"
	else
		echo "PROMPT [warn] CAA3 が見つかりません。"
	fi

	echo "EXIT"
} > "${RUN_FILE}"

sqlplus -s "CAA/CAA@//localhost:1521/XEPDB1" @"${RUN_FILE}" || true

echo "[init] Reconcile CAA grants from CB after CAA import"
sqlplus -s "sys/${ORACLE_PASSWORD}@//localhost:1521/XEPDB1 as sysdba" @/container-entrypoint-initdb.d/05_exec_caa_to_cb.sql || true

echo "[init] Compile CAA dependent objects"
sqlplus -s "sys/${ORACLE_PASSWORD}@//localhost:1521/XEPDB1 as sysdba" <<'SQL_COMPILE_CAA' || true
ALTER VIEW CAA.CBV_USRINF COMPILE;
ALTER VIEW CAA.CBV_USRINF2 COMPILE;
ALTER PACKAGE CAA.CAP_AUTH_GET COMPILE BODY;
EXIT
SQL_COMPILE_CAA