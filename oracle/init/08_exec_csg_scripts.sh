#!/bin/bash
set +e

echo "Executing CSG DB scripts..."

sqlplus CSG/********@XE <<EOF
WHENEVER SQLERROR CONTINUE

-- TABLE
@/sql/csg/DBScript/TABLE/CSG**.sql
@/sql/csg/DBScript/TABLE/CSGM**.sql
@/sql/csg/DBScript/TABLE/ADD_COLUMN.sql

-- SEQUENCE
@/sql/csg/DBScript/SEQUENCE/*.sql

-- FUNCTION
@/sql/csg/DBScript/FUNCTION/*.sql

-- VIEW
@/sql/csg/DBScript/VIEW/*.sql

-- INDEX（エラー出る想定）
@/sql/csg/DBScript/INDEX/*.sql

-- TRIGGER（BIN$wrl～エラー無視）
@/sql/csg/DBScript/TRIGGER/*.sql

-- SYNONYM
@/sql/csg/DBScript/SYNONYM/*.sql

EXIT
EOF