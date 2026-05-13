#!/usr/bin/env bash
set -euo pipefail

echo "[init] Importing CB schema from /dumps/cb/cb.dmp"

if [[ ! -f /dumps/cb/cb.dmp ]]; then
  echo "[init] /dumps/cb/cb.dmp が見つからないため CB import をスキップします"
  exit 0
fi

imp \
  "userid='sys/${ORACLE_PASSWORD}@localhost:1521/XEPDB1 as sysdba'" \
  file=/dumps/cb/cb.dmp \
  fromuser=CB \
  touser=CB \
  log=/tmp/imp_CB.log