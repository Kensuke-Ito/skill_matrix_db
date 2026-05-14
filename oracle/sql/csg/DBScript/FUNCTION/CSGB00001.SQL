CREATE OR REPLACE FUNCTION CSG.CSGB00001 RETURN NUMERIC IS 
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    INSERT 
            INTO CSG01( 
                SYAIN
                , YEAR
                , LC_CD
                , CLS_CD
                , MDL_CD
                , STATUS
                , DYSET
                , DYUPD
                , USRSET
                , USRUPD
                , PRGUPD
            ) 
            SELECT
                EmpCodes.SYAIN
                , TO_CHAR(SYSDATE, 'YYYY')+1
                , m20.LC_CD
                , m20.CLS_CD
                , m20.MDL_CD
                , 1
                , TO_CHAR(SYSDATE, 'YYYMMDDHH24MISS')
                , TO_CHAR(SYSDATE, 'YYYMMDDHH24MISS')
                , 'BATCH'
                , 'BATCH'
                , 'BATCH' 
            FROM
                ( 
                    SELECT
                        SYAIN 
                    FROM
                        ( 
                            SELECT
                                BUSYONO
                                , SYAIN 
                            FROM
                                CSGM04 
                            UNION ALL 
                            SELECT
                                BUSYONO
                                , SYAIN 
                            FROM
                                CSGM05
                        ) SYAIN_MST 
                    WHERE
                        EXISTS ( 
                            SELECT
                                BUSYONO 
                            FROM
                                CSG04 
                            WHERE
                                CRTMETHOD = 1 
                                AND DYEXE IS NOT NULL 
                                AND TO_CHAR(SYSDATE, 'mmdd') = DYEXE 
                                AND SYAIN_MST.BUSYONO = CSG04.BUSYONO
                                
                        ) 
                        AND NOT EXISTS ( 
                            SELECT
                                SYAIN 
                            FROM
                                CSG01 
                            WHERE
                                CSG01.YEAR = TO_CHAR(SYSDATE, 'YYYY') +1
                                AND SYAIN_MST.SYAIN = CSG01.SYAIN
                        )
                ) EmpCodes 
                CROSS JOIN CSGM20 m20 
            GROUP BY
                EmpCodes.SYAIN
                , m20.LC_CD
                , m20.CLS_CD
                , m20.MDL_CD 
            ORDER BY
                SYAIN;
    COMMIT; 
    return 0;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    return 1;
END CSGB00001;
/
