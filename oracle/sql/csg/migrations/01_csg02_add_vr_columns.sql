WHENEVER SQLERROR CONTINUE

DECLARE
    v_count NUMBER := 0;
BEGIN
    SELECT COUNT(*)
      INTO v_count
            FROM dba_tab_cols
         WHERE owner = 'CSG'
             AND table_name = 'CSG02'
             AND column_name = 'VRTRNG';

    IF v_count = 0 THEN
                EXECUTE IMMEDIATE 'ALTER TABLE CSG.CSG02 ADD (VRTRNG NUMBER(1) DEFAULT 0)';
                EXECUTE IMMEDIATE q'[COMMENT ON COLUMN CSG.CSG02.VRTRNG IS 'VRトレーニング(0:未チェック 1:チェック済 2:承認済み)']';
    END IF;
END;
/

DECLARE
    v_count NUMBER := 0;
BEGIN
    SELECT COUNT(*)
      INTO v_count
            FROM dba_tab_cols
         WHERE owner = 'CSG'
             AND table_name = 'CSG02'
             AND column_name = 'DYVRTRNG';

    IF v_count = 0 THEN
                EXECUTE IMMEDIATE 'ALTER TABLE CSG.CSG02 ADD (DYVRTRNG VARCHAR2(14))';
                EXECUTE IMMEDIATE q'[COMMENT ON COLUMN CSG.CSG02.DYVRTRNG IS 'VRトレーニング日時']';
    END IF;
END;
/

EXIT
