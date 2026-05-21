-- CAA -> CB 権限付与
BEGIN
  EXECUTE IMMEDIATE 'DROP ROLE cb_to_caa_role';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -1919 THEN
      RAISE;
    END IF;
END;
/

CREATE ROLE cb_to_caa_role;

BEGIN
  -- テーブル：DML一式
  FOR r IN (
    SELECT owner, table_name AS object_name
    FROM all_tables
    WHERE owner = 'CB'
  ) LOOP
    EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON '
                      || r.owner || '.' || r.object_name || ' TO cb_to_caa_role';
  END LOOP;

  -- ビュー：SELECT
  FOR r IN (
    SELECT owner, view_name AS object_name
    FROM all_views
    WHERE owner = 'CB'
  ) LOOP
    EXECUTE IMMEDIATE 'GRANT SELECT ON '
                      || r.owner || '.' || r.object_name || ' TO cb_to_caa_role';
  END LOOP;

  -- シーケンス：SELECT
  FOR r IN (
    SELECT sequence_owner AS owner, sequence_name AS object_name
    FROM all_sequences
    WHERE sequence_owner = 'CB'
  ) LOOP
    EXECUTE IMMEDIATE 'GRANT SELECT ON '
                      || r.owner || '.' || r.object_name || ' TO cb_to_caa_role';
  END LOOP;

  -- プロシージャ/ファンクション/パッケージ：EXECUTE
  FOR r IN (
    SELECT owner, object_name
    FROM all_objects
    WHERE owner = 'CB'
      AND object_type IN ('PROCEDURE', 'FUNCTION', 'PACKAGE')
  ) LOOP
    EXECUTE IMMEDIATE 'GRANT EXECUTE ON '
                      || r.owner || '.' || r.object_name || ' TO cb_to_caa_role';
  END LOOP;
END;
/

GRANT cb_to_caa_role TO CAA;

-- 型の権限
GRANT EXECUTE ON CB.CBM_USR_TABLE TO CAA;
GRANT EXECUTE ON CB.CBV_SECG_TABLE TO CAA;
GRANT EXECUTE ON CB.CONST TO CAA;
GRANT SELECT ON CB.CBM_USR TO CAA;
GRANT SELECT ON CB.CBT_USRATTRINF TO CAA;
GRANT SELECT ON CB.CBM_AUTH TO CAA;
GRANT EXECUTE ON CB.CBM_SSKMEM_TABLE TO CAA;
GRANT SELECT ON CB.CBV_SECG TO CAA;
GRANT SELECT ON CB.CBM_SSKKSI TO CAA;
GRANT EXECUTE ON CB.TYPE_CBM_USR TO CAA;
GRANT EXECUTE ON CB.CBP_SSKKNR_SSK_GET TO CAA;
GRANT SELECT ON CB.CBM_USRKBN TO CAA;
GRANT SELECT ON CB.CBM_LGIN TO CAA;
GRANT SELECT ON CB.CBT_CSTMINF TO CAA;
GRANT SELECT ON CB.CBT_PRMI TO CAA;
GRANT EXECUTE ON CB.CBP_PRMI_ACS_GET TO CAA;