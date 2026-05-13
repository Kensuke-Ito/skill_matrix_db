-- (DBA か 権限あるユーザーで) ロール作成 
DROP ROLE caa_to_csg_role;

CREATE ROLE caa_to_csg_role;

BEGIN -- テーブル：DML一式（必要なものだけに絞るのが本当は理想） 
FOR r IN (
  SELECT
    owner,
    table_name AS object_name
  FROM
    all_tables
  WHERE
    owner = 'CAA'
) LOOP EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON ' || r.owner || '.' || r.object_name || ' TO caa_to_csg_role';

END LOOP;

-- ビュー：通常はSELECT（ビュー更新させたいなら INSERT/UPDATE/DELETE も検討） 
FOR r IN (
  SELECT
    owner,
    view_name AS object_name
  FROM
    all_views
  WHERE
    owner = 'CAA'
) LOOP EXECUTE IMMEDIATE 'GRANT SELECT ON ' || r.owner || '.' || r.object_name || ' TO caa_to_csg_role';

END LOOP;

-- シーケンス：SELECT 
FOR r IN (
  SELECT
    sequence_owner AS owner,
    sequence_name AS object_name
  FROM
    all_sequences
  WHERE
    sequence_owner = 'CAA'
) LOOP EXECUTE IMMEDIATE 'GRANT SELECT ON ' || r.owner || '.' || r.object_name || ' TO caa_to_csg_role';

END LOOP;

-- プロシージャ/ファンクション/パッケージ：EXECUTE 
FOR r IN (
  SELECT
    owner,
    object_name
  FROM
    all_objects
  WHERE
    owner = 'CAA'
    AND object_type IN ('PROCEDURE', 'FUNCTION', 'PACKAGE')
) LOOP EXECUTE IMMEDIATE 'GRANT EXECUTE ON ' || r.owner || '.' || r.object_name || ' TO caa_to_csg_role';

END LOOP;

END;

/ GRANT caa_to_csg_role TO CSG;