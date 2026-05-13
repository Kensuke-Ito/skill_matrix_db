#!/bin/bash
set +e   # エラーが出ても止めない

echo "Executing CAA SQL scripts..."

sqlplus system/oracle@XE <<EOF
WHENEVER SQLERROR CONTINUE

-- CAA1.sql
@/sql/caa/CAA1.sql
-- VIEW作成エラーは無視してOK

-- CAA2.sql（1回目）
@/sql/caa/CAA2.sql

-- CAA2.sql（2回目）
@/sql/caa/CAA2.sql
-- パッケージ系エラーは無視
-- PACKAGE / PACKAGE BODY エラー想定

-- CAA3.sql
@/sql/caa/CAA3.sql

EXIT
EOF