-- CAA -> CSG 権限付与
BEGIN
  EXECUTE IMMEDIATE 'DROP ROLE caa_to_csg_role';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -1919 THEN
      RAISE;
    END IF;
END;
/

CREATE ROLE caa_to_csg_role;

BEGIN
  -- テーブル：DML一式
  FOR r IN (
    SELECT owner, table_name AS object_name
    FROM all_tables
    WHERE owner = 'CAA'
  ) LOOP
    EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON '
                      || r.owner || '.' || r.object_name || ' TO caa_to_csg_role';
  END LOOP;

  -- ビュー：SELECT
  FOR r IN (
    SELECT owner, view_name AS object_name
    FROM all_views
    WHERE owner = 'CAA'
  ) LOOP
    EXECUTE IMMEDIATE 'GRANT SELECT ON '
                      || r.owner || '.' || r.object_name || ' TO caa_to_csg_role';
  END LOOP;

  -- シーケンス：SELECT
  FOR r IN (
    SELECT sequence_owner AS owner, sequence_name AS object_name
    FROM all_sequences
    WHERE sequence_owner = 'CAA'
  ) LOOP
    EXECUTE IMMEDIATE 'GRANT SELECT ON '
                      || r.owner || '.' || r.object_name || ' TO caa_to_csg_role';
  END LOOP;

  -- プロシージャ/ファンクション/パッケージ：EXECUTE
  FOR r IN (
    SELECT owner, object_name
    FROM all_objects
    WHERE owner = 'CAA'
      AND object_type IN ('PROCEDURE', 'FUNCTION', 'PACKAGE')
  ) LOOP
    EXECUTE IMMEDIATE 'GRANT EXECUTE ON '
                      || r.owner || '.' || r.object_name || ' TO caa_to_csg_role';
  END LOOP;
END;
/

GRANT caa_to_csg_role TO CSG;

-- CSG への基本権限確保（dmp復元やスクリプト実行により権限が消える場合に備え）
ALTER USER CSG DEFAULT TABLESPACE USERS TEMPORARY TABLESPACE TEMP;
ALTER USER CSG QUOTA UNLIMITED ON USERS;
GRANT CREATE SESSION TO CSG;
GRANT DBA TO CSG;