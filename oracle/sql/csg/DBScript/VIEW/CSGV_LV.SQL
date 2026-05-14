CREATE OR REPLACE VIEW CSGV_LV
    (MDL_CD,WRK_CD,LV,REQNUM)
AS
WITH LV_LIST(LV) AS(
    SELECT 0 
    FROM DUAL
    UNION ALL
    SELECT LV + 1
    FROM LV_LIST
    WHERE LV < 100
)

SELECT MDL_CD, WRK_CD, LV, MAX(REQNUM) AS REQNUM
FROM (
    SELECT LV_LIST.LV,X.MDL_CD, X.WRK_CD, X.REQNUM FROM (
        SELECT 
            mlv.MDL_CD
            ,X.MAX_LV
            ,mlv.LV
            ,mlv.WRK_CD
            ,mlv.REQNUM
        FROM (
            SELECT MDL_CD, WRK_CD, LV , MAX(REQNUM) AS REQNUM
            FROM (
                SELECT MDL_CD, WRK_CD, LV, REQNUM
                FROM CSGM22
                WHERE DELFLG <> '9'
                
                /*
                UNION ALL 
                SELECT MDL_CD, WRK_CD, 1 AS LV, 0 AS REQNUM
                FROM CSGM22
                GROUP BY MDL_CD, WRK_CD
                --*/
                --/*
                UNION ALL 
                SELECT MDL_CD, WRK_CD, 0 AS LV, 0 AS REQNUM
                FROM CSGM22
                GROUP BY MDL_CD, WRK_CD
                --*/
            ) X
            GROUP BY MDL_CD, WRK_CD, LV 
        ) mlv
        INNER JOIN (
            SELECT MDL_CD, MAX(LV) AS MAX_LV
            FROM CSGM22
            WHERE DELFLG <> '9'
            GROUP BY MDL_CD
        ) X
        ON
        mlv.MDL_CD = X.MDL_CD
    ) X
    left JOIN LV_LIST
    ON LV_LIST.LV <= X.MAX_LV
    where LV_LIST.lv  >= x.lv
) X
GROUP BY MDL_CD, WRK_CD, LV
ORDER BY MDL_CD, LV, WRK_CD
/
