#!/usr/bin/env bash
set -euo pipefail

ORACLE_HOST="${ORACLE_HOST:-localhost}"
ORACLE_PORT="${ORACLE_PORT:-1521}"
ORACLE_SERVICE="${ORACLE_SERVICE:-XEPDB1}"

SYSDBA_CONN="sys/${ORACLE_PASSWORD}@//${ORACLE_HOST}:${ORACLE_PORT}/${ORACLE_SERVICE} as sysdba"
CSG_CONN="CSG/CSG@//${ORACLE_HOST}:${ORACLE_PORT}/${ORACLE_SERVICE}"

CSG_ROOT="/sql/csg/DBScript"
CSG_DATA_ROOT="/sql/csg/data"

echo "[init] Executing CSG scripts"

RUN_FILE=/tmp/run_csg.sql
{
	echo "WHENEVER SQLERROR CONTINUE"
} > "${RUN_FILE}"

ADDED_SQL_COUNT=0

append_sql_file() {
	local file="$1"
	if [[ -f "$file" ]]; then
		echo "@${file}" >> "${RUN_FILE}"
		ADDED_SQL_COUNT=$((ADDED_SQL_COUNT + 1))
	fi
}

append_sql_dir() {
	local dir="$1"
	[[ -d "$dir" ]] || return 0

	# TABLE は手順に合わせて CSG*/CSGM* を先に実行する
	if [[ "$dir" == "${CSG_ROOT}/TABLE" ]]; then
		for file in "$dir"/CSG*.sql "$dir"/CSG*.SQL; do
			append_sql_file "$file"
		done
		for file in "$dir"/*.sql "$dir"/*.SQL; do
			local base
			base="$(basename "$file")"
			if [[ "$base" == CSG* ]]; then
				continue
			fi
			append_sql_file "$file"
		done
		return 0
	fi

	# slim イメージに find が存在しないため glob で代替（*.sql と *.SQL を両方処理）
	for file in "$dir"/*.sql "$dir"/*.SQL; do
		append_sql_file "$file"
	done
}

append_sql_dir "${CSG_ROOT}/TABLE"
append_sql_dir "${CSG_ROOT}/SEQUENCE"
append_sql_dir "${CSG_ROOT}/FUNCTION"
append_sql_dir "${CSG_ROOT}/VIEW"
append_sql_dir "${CSG_ROOT}/INDEX"
append_sql_dir "${CSG_ROOT}/TRIGGER"
append_sql_dir "${CSG_ROOT}/SYNONYM"
append_sql_dir "${CSG_DATA_ROOT}"

if [[ ${ADDED_SQL_COUNT} -eq 0 ]]; then
	echo "[init] 実行対象SQLが見つからないため CSGスクリプト実行をスキップします"
	exit 0
fi

echo "EXIT" >> "${RUN_FILE}"

# 08_exec_csg_scripts.sh の実行前に SYS で CSG の基本権限を保証
sqlplus -s "${SYSDBA_CONN}" <<SQL_ENSURE_CSG || true
ALTER USER CSG DEFAULT TABLESPACE USERS TEMPORARY TABLESPACE TEMP;
ALTER USER CSG QUOTA UNLIMITED ON USERS;
GRANT CREATE SESSION TO CSG;
GRANT DBA TO CSG;
EXIT
SQL_ENSURE_CSG

# CSG スクリプト実行
sqlplus -s "${CSG_CONN}" @"${RUN_FILE}" || true