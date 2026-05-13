#!/usr/bin/env bash
set -euo pipefail

CSG_ROOT="/sql/csg/DBScript"

if [[ ! -d "${CSG_ROOT}" ]]; then
	echo "[init] ${CSG_ROOT} が見つからないため CSGスクリプト実行をスキップします"
	exit 0
fi

echo "[init] Executing CSG DB scripts from ${CSG_ROOT}"

RUN_FILE=/tmp/run_csg.sql
{
	echo "WHENEVER SQLERROR CONTINUE"
} > "${RUN_FILE}"

append_sql_dir() {
	local dir="$1"
	if [[ -d "$dir" ]]; then
		while IFS= read -r file; do
			echo "@${file}" >> "${RUN_FILE}"
		done < <(find "$dir" -maxdepth 1 -type f \( -iname '*.sql' \) | sort)
	fi
}

append_sql_dir "${CSG_ROOT}/TABLE"
append_sql_dir "${CSG_ROOT}/SEQUENCE"
append_sql_dir "${CSG_ROOT}/FUNCTION"
append_sql_dir "${CSG_ROOT}/VIEW"
append_sql_dir "${CSG_ROOT}/INDEX"
append_sql_dir "${CSG_ROOT}/TRIGGER"
append_sql_dir "${CSG_ROOT}/SYNONYM"

echo "EXIT" >> "${RUN_FILE}"

sqlplus -s "CSG/CSG@//localhost:1521/XEPDB1" @"${RUN_FILE}" || true