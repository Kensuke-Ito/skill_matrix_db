CREATE MATERIALIZED VIEW CBV_USRINF2_OLD
PCTFREE 10
MAXTRANS 255
TABLESPACE USERS
STORAGE(INITIAL 64K NEXT 1M MINEXTENTS 1 MAXEXTENTS 2147483645)
NOCACHE
LOGGING
REFRESH COMPLETE ON DEMAND
AS
SELECT 
 USR.USRSEQ AS USRSEQ,
 USR.USRKBN AS USRKBN,
 USR.MAIL AS MAIL,
 USR.USRNM AS USRNM,
 USR.SYKIID AS SYKIID,
 USR.SYKMID AS SYKMID,
 USR.DELFLG AS DELFLG,
 DPMT.VAL AS DPMTNM,
 DPCD.VAL AS DPMTCD,
 EPCD.VAL AS USRID
FROM 
 CBM_USR USR
 LEFT JOIN (
  SELECT
   USRSEQ,
   VAL
  FROM
   CBT_USRATTRINF
  WHERE
   KEY = 'CBUA_USR_DPMT'
 ) DPMT ON DPMT.USRSEQ = USR.USRSEQ
 LEFT JOIN (
  SELECT
   USRSEQ,
   VAL
  FROM
   CBT_USRATTRINF
  WHERE
   KEY = 'CBUA_USR_DPCD'
 ) DPCD ON DPCD.USRSEQ = USR.USRSEQ
 LEFT JOIN (
  SELECT
   USRSEQ,
   (CASE WHEN VAL IS NULL THEN NULL
   ELSE 'C' || VAL
   END) AS VAL
  FROM
   CBT_USRATTRINF
  WHERE
   KEY = 'CBUA_USR_EPCD'
 ) EPCD ON EPCD.USRSEQ = USR.USRSEQ
/
CREATE OR REPLACE PACKAGE CAAP0001
IS
	-- PLSQL のプログラムID
	PROGRAM_ID				CONSTANT VARCHAR2(20) := 'CAAP0001';

	UserException			EXCEPTION;

	--LMMM101で管理されるO-PROの作番ID
	O_PRO_SAKUID			CONSTANT VARCHAR2(10) := '0000000001';
	--手動設定時の値
	HNDFLG					CONSTANT NUMBER(1) := 1;

	--戻り値用
	TYPE AUTHUSR_TYPE is RECORD
	(
		USERID		SAKU_USR.USERID%type
	);
	TYPE REC_AUTHUSR IS TABLE OF AUTHUSR_TYPE;

	--閲覧権限更新
	PROCEDURE UPDATE_USERAUTH;

	--閲覧権限取得
	FUNCTION GET_KENKBN
	(
		a_BKNCD			IN	VARCHAR2 := NULL
		,a_PWBS			IN	VARCHAR2 := NULL
	)
	RETURN REC_AUTHUSR PIPELINED;

	--金額権限取得
	FUNCTION GET_MONEYKENKBN
	(
		a_BKNCD			IN	VARCHAR2 := NULL
		,a_PWBS			IN	VARCHAR2 := NULL
	)
	RETURN REC_AUTHUSR PIPELINED;

	--権限取得関数
	FUNCTION GET_AUTHUSR
	(
		a_CLMNM			IN	VARCHAR2 := NULL
		,a_BKNCD		IN	VARCHAR2 := NULL
		,a_PWBS			IN	VARCHAR2 := NULL
	)
	RETURN REC_AUTHUSR PIPELINED;

END;
/
CREATE OR REPLACE PACKAGE CAAP0002
IS
	-- PLSQL のプログラムID
	PROGRAM_ID				CONSTANT VARCHAR2(20) := 'CAAP0002';

	UserException			EXCEPTION;
	
	--テーブル転送処理
	PROCEDURE TRANSFER_TABLE
	(
		a_BASETABLE		IN	VARCHAR2
		,a_TARGETTABLE	IN	VARCHAR2
	);
	
	FUNCTION GET_COLUMN
	(
		a_BASETABLE		IN	VARCHAR2
	)
	RETURN VARCHAR2;

END;
/
CREATE OR REPLACE PACKAGE CAAP0003 AS
/********************************************************************************
*   システム        :   プロジェクトビューワ
*   プログラムＩＤ  :   CAAP0003
*   処理名          :   共通パッケージ
*   作成日          :   2018/01/27
*   作成者          :   S.Egami
*   更新日/更新者   :
*   更新内容        :
********************************************************************************/

    /********************************************************************************
    *   宣言            :   TP619更新処理
    *   補足            :   連携DBからTP619のデータをコピーする
    *                       正常：0,異常：-1
    *   作成日          :   2018/01/27
    *   作成者          :   S.Egami
    *   更新日/更新者   :
    *   更新内容        :
    ********************************************************************************/
    FUNCTION getTP619 RETURN NUMBER;

    PROCEDURE setLog(task IN VARCHAR2,SYSID IN VARCHAR2);

END CAAP0003;
/
CREATE OR REPLACE PACKAGE CAP_AUTH_GET AS 

FUNCTION F_GET_SECG(
    i_AUTHCTGID IN VARCHAR2,--権限カテゴリID
    i_USRSEQ IN NUMBER, --ユーザー管理番号
    i_SSYSTEMID IN VARCHAR2 --サブシステムID
)RETURN VARCHAR2;

FUNCTION F_GET_AUTHLIST(
    i_AUTHCTGID IN VARCHAR2,--権限カテゴリID
    i_USRSEQ IN NUMBER,--ユーザー管理番号
    i_SSYSTEMID IN VARCHAR2 --サブシステムID
)RETURN CBT_AUTHLIST;

FUNCTION F_GET_AUTHROLE_USR(
    i_AUTHID IN VARCHAR2 --権限ID
)RETURN CBT_AUTHROLE_USR;

--サブファンクション：指定した権限IDの対象ユーザーを取得
--条件マスタによる条件管理はしない
FUNCTION F_GET_AUTH_USR (
  i_AUTHID IN VARCHAR2 --権限ID
)RETURN CBM_USR_TABLE;


END CAP_AUTH_GET;
/
CREATE OR REPLACE PACKAGE CAP_AUTHLIST_UPDATE
IS
	-- PLSQL のプログラムID
	PROGRAM_ID				CONSTANT VARCHAR2(20) := 'CAP_AUTHLIST_UPDATE';

	-- AUTHLISTを最新化する
	PROCEDURE UPDATE_AUTHLIST_TBL;
  
END;
/
CREATE OR REPLACE PACKAGE HYBS AS

	-- エラーメッセージ最大数オーバー例外
	TOO_MANY_ERRORS		EXCEPTION;

	--共通SPをCallした時に使用する例外(2007/09/28)
	COMMONSP_ERROR		EXCEPTION;

	---------------------------------------------------------------------------
	-- エラーメッセージ配列セット関数
	---------------------------------------------------------------------------
	PROCEDURE SET_ERRMSGS
		(P_ERRMSGS	IN OUT	ERR_MSG_ARRAY,
		 P_NO		IN		NUMBER   := NULL,
		 P_KEKKA	IN		NUMBER	 := NULL,
		 P_ID		IN		VARCHAR2 := NULL,
		 P_MSG1		IN		VARCHAR2 := NULL,
		 P_MSG2		IN		VARCHAR2 := NULL,
		 P_MSG3		IN		VARCHAR2 := NULL,
		 P_MSG4		IN		VARCHAR2 := NULL,
		 P_MSG5		IN		VARCHAR2 := NULL );

	---------------------------------------------------------------------------
	-- エラーメッセージ配列セット関数2 3.8.9.5 (2007/09/29) PG、ステップ名称追加
	---------------------------------------------------------------------------
	PROCEDURE SET_ERRMSGS2
		(P_ERRMSGS	IN OUT	ERR_MSG_ARRAY,
		 P_NO		IN		NUMBER   := NULL,
		 P_KEKKA	IN		NUMBER	 := NULL,
		 P_PG		IN		VARCHAR2 := NULL,
		 P_STEP		IN		VARCHAR2 := NULL,
		 P_ID		IN		VARCHAR2 := NULL,
		 P_MSG1		IN		VARCHAR2 := NULL,
		 P_MSG2		IN		VARCHAR2 := NULL,
		 P_MSG3		IN		VARCHAR2 := NULL,
		 P_MSG4		IN		VARCHAR2 := NULL,
		 P_MSG5		IN		VARCHAR2 := NULL );

	---------------------------------------------------------------------------
	-- エラーメッセージ配列最大値オーバーメッセージセット関数
	---------------------------------------------------------------------------
	PROCEDURE SET_LIMITOVER
		(P_ERRMSGS	IN OUT	ERR_MSG_ARRAY);

	---------------------------------------------------------------------------
	-- 経過時刻セット関数
	---------------------------------------------------------------------------
	PROCEDURE SET_TIMEMSG
		(P_ERRMSGS	IN OUT	ERR_MSG_ARRAY,
		 P_ID		IN		VARCHAR2 := NULL,
		 P_MSG1		IN		VARCHAR2 := NULL );

	---------------------------------------------------------------------------
	-- エラーメッセージ配列出力関数 3.8.9.5 (2007/09/29)
	---------------------------------------------------------------------------
	PROCEDURE OUTPUT_ERRMSGS
		(P_ERRMSGS	IN	ERR_MSG_ARRAY,
		 P_JOBID	IN	VARCHAR2,
		 P_PGNAME	IN	VARCHAR2);

	---------------------------------------------------------------------------
	-- エラーメッセージ配列のステータス最大値取得関数 3.8.9.5 (2007/09/29)
	---------------------------------------------------------------------------
	FUNCTION GET_MAX_KEKKA
		(P_ERRMSGS	IN	ERR_MSG_ARRAY,
		 P_ROWNO	IN	NUMBER := 1
		) RETURN NUMBER; -- 4.3.1.1 (2008/10/08) 検索開始行番号を指定できるように修正

END HYBS;
/
CREATE OR REPLACE PACKAGE LAAP00001 AS
/********************************************************************************
*   システム        :   ハヤブサ共通
*   プログラムＩＤ  :   LAAP00001
*   処理名          :   共通処理系 共通パッケージ
*   作成日          :   2019/10/09
*   
********************************************************************************/

	/********************************************************************************
	*   宣言        :   DBリンククローズ処理
	*   補足        :   セッションのDBリンクすべてを切断
	********************************************************************************/
	FUNCTION closeDBLINK RETURN NUMBER;

	/********************************************************************************
	*   宣言        :   DBリンククローズ処理
	*   補足        :   DBリンク名を指定する
	********************************************************************************/
	FUNCTION closeDBLINK(
		  inDbLinkNm	IN	VARCHAR2
	) RETURN NUMBER;

END;
/
CREATE OR REPLACE PACKAGE LAAP00002 AS
/********************************************************************************
*   システム        :   ハヤブサ共通(仕様)
*   プログラムＩＤ  :   LAAP00002
*   処理名          :   共通処理系 共通パッケージ
*   作成日          :   2009/11/11
*   作成者          :   hiro
*   更新日/更新者   :
*   更新内容        :
********************************************************************************/

	/********************************************************************************
	*   宣言        :   カーソル:社員マスタ
	*   補足        :   パラメータ
	*               :   　・“i_”からはじめます（他処理との混同を避けるため）
	*               :   　・サイズ指定しない
	********************************************************************************/
	CURSOR curNmsya
	( i_SYAIN VARCHAR2
	) IS
		SELECT NMSYA
		  FROM SYAIN_MST
		  WHERE SYAIN = i_SYAIN;

	CURSOR curEmail
	( i_SYAIN VARCHAR2
	) IS
		SELECT EMAIL
		     , NMSYA
		  FROM SYAIN_MST
		  WHERE SYAIN = i_SYAIN;

	/********************************************************************************
	*   宣言        :   カーソル:物件情報
	*   補足        :   パラメータ
	*               :   　・“i_”からはじめます（他処理との混同を避けるため）
	*               :   　・サイズ指定しない
	********************************************************************************/
	CURSOR curBknnm
	( i_BKNCD VARCHAR2
	, i_DSPCD VARCHAR2 DEFAULT NULL
	) IS
		SELECT CASE
		         WHEN i_DSPCD IS NULL THEN BKNNM
		         ELSE BKNCD || i_DSPCD || BKNNM
		       END AS BKNNM
		  FROM PA21
		  WHERE BKNCD = i_BKNCD;

	CURSOR curNonsnm
	( i_BKNCD VARCHAR2
	, i_DSPCD VARCHAR2 DEFAULT NULL
	) IS
		SELECT CASE
		         WHEN i_DSPCD IS NULL THEN NONSNM
		         ELSE BKNCD || i_DSPCD || NONSNM
		       END AS NONSNM
		  FROM PA21
		  WHERE BKNCD = i_BKNCD;

	/********************************************************************************
	*   宣言        :   カーソル:大項目マスタ
	*   補足        :   パラメータ
	*               :   　・“i_”からはじめます（他処理との混同を避けるため）
	*               :   　・サイズ指定しない
	********************************************************************************/
	CURSOR curPdnm
	( i_SYSTEM_ID VARCHAR2
	, i_LANG  VARCHAR2
	, i_PDSEQ VARCHAR2
	, i_DSPCD VARCHAR2 DEFAULT NULL
	) IS
		SELECT CASE
		         WHEN i_DSPCD IS NULL THEN PDNM
		         ELSE PDSEQ || i_DSPCD || PDNM
		       END AS PDNM
		  FROM MST01
		  WHERE SYSTEM_ID = i_SYSTEM_ID
		    AND LANG = i_LANG
		    AND PDSEQ = i_PDSEQ;

	/********************************************************************************
	*   宣言        :   カーソル:中項目マスタ
	*   補足        :   パラメータ
	*               :   　・“i_”からはじめます（他処理との混同を避けるため）
	*               :   　・サイズ指定しない
	********************************************************************************/
	CURSOR curPsnm
	( i_SYSTEM_ID VARCHAR2
	, i_LANG  VARCHAR2
	, i_PDSEQ VARCHAR2
	, i_PSSEQ VARCHAR2
	, i_DSPCD VARCHAR2 DEFAULT NULL
	) IS
		SELECT CASE
		         WHEN i_DSPCD IS NULL THEN PSNM
		         ELSE PSSEQ || i_DSPCD || PSNM
		       END AS PSNM
		  FROM MST02
		  WHERE SYSTEM_ID = i_SYSTEM_ID
		    AND LANG = i_LANG
		    AND PDSEQ = i_PDSEQ
		    AND PSSEQ = i_PSSEQ;

	/********************************************************************************
	*   宣言        :   カーソル:小項目マスタ
	*   補足        :   パラメータ
	*               :   　・“i_”からはじめます（他処理との混同を避けるため）
	*               :   　・サイズ指定しない
	********************************************************************************/
	CURSOR curPmnm
	( i_SYSTEM_ID VARCHAR2
	, i_LANG  VARCHAR2
	, i_PDSEQ VARCHAR2
	, i_PSSEQ VARCHAR2
	, i_PMSEQ VARCHAR2
	, i_DSPCD VARCHAR2 DEFAULT NULL
	) IS
		SELECT CASE
		         WHEN i_DSPCD IS NULL THEN PMNM
		         ELSE PMSEQ || i_DSPCD || PMNM
		       END AS PMNM
		  FROM MST03
		  WHERE SYSTEM_ID = i_SYSTEM_ID
		    AND LANG = i_LANG
		    AND PDSEQ = i_PDSEQ
		    AND PSSEQ = i_PSSEQ
		    AND PMSEQ = i_PMSEQ;

	/********************************************************************************
	*   宣言        :   ファンクション:社員マスタ
	*   補足        :
	********************************************************************************/
	FUNCTION getNmsya
	( inSYAIN IN SYAIN_MST.SYAIN%TYPE
	, inDSPCD IN VARCHAR2 DEFAULT NULL
	, inMODE IN PLS_INTEGER DEFAULT 0
	, inLANG IN VARCHAR2 DEFAULT 'ja') RETURN VARCHAR2;

	FUNCTION getEmail
	( inSYAIN IN SYAIN_MST.SYAIN%TYPE
	, inDSPNM IN PLS_INTEGER DEFAULT 0
	, inMODE IN PLS_INTEGER DEFAULT 0
	, inLANG IN VARCHAR2 DEFAULT 'ja') RETURN VARCHAR2;

	/********************************************************************************
	*   宣言        :   ファンクション:物件情報
	*   補足        :
	********************************************************************************/
	FUNCTION getBknnm
	( inBKNCD IN PA21.BKNCD%TYPE
	, inDSPCD IN VARCHAR2 DEFAULT NULL
	) RETURN VARCHAR2;

	FUNCTION getNonsnm
	( inBKNCD IN PA21.BKNCD%TYPE
	, inDSPCD IN VARCHAR2 DEFAULT NULL
	) RETURN VARCHAR2;

	/********************************************************************************
	*   宣言        :   ファンクション:大項目マスタ
	*   補足        :
	********************************************************************************/
	FUNCTION getPdnm
	( inSYSTEM_ID IN MST01.SYSTEM_ID%TYPE
	, inLANG      IN MST01.LANG%TYPE
	, inPDSEQ     IN MST01.PDSEQ%TYPE
	, inDSPCD     IN VARCHAR2 DEFAULT NULL
	, inRTNERR    IN VARCHAR2 DEFAULT NULL
	) RETURN VARCHAR2;

	/********************************************************************************
	*   宣言        :   ファンクション:中項目マスタ
	*   補足        :
	********************************************************************************/
	FUNCTION getPsnm
	( inSYSTEM_ID IN MST02.SYSTEM_ID%TYPE
	, inLANG      IN MST02.LANG%TYPE
	, inPDSEQ     IN MST02.PDSEQ%TYPE
	, inPSSEQ     IN MST02.PSSEQ%TYPE
	, inDSPCD     IN VARCHAR2 DEFAULT NULL
	, inRTNERR    IN VARCHAR2 DEFAULT NULL
	) RETURN VARCHAR2;

	/********************************************************************************
	*   宣言        :   ファンクション:小項目マスタ
	*   補足        :
	********************************************************************************/
	FUNCTION getPmnm
	( inSYSTEM_ID IN MST03.SYSTEM_ID%TYPE
	, inLANG      IN MST03.LANG%TYPE
	, inPDSEQ     IN MST03.PDSEQ%TYPE
	, inPSSEQ     IN MST03.PSSEQ%TYPE
	, inPMSEQ     IN MST03.PMSEQ%TYPE
	, inDSPCD     IN VARCHAR2 DEFAULT NULL
	, inRTNERR    IN VARCHAR2 DEFAULT NULL
	) RETURN VARCHAR2;


	/********************************************************************************
	*   宣言        :   ファンクション:ラベルリソース取得
	*   補足        :   井上さんが作成したファンクションを流用
	********************************************************************************/
	FUNCTION GETLBLNAME (
		  inSYSTEM_ID	IN	VARCHAR2				-- システムID
		, inLANG		IN	VARCHAR2				-- 言語
		, inCLM			IN	VARCHAR2				-- カラム
		, inLBLTYPE		IN	VARCHAR2 DEFAULT '0'	-- 0:名前(長)  1:名前(短)
	) RETURN VARCHAR2;

	/********************************************************************************
	*   宣言        :   ファンクション:日付チェック
	*   補足        :
	********************************************************************************/
	FUNCTION DATE_CHECK (
		  inCLNDY		IN	VARCHAR2				-- カレンダ日付
	) RETURN VARCHAR2;


END LAAP00002;
/
CREATE OR REPLACE PACKAGE RGP10212
AS
	PROCEDURE RG10212
	(
		P_KEKKA			OUT	NUMBER			-- エラー結果(0:正常 1:警告 2:異常)
		,P_ERRMSGS		OUT	ERR_MSG_ARRAY	-- エラーのあるときのエラーメッセージ配列
		,P_NAMES		IN	VARCHAR2
		,P_SYSARGS		IN	SYSARG_ARRAY	-- 引数 SYSTEMデータ
		,P_RG0212ARG	IN	RG0212ARG_ARRAY	-- 引数 USERデータ
	);
	TYPE PN_ARRAY   	IS TABLE OF RG103.KO%TYPE;
END;
/
CREATE OR REPLACE PACKAGE RGP10542A AS
-- 結果カーソルタイプ
TYPE CUST_CURSOR IS REF CURSOR;
PROCEDURE RG10542A (
	 P_KEKKA	OUT	NUMBER			-- 処理結果(0:正常 1:警告 2:異常)
	,P_ERRMSGS	OUT	ERR_MSG_ARRAY	-- エラーメッセージ配列
	,P_CURSOR	OUT	CUST_CURSOR		-- 結果カーソル
	,P_SYSARGS	IN	ARG_ARRAY 		-- 条件配列
);

END;
/
CREATE OR REPLACE PACKAGE SSYSTEM_MENU
IS
    --customInfoを登録する際に使用するオブジェクト
    TYPE TYPE_CSTMINF IS RECORD (
    	attrkey VARCHAR2(2000),
    	attrval VARCHAR2(2000),
    	lginid  VARCHAR2(2000),
    	seqno   VARCHAR2(2000)
    );
    
    TYPE CSTMINF_TABLE IS TABLE OF TYPE_CSTMINF INDEX BY PLS_INTEGER;
    TYPE MULTILANG_TABLE IS TABLE OF TYPE_MULTILANG;
    TYPE MENU_TABLE IS TABLE OF TYPE_MENU;
    TYPE FAVORITE_TABLE IS TABLE OF TYPE_FAVORITE;
    TYPE TAB_TABLE IS TABLE OF TYPE_TAB;
    
    FUNCTION USRSEQ_TO_LGINID(
        i_USRSEQ IN NUMBER
    ) RETURN VARCHAR2;
    
    FUNCTION F_HAS_AUTHID(
        i_USRSEQ IN VARCHAR2,
        i_AUTHID IN VARCHAR2
    ) RETURN VARCHAR2;
    
    FUNCTION F_GET_AUTHID_SSYSTEM(
        i_USRSEQ IN VARCHAR2
    ) RETURN CBT_AUTHLIST PIPELINED;
    
    FUNCTION F_GET_MENUS(
        i_USRSEQ IN VARCHAR2,
        i_SYSTEMID IN VARCHAR2 DEFAULT null,
        i_EXTERNALFLG IN NUMBER DEFAULT 0
        
    ) RETURN MENU_TABLE PIPELINED;
    
    FUNCTION F_SUBMENUFLG (
     i_USRSEQ IN VARCHAR2,
     i_SYSTEMID IN VARCHAR2
    ) RETURN TAB_TABLE PIPELINED;
    
    FUNCTION F_PINFLG (
     i_USERID IN VARCHAR2,
     i_SYSTEMID IN VARCHAR2
    ) RETURN TAB_TABLE PIPELINED;

    
    FUNCTION F_GET_FAVORITE (
     i_USRSEQ IN VARCHAR2
    ) RETURN FAVORITE_TABLE PIPELINED;
    
    FUNCTION F_GET_MULTILANG 
    RETURN MULTILANG_TABLE PIPELINED;
    
    PROCEDURE P_INS_CUSTOMEINFO(
      i_LGINID IN VARCHAR2, --ログインID
      i_ATTRKEY IN VARCHAR2, --KEY
      i_ATTRVAL IN VARCHAR2 --KEYに対応する値
    ) ;
    
    PROCEDURE P_UPD_CUSTOMEINFO(
      i_LGINID IN VARCHAR2, --更新対象のログインID
      i_ATTRKEY IN VARCHAR2, --更新対象のKEY
      i_ATTRVAL IN VARCHAR2, --更新対象のKEYに対応する値
      i_SEQNO IN VARCHAR2 --SEQNO
    ) ;
    
    PROCEDURE P_BULKINS_CUSTOMEINFO
    (
        i_list IN SSYSTEM_MENU.CSTMINF_TABLE
    );
        
    PROCEDURE P_BULKUPD_CUSTOMEINFO
    (
        i_list IN SSYSTEM_MENU.CSTMINF_TABLE
    );
    
END ;
/
CREATE OR REPLACE PACKAGE BODY CAAP0001
/******************************************************
System	:	コラボレーション
New		:	20170421
Name	:	S.Ito
--------
Mod1	:	20170908
Name	:	S.Ito
			一部local関数化
--------
LMMの権限取得関数を元に、一括&高速化した関数
******************************************************/
IS
	--閲覧権限作業TABLE作成
	FUNCTION CREATE_USERAUTH_TEMP RETURN NUMBER;

	--閲覧権限OVERRIDE
	FUNCTION OVERRIDE_USERAUTH RETURN NUMBER;

	/******************************************************
	New		:	20170421
	Name	:	S.Ito
	--------
	Mod1	:	20170621
	Name	:	S.Ito
				権限上書き処理対応
	--------
	Mod2	:	20170908
	Name	:	S.Ito
				PMS権限対応
	--------
	Mod3	:	20180808
	Name	:	S.Ito
				DC金額, 予実権限対応
	--------
	閲覧権限更新
	******************************************************/
	PROCEDURE UPDATE_USERAUTH
	IS
		result NUMBER;
	BEGIN

		--特定物件テーブル削除
		DELETE FROM BKN_SEC;
		--特定物件テーブル追加
		INSERT INTO BKN_SEC
		(
			SELECT
				BKNCD
				,TO_CHAR(SYSDATE,'yyyymmddhh24miss')
				,TO_CHAR(SYSDATE,'yyyymmddhh24miss')
				,'BACTH'
				,'BATCH'
				,PROGRAM_ID
			FROM
				LMM101
			WHERE
				SAKUID = CAAP0001.O_PRO_SAKUID
		)
		;

		--閲覧権限作業TABLE作成
		result := CREATE_USERAUTH_TEMP();
		IF result = -1 THEN
			ROLLBACK;
			RETURN;
		END IF;

		--作業テーブルからデータを移す
		DELETE FROM USR_AUTH;
		INSERT INTO USR_AUTH
		(
			USRID,BKNREFAUTH,KINREFAUTH,PMSREFAUTH,DOCKINREFAUTH,YOJIREFAUTH,DYSET,DYUPD ,USRSET,USRUPD,PRGUPD
		)
		SELECT
			USRID,BKNREFAUTH,KINREFAUTH,PMSREFAUTH,DOCKINREFAUTH,YOJIREFAUTH,DYSET,DYUPD ,USRSET,USRUPD,PRGUPD
		FROM
			USR_AUTH_TMP
		;

		--閲覧権限OVERRIDE
		result := OVERRIDE_USERAUTH();
		IF result = -1 THEN
			ROLLBACK;
			RETURN;
		END IF;

		COMMIT;

		exception when others then
			dbms_output.put_line('********ERROR********');
			dbms_output.put_line('ErrorCode : ' || sqlcode);
			dbms_output.put_line('ErrorMessage : ' || sqlerrm);
			ROLLBACK;

	END UPDATE_USERAUTH;

	/******************************************************
	New		:	20170621
	Name	:	S.Ito
	--------
	Mod1	:	20170908
	Name	:	S.Ito
				PMS権限対応
	--------
	Mod2	:	20180808
	Name	:	S.Ito
				DC金額, 予実権限対応
	--------
	閲覧権限作業TABLE作成
	******************************************************/
	FUNCTION CREATE_USERAUTH_TEMP RETURN NUMBER
	IS

	BEGIN

		--権限テーブル初期化
		DELETE FROM USR_AUTH_TMP;
		--O-PROの物件コード一件ピックアップしてINSERT
		INSERT INTO USR_AUTH_TMP
		(
			SELECT
				USERID
				,MAX(BKNREFAUTH)		--指定物件閲覧権限
				,CASE					--金額閲覧権限を職制から取得
				WHEN(SELECT SYOKUSEI FROM SAKU_USR WHERE USERID = Q1.USERID)
				IN ('1101','1102','1103','1104') THEN
					1
				ELSE
					0
				END KINREFAUTH
				,CASE					--PMS閲覧権限を職制から取得
				WHEN(SELECT SYOKUSEI FROM SAKU_USR WHERE USERID = Q1.USERID)
				IN ('1101','1102','1103','1104') THEN
					1
				ELSE
					0
				END PMSREFAUTH
				,CASE					--ドキュメント金額権限を職制から取得
				WHEN(SELECT SYOKUSEI FROM SAKU_USR WHERE USERID = Q1.USERID)
				IN ('1101','1102','1103','1104') THEN
					1
				ELSE
					0
				END DOCKINREFAUTH
				,CASE					--予実閲覧権限を職制から取得
				WHEN(SELECT SYOKUSEI FROM SAKU_USR WHERE USERID = Q1.USERID)
				IN ('1101','1102','1103','1104') THEN
					1
				ELSE
					0
				END YOJIREFAUTH
				,TO_CHAR(SYSDATE,'yyyymmddhh24miss')
				,TO_CHAR(SYSDATE,'yyyymmddhh24miss')
				,'BACTH'
				,'BATCH'
				,PROGRAM_ID
			FROM
			(
				--権限あり全ユーザ取得（閲覧）
				SELECT
					USERID
					,1 AS BKNREFAUTH
				FROM
				(
					SELECT
						BKNCD
					FROM
						BKN_SEC
					WHERE
						ROWNUM = 1
				)
				CROSS JOIN
					TABLE(CAAP0001.GET_KENKBN(BKNCD,'-'))
				UNION ALL
				--権限なしユーザ
				SELECT
					USERID
					,0 AS BKNREFAUTH
				FROM
					SAKU_USR
			) Q1
			GROUP BY
				USERID
		)
		;

		RETURN 0;

		exception when others then
			dbms_output.put_line('********ERROR********');
			dbms_output.put_line('ErrorCode : ' || sqlcode);
			dbms_output.put_line('ErrorMessage : ' || sqlerrm);
			RETURN -1;

	END CREATE_USERAUTH_TEMP;

	/******************************************************
	New		:	20170621
	Name	:	S.Ito
	--------
	Mod1	:	20170908
	Name	:	S.Ito
				PMS権限対応
	--------
	Mod2	:	20180808
	Name	:	S.Ito
				DC金額, 予実権限対応
	--------
	閲覧権限OVERRIDE
	******************************************************/
	FUNCTION OVERRIDE_USERAUTH RETURN NUMBER
	IS

	BEGIN

		--金額権限
		UPDATE USR_AUTH
		SET
			KINREFAUTH = (SELECT FLG FROM KIN_AUTH WHERE KIN_AUTH.USRID = USR_AUTH.USRID)
			,HNDFLG = CAAP0001.HNDFLG
		WHERE
			USRID IN
			(SELECT USRID FROM KIN_AUTH WHERE FLG IS NOT NULL)
		;

		--PMS権限
		UPDATE USR_AUTH
		SET
			PMSREFAUTH = (SELECT FLG FROM PMS_AUTH WHERE PMS_AUTH.USRID = USR_AUTH.USRID)
			,HNDFLG = CAAP0001.HNDFLG
		WHERE
			USRID IN
			(SELECT USRID FROM PMS_AUTH WHERE FLG IS NOT NULL)
		;

		--ドキュメント金額権限
		UPDATE USR_AUTH
		SET
			DOCKINREFAUTH = (SELECT FLG FROM DOCKIN_AUTH WHERE DOCKIN_AUTH.USRID = USR_AUTH.USRID)
			,HNDFLG = CAAP0001.HNDFLG
		WHERE
			USRID IN
			(SELECT USRID FROM DOCKIN_AUTH WHERE FLG IS NOT NULL)
		;

		--予実閲覧権限
		UPDATE USR_AUTH
		SET
			YOJIREFAUTH = (SELECT FLG FROM YOJI_AUTH WHERE YOJI_AUTH.USRID = USR_AUTH.USRID)
			,HNDFLG = CAAP0001.HNDFLG
		WHERE
			USRID IN
			(SELECT USRID FROM YOJI_AUTH WHERE FLG IS NOT NULL)
		;

		RETURN 0;

		exception when others then
			dbms_output.put_line('********ERROR********');
			dbms_output.put_line('ErrorCode : ' || sqlcode);
			dbms_output.put_line('ErrorMessage : ' || sqlerrm);
			RETURN -1;

	END OVERRIDE_USERAUTH;

	/******************************************************
	New		:	20170421
	Name	:	S.Ito
	--------
	Mod1	:
	Name	:
	--------
	閲覧権限取得
	******************************************************/
	FUNCTION GET_KENKBN
	(
		a_BKNCD			IN	VARCHAR2 := NULL
		,a_PWBS			IN	VARCHAR2 := NULL
	)
	RETURN REC_AUTHUSR PIPELINED
	IS
	BEGIN

		FOR rec
		IN (
			SELECT *
			FROM
				TABLE(CAAP0001.GET_AUTHUSR('KENKBN',a_BKNCD,a_PWBS))
			)
		LOOP
			PIPE ROW(rec);
		END LOOP;

		RETURN ;

	END GET_KENKBN;

	/******************************************************
	New		:	20170421
	Name	:	S.Ito
	--------
	Mod1	:
	Name	:
	--------
	金額権限取得
	******************************************************/
	FUNCTION GET_MONEYKENKBN
	(
		a_BKNCD			IN	VARCHAR2 := NULL
		,a_PWBS			IN	VARCHAR2 := NULL
	)
	RETURN REC_AUTHUSR PIPELINED
	IS
	BEGIN

		FOR rec
		IN (
			SELECT *
			FROM
				TABLE(CAAP0001.GET_AUTHUSR('MONEYKENKBN',a_BKNCD,a_PWBS))
			)
		LOOP
			PIPE ROW(rec);
		END LOOP;

		RETURN;

	END GET_MONEYKENKBN;

	/******************************************************
	New		:	20170421
	Name	:	S.Ito
	--------
	Mod1	:
	Name	:
	--------
	ある作番に対し、閲覧権限のあるユーザを取得する
	この関数は原則として直接呼び出さず、GET_MONEYKENKBN等を経由する
	******************************************************/
	FUNCTION GET_AUTHUSR
	(
		a_CLMNM			IN	VARCHAR2 := NULL
		,a_BKNCD		IN	VARCHAR2 := NULL
		,a_PWBS			IN	VARCHAR2 := NULL
	)
	RETURN REC_AUTHUSR PIPELINED

	IS
		TYPE CUR			IS REF CURSOR;
		cnt					NUMBER:=0;
		rowcnt				NUMBER:=0;

		--社員用
		CURREC_SYAIN		CUR;
		retrec_SYAIN		AUTHUSR_TYPE;

		-- カーソルOPEN用のSQL文字列
		strInSQL			VARCHAR2(32767);
		strFromSyainSQL1	VARCHAR2(32767);
		strOutSQL1			VARCHAR2(32767);
		strOutSQL2			VARCHAR2(32767);
		strOutSQL3			VARCHAR2(32767);
		strWhere			VARCHAR2(32767);
		strSQL				VARCHAR2(32767);

		strUseSyainTable	VARCHAR2(32767);

		--社員数
		strSyainCountSQL	VARCHAR2(32767);
		iSyainCount			NUMBER:=0;

	BEGIN

		--クエリ構成

		strUseSyainTable := 'SAKU_USR';

		--処理すべきユーザがいなければ無駄なため終了
		strSyainCountSQL := NULL;
		strSyainCountSQL := strSyainCountSQL || '	SELECT						';
		strSyainCountSQL := strSyainCountSQL || '		COUNT(*)				';
		strSyainCountSQL := strSyainCountSQL || '	FROM						';
		strSyainCountSQL := strSyainCountSQL || '	' || strUseSyainTable || '	';
		EXECUTE IMMEDIATE strSyainCountSQL INTO iSyainCount;

		IF iSyainCount <= 0 THEN
			RETURN;
		END iF;


		--権限チェックをするユーザ一覧
		strFromSyainSQL1 := NULL;
		strFromSyainSQL1 := strFromSyainSQL1 || '	SELECT						';
		strFromSyainSQL1 := strFromSyainSQL1 || '		USERID AS ID,			';
		strFromSyainSQL1 := strFromSyainSQL1 || '		BUKA,					';-- 部課CD
		strFromSyainSQL1 := strFromSyainSQL1 || '		SYAINK,					';-- 社員区分
		strFromSyainSQL1 := strFromSyainSQL1 || '		SYOKUSYU,				';-- 職種
		strFromSyainSQL1 := strFromSyainSQL1 || '		SYOKUSEI				';-- 職制
		strFromSyainSQL1 := strFromSyainSQL1 || '	FROM						';
		strFromSyainSQL1 := strFromSyainSQL1 || '	' || strUseSyainTable || '	';


		--ある作番に対しグループ単位での権限-所属ユーザ取得
		strOutSQL1 := NULL;
		strOutSQL1 := strOutSQL1 || '	SELECT											';
		strOutSQL1 := strOutSQL1 || '		Q_KOJIN.USERID,								';
		strOutSQL1 := strOutSQL1 || '		Q_KOJIN.GRPID,								';
		strOutSQL1 := strOutSQL1 || '		Q_GROUP.' || a_CLMNM || ',					';-- 権限区分
		strOutSQL1 := strOutSQL1 || '		Q_GROUP.YJUN								';-- 優先順位
		strOutSQL1 := strOutSQL1 || '	FROM											';
		strOutSQL1 := strOutSQL1 || '		(											';
		strOutSQL1 := strOutSQL1 || '		SELECT										';
		strOutSQL1 := strOutSQL1 || '			MST_ID.ID AS USERID,					';
		strOutSQL1 := strOutSQL1 || '			LMMM122.GRPID							';
		strOutSQL1 := strOutSQL1 || '		FROM										';
		strOutSQL1 := strOutSQL1 || '			MST_ID									';
		strOutSQL1 := strOutSQL1 || '			LEFT JOIN								';
		strOutSQL1 := strOutSQL1 || '			(										';
		strOutSQL1 := strOutSQL1 || '			SELECT									';
		strOutSQL1 := strOutSQL1 || '				*									';
		strOutSQL1 := strOutSQL1 || '			FROM									';
		strOutSQL1 := strOutSQL1 || '				LMMM122								';
		strOutSQL1 := strOutSQL1 || '			WHERE									';
		strOutSQL1 := strOutSQL1 || '				TO_CHAR(SYSDATE,''YYYYMMDD'') BETWEEN YUKODY_F AND YUKODY_T			';
		strOutSQL1 := strOutSQL1 || '			) LMMM122 ON							';
		strOutSQL1 := strOutSQL1 || '			MST_ID.ID = LMMM122.USERID				';
		strOutSQL1 := strOutSQL1 || '		) Q_KOJIN									';
		strOutSQL1 := strOutSQL1 || '													';
		strOutSQL1 := strOutSQL1 || '	INNER JOIN										';
		strOutSQL1 := strOutSQL1 || '		(											';
		strOutSQL1 := strOutSQL1 || '		SELECT Q_GROUP1.' || a_CLMNM || ',Q_GROUP1.YJUN,Q_GROUP1.GRPID FROM			';
		strOutSQL1 := strOutSQL1 || '		(											';
		strOutSQL1 := strOutSQL1 || '		SELECT										';
		strOutSQL1 := strOutSQL1 || '			A.' || a_CLMNM || ',					';	-- 権限区分
		strOutSQL1 := strOutSQL1 || '			A.YJUN,									';	-- 優先順位
		strOutSQL1 := strOutSQL1 || '			GRPID									';	-- グループID
		strOutSQL1 := strOutSQL1 || '		FROM										';
		strOutSQL1 := strOutSQL1 || '			(										';
		strOutSQL1 := strOutSQL1 || '			SELECT									';
		strOutSQL1 := strOutSQL1 || '				DISTINCT SAKUID,					';	-- 作番
		strOutSQL1 := strOutSQL1 || '				' || a_CLMNM || ',					';	-- 権限区分
		strOutSQL1 := strOutSQL1 || '				YJUN,								';	-- 優先順位
		strOutSQL1 := strOutSQL1 || '				GRPID								';
		strOutSQL1 := strOutSQL1 || '			FROM									';
		strOutSQL1 := strOutSQL1 || '				LMMM112								';	-- グループ作番権限区分マスタ
		strOutSQL1 := strOutSQL1 || '			) A										';
		strOutSQL1 := strOutSQL1 || '			INNER JOIN								';
		strOutSQL1 := strOutSQL1 || '			LMM101 B ON								';
		strOutSQL1 := strOutSQL1 || '			A.SAKUID = B.SAKUID						';
		strOutSQL1 := strOutSQL1 || '		WHERE																	';	-- 作番設定テーブル
		strOutSQL1 := strOutSQL1 || '			B.BKNCD IN (''-'',''' || a_BKNCD || ''') AND						';	-- 物件CD条件（'-'はすべてをあらわす）
		strOutSQL1 := strOutSQL1 || '			B.PWBS IN (''-'',''' || a_PWBS || ''') AND				 			'; 	-- PWBS条件（'-'はすべてをあらわす）
		strOutSQL1 := strOutSQL1 || '			TO_CHAR(SYSDATE,''YYYYMMDD'') BETWEEN B.YUKODY_F AND B.YUKODY_T		';	-- 有効期間条件
		strOutSQL1 := strOutSQL1 || '		UNION ALL									';
		strOutSQL1 := strOutSQL1 || '		SELECT										';
		strOutSQL1 := strOutSQL1 || '			' || a_CLMNM || ',						';	-- 権限区分
		strOutSQL1 := strOutSQL1 || '			1000000 AS YJUN,						';	-- 優先順位
		strOutSQL1 := strOutSQL1 || '			GRPID									';	-- グループID
		strOutSQL1 := strOutSQL1 || '		FROM										';
		strOutSQL1 := strOutSQL1 || '			LMMM111									';	-- グループ権限区分マスタ
		strOutSQL1 := strOutSQL1 || '		ORDER BY									';
		strOutSQL1 := strOutSQL1 || '			YJUN ASC								';	-- 優先順位昇順
		strOutSQL1 := strOutSQL1 || '		)Q_GROUP1,									';
		strOutSQL1 := strOutSQL1 || '		(											';
		strOutSQL1 := strOutSQL1 || '		SELECT GRPID,MIN(YJUN) AS YJUN				';
		strOutSQL1 := strOutSQL1 || '		FROM										';
		strOutSQL1 := strOutSQL1 || '		(											';
		strOutSQL1 := strOutSQL1 || '		SELECT										';
		strOutSQL1 := strOutSQL1 || '			A.YJUN,									';	-- 優先順位
		strOutSQL1 := strOutSQL1 || '			GRPID									';	-- グループID
		strOutSQL1 := strOutSQL1 || '		FROM										';
		strOutSQL1 := strOutSQL1 || '			(										';
		strOutSQL1 := strOutSQL1 || '			SELECT									';
		strOutSQL1 := strOutSQL1 || '				DISTINCT SAKUID,					';	-- 作番
		strOutSQL1 := strOutSQL1 || '				' || a_CLMNM || ',					';	-- 権限区分
		strOutSQL1 := strOutSQL1 || '				YJUN,								';	-- 優先順位
		strOutSQL1 := strOutSQL1 || '				GRPID								';
		strOutSQL1 := strOutSQL1 || '			FROM									';
		strOutSQL1 := strOutSQL1 || '				LMMM112								';	-- グループ作番権限区分マスタ
		strOutSQL1 := strOutSQL1 || '			) A										';
		strOutSQL1 := strOutSQL1 || '			INNER JOIN								';
		strOutSQL1 := strOutSQL1 || '			LMM101 B ON								';
		strOutSQL1 := strOutSQL1 || '			A.SAKUID = B.SAKUID						';
		strOutSQL1 := strOutSQL1 || '		WHERE										';	-- 作番設定テーブル
		strOutSQL1 := strOutSQL1 || '			B.BKNCD IN (''-'',''' || a_BKNCD || ''') AND						';	-- 物件CD条件（'-'はすべてをあらわす）
		strOutSQL1 := strOutSQL1 || '			B.PWBS IN (''-'',''' || a_PWBS || ''') AND							';	-- PWBS条件（'-'はすべてをあらわす）
		strOutSQL1 := strOutSQL1 || '			TO_CHAR(SYSDATE,''YYYYMMDD'') BETWEEN B.YUKODY_F AND B.YUKODY_T		';	-- 有効期間条件
		strOutSQL1 := strOutSQL1 || '		UNION ALL									';
		strOutSQL1 := strOutSQL1 || '		SELECT										';
		strOutSQL1 := strOutSQL1 || '			1000000 AS YJUN,						';	-- 優先順位
		strOutSQL1 := strOutSQL1 || '			GRPID									';	-- グループID
		strOutSQL1 := strOutSQL1 || '		FROM										';
		strOutSQL1 := strOutSQL1 || '			LMMM111									';	-- グループ権限区分マスタ
		strOutSQL1 := strOutSQL1 || '		) 											';
		strOutSQL1 := strOutSQL1 || '		GROUP BY GRPID								';
		strOutSQL1 := strOutSQL1 || '		)Q_GROUP2									';
		strOutSQL1 := strOutSQL1 || '		WHERE Q_GROUP1.YJUN = Q_GROUP2.YJUN AND Q_GROUP1.GRPID = Q_GROUP2.GRPID		';
		strOutSQL1 := strOutSQL1 || '		) Q_GROUP 									';
		strOutSQL1 := strOutSQL1 || '		ON											';
		strOutSQL1 := strOutSQL1 || '			Q_GROUP.GRPID = Q_KOJIN.GRPID			';


		--ある作番に対し個人単位での権限
		strOutSQL2 := NULL;
		strOutSQL2 := strOutSQL2 || '		SELECT												';
		strOutSQL2 := strOutSQL2 || '			USERID,											';
		strOutSQL2 := strOutSQL2 || '			B.' || a_CLMNM || '								';	-- 権限区分
		strOutSQL2 := strOutSQL2 || '		FROM												';
		strOutSQL2 := strOutSQL2 || '			LMM101 A										';	-- 作番設定テーブル
		strOutSQL2 := strOutSQL2 || '			INNER JOIN										';
		strOutSQL2 := strOutSQL2 || '			(												';
		strOutSQL2 := strOutSQL2 || '			SELECT											';
		strOutSQL2 := strOutSQL2 || '				SAKUID,										';
		strOutSQL2 := strOutSQL2 || '				' || a_CLMNM || ',							';	-- 権限区分
		strOutSQL2 := strOutSQL2 || '				USERID,										';
		strOutSQL2 := strOutSQL2 || '				YJUN										';	-- 優先順位
		strOutSQL2 := strOutSQL2 || '			FROM											';
		strOutSQL2 := strOutSQL2 || '				LMMM121										';	-- 個人作番権限区分マスタ
		strOutSQL2 := strOutSQL2 || '			WHERE											';
		strOutSQL2 := strOutSQL2 || '				TO_CHAR(SYSDATE,''YYYYMMDD'') BETWEEN YUKODY_F AND YUKODY_T	';	-- 有効期間条件-- 有効期間条
		strOutSQL2 := strOutSQL2 || '			) B ON											';	-- 個人作番情報取得文
		strOutSQL2 := strOutSQL2 || '			A.SAKUID = B.SAKUID								';
		strOutSQL2 := strOutSQL2 || '		WHERE												';
		strOutSQL2 := strOutSQL2 || '			A.BKNCD IN (''-'',''' || a_BKNCD || ''') AND	';	-- 物件CD条件（'-'はすべてをあらわす）
		strOutSQL2 := strOutSQL2 || '			A.PWBS IN (''-'',''' || a_PWBS || ''') AND		';	-- PWBS条件（'-'はすべてをあらわす）
		strOutSQL2 := strOutSQL2 || '			TO_CHAR(SYSDATE,''YYYYMMDD'') BETWEEN A.YUKODY_F AND A.YUKODY_T	';	-- 有効期間条件
		strOutSQL2 := strOutSQL2 || '		ORDER BY											';
		strOutSQL2 := strOutSQL2 || '			B.YJUN ASC										';	-- 優先位昇順


		--全社員の所属による権限
		strOutSQL3 := NULL;
		strOutSQL3 := strOutSQL3 || '	SELECT												';
		strOutSQL3 := strOutSQL3 || '		Q_SYAINGROUP.ID AS USERID,						';
		strOutSQL3 := strOutSQL3 || '		Q_SYAINGROUP.GRPID,								';
		strOutSQL3 := strOutSQL3 || '		';	--Q_SYAINGROUPKENGEN.YJUN,					';	-- 優先順位
		strOutSQL3 := strOutSQL3 || '		Q_SYAINGROUPKENGEN.' || a_CLMNM || ' AS KENGEN1,';
		strOutSQL3 := strOutSQL3 || '		Q_LMMM111.' || a_CLMNM || ' AS KENGEN2,			';
		strOutSQL3 := strOutSQL3 || '		CASE 											';
		strOutSQL3 := strOutSQL3 || '		WHEN											';
		strOutSQL3 := strOutSQL3 || '			(Q_SYAINGROUPKENGEN.' || a_CLMNM || ' = ''0'') THEN	''0''						';
		strOutSQL3 := strOutSQL3 || '		WHEN																				';
		strOutSQL3 := strOutSQL3 || '			(Q_SYAINGROUPKENGEN.' || a_CLMNM || ' = ''1'') THEN	''1''						';
		strOutSQL3 := strOutSQL3 || '		WHEN																				';
		strOutSQL3 := strOutSQL3 || '			(Q_SYAINGROUPKENGEN.' || a_CLMNM || ' IS NULL) THEN	Q_LMMM111.' || a_CLMNM || '	';
		strOutSQL3 := strOutSQL3 || '		ELSE											';
		strOutSQL3 := strOutSQL3 || '			''0''										';
		strOutSQL3 := strOutSQL3 || '		END ' || a_CLMNM || '							';
		strOutSQL3 := strOutSQL3 || '	FROM												';
		strOutSQL3 := strOutSQL3 || '		(												';
											--全社員の所属
		strOutSQL3 := strOutSQL3 || '		SELECT											';
		strOutSQL3 := strOutSQL3 || '			Q_SYAIN.ID,									';
		strOutSQL3 := strOutSQL3 || '			';	--	Q_SYAIN.SBUKA,						';	-- 部課CD
		strOutSQL3 := strOutSQL3 || '			';	--	Q_SYAIN.SYAINK,						';	-- 社員区分
		strOutSQL3 := strOutSQL3 || '			';	--	Q_SYAIN.SYOKUSYU,					';	-- 職種
		strOutSQL3 := strOutSQL3 || '			';	--	Q_SYAIN.SYOKUSEI,					';	-- 職制
		strOutSQL3 := strOutSQL3 || '			GRPID										';
		strOutSQL3 := strOutSQL3 || '		FROM											';
		strOutSQL3 := strOutSQL3 || '			(											';
		strOutSQL3 := strOutSQL3 || '			' || strFromSyainSQL1 || '					';	--更新したいユーザだけ
		strOutSQL3 := strOutSQL3 || '			) Q_SYAIN									';
		strOutSQL3 := strOutSQL3 || '			INNER JOIN									';
		strOutSQL3 := strOutSQL3 || '			(											';
		strOutSQL3 := strOutSQL3 || '			SELECT										';
		strOutSQL3 := strOutSQL3 || '				*										';
		strOutSQL3 := strOutSQL3 || '			FROM										';
		strOutSQL3 := strOutSQL3 || '				LMMM113									';
		strOutSQL3 := strOutSQL3 || '			WHERE										';
		strOutSQL3 := strOutSQL3 || '				TO_CHAR(SYSDATE,''YYYYMMDD'') BETWEEN YUKODY_F AND YUKODY_T			';
		strOutSQL3 := strOutSQL3 || '			) LMMM113 ON								';
		strOutSQL3 := strOutSQL3 || '			LMMM113.DATACD = Q_SYAIN.BUKA OR			';
		strOutSQL3 := strOutSQL3 || '			LMMM113.DATACD = Q_SYAIN.SYAINK OR			';
		strOutSQL3 := strOutSQL3 || '			LMMM113.DATACD = Q_SYAIN.SYOKUSYU OR		';
		strOutSQL3 := strOutSQL3 || '			LMMM113.DATACD = Q_SYAIN.SYOKUSEI			';
		strOutSQL3 := strOutSQL3 || '		) Q_SYAINGROUP									';
		strOutSQL3 := strOutSQL3 || '		LEFT OUTER JOIN									';
		strOutSQL3 := strOutSQL3 || '		(												';
											--ある作番に対しグループ単位での権限
		strOutSQL3 := strOutSQL3 || '		SELECT											';
		strOutSQL3 := strOutSQL3 || '			A.' || a_CLMNM || ',						';	-- 権限区分
		strOutSQL3 := strOutSQL3 || '			A.YJUN,										';	-- 優先順位
		strOutSQL3 := strOutSQL3 || '			GRPID										';	-- グループID
		strOutSQL3 := strOutSQL3 || '		FROM											';
		strOutSQL3 := strOutSQL3 || '			(											';
		strOutSQL3 := strOutSQL3 || '			SELECT										';
		strOutSQL3 := strOutSQL3 || '				DISTINCT SAKUID,						';	-- 作番
		strOutSQL3 := strOutSQL3 || '				' || a_CLMNM || ',						';	-- 権限区分
		strOutSQL3 := strOutSQL3 || '				YJUN,									';	-- 優先順位
		strOutSQL3 := strOutSQL3 || '				GRPID									';
		strOutSQL3 := strOutSQL3 || '			FROM										';
		strOutSQL3 := strOutSQL3 || '				LMMM112									';	-- グループ作番権限区分マスタ
		strOutSQL3 := strOutSQL3 || '			) A											';
		strOutSQL3 := strOutSQL3 || '			INNER JOIN									';
		strOutSQL3 := strOutSQL3 || '			LMM101 B ON									';	-- 作番設定テーブル
		strOutSQL3 := strOutSQL3 || '			A.SAKUID = B.SAKUID							';
		strOutSQL3 := strOutSQL3 || '		WHERE											';
		strOutSQL3 := strOutSQL3 || '			B.BKNCD IN (''-'',''' || a_BKNCD || ''') AND					';	-- 物件CD条件（'-'はすべてをあらわす）
		strOutSQL3 := strOutSQL3 || '			B.PWBS IN (''-'',''' || a_PWBS || ''') AND						';	-- PWBS条件（'-'はすべてをあらわす）
		strOutSQL3 := strOutSQL3 || '			TO_CHAR(SYSDATE,''YYYYMMDD'') BETWEEN B.YUKODY_F AND B.YUKODY_T	';	-- 有効期間条件
		strOutSQL3 := strOutSQL3 || '		) Q_SYAINGROUPKENGEN ON			';
		strOutSQL3 := strOutSQL3 || '		Q_SYAINGROUP.GRPID = Q_SYAINGROUPKENGEN.GRPID	';
											--グループ権限マスタから取得
		strOutSQL3 := strOutSQL3 || '		LEFT OUTER JOIN									';
		strOutSQL3 := strOutSQL3 || '		(												';
		strOutSQL3 := strOutSQL3 || '		SELECT											';
		strOutSQL3 := strOutSQL3 || '			' || a_CLMNM || ',							';	-- 権限区分
		strOutSQL3 := strOutSQL3 || '			1000000 AS YJUN,							';	-- 優先順位
		strOutSQL3 := strOutSQL3 || '			GRPID										';	-- グループID
		strOutSQL3 := strOutSQL3 || '		FROM											';
		strOutSQL3 := strOutSQL3 || '			LMMM111										';	-- グループ権限区分マスタ
		strOutSQL3 := strOutSQL3 || '		ORDER BY										';
		strOutSQL3 := strOutSQL3 || '			YJUN ASC									';	-- 優先順位昇順
		strOutSQL3 := strOutSQL3 || '		) Q_LMMM111										';
		strOutSQL3 := strOutSQL3 || '		ON												';
		strOutSQL3 := strOutSQL3 || '			Q_LMMM111.GRPID = Q_SYAINGROUP.GRPID		';


		--クエリ結合
		strSQL := NULL;
		strSQL := strSQL || ' SELECT ' || strUseSyainTable || '.USERID						';
		strSQL := strSQL || ' 	,Q_KOJIN_KENGEN.' || a_CLMNM || ' AS KENGEN1				';		--優先1
		strSQL := strSQL || ' 	,Q_GROUP_KENGEN.' || a_CLMNM || ' AS KENGEN2				';		--優先2
		strSQL := strSQL || ' 	,Q_SYOZOKU_KENGEN.' || a_CLMNM || ' AS KENGEN3				';		--優先3
		strSQL := strSQL || ' 	,CASE														';
		strSQL := strSQL || ' 		WHEN													';
		strSQL := strSQL || ' 			(Q_KOJIN_KENGEN.' || a_CLMNM || ' IS NOT NULL) THEN		Q_KOJIN_KENGEN.' || a_CLMNM || '			';
		strSQL := strSQL || ' 		WHEN																									';
		strSQL := strSQL || ' 			(Q_GROUP_KENGEN.' || a_CLMNM || ' IS NOT NULL) THEN		Q_GROUP_KENGEN.' || a_CLMNM || '			';
		strSQL := strSQL || ' 		WHEN																									';
		strSQL := strSQL || ' 			(Q_SYOZOKU_KENGEN.' || a_CLMNM || ' IS NOT NULL) THEN		Q_SYOZOKU_KENGEN.' || a_CLMNM || '		';
		strSQL := strSQL || ' 		ELSE																									';
		strSQL := strSQL || ' 			''0''												';
		strSQL := strSQL || ' 	END ' || a_CLMNM || '										';
		strSQL := strSQL || ' FROM															';
		strSQL := strSQL || ' 	' || strUseSyainTable || '									';
		strSQL := strSQL || ' LEFT JOIN														';
		strSQL := strSQL || ' 	(															';
		strSQL := strSQL || ' 	' || strOutSQL1 || ' 										';
		strSQL := strSQL || ' 	) Q_GROUP_KENGEN											';
		strSQL := strSQL || ' ON 															';
		strSQL := strSQL || ' 	' || strUseSyainTable || '.USERID = Q_GROUP_KENGEN.USERID	';
		strSQL := strSQL || ' LEFT JOIN														';
		strSQL := strSQL || ' 	(															';
		strSQL := strSQL || ' 	' || strOutSQL2 || '										';
		strSQL := strSQL || ' 	) Q_KOJIN_KENGEN											';
		strSQL := strSQL || ' ON 															';
		strSQL := strSQL || ' 	' || strUseSyainTable || '.USERID = Q_KOJIN_KENGEN.USERID	';
		strSQL := strSQL || ' LEFT JOIN														';
		strSQL := strSQL || ' 	(															';
		strSQL := strSQL || ' 	' || strOutSQL3 || '										';
		strSQL := strSQL || ' 	) Q_SYOZOKU_KENGEN											';
		strSQL := strSQL || ' ON 															';
		strSQL := strSQL || ' 	' || strUseSyainTable || '.USERID = Q_SYOZOKU_KENGEN.USERID	';

		strSQL := ' SELECT USERID FROM ( ' || strSQL || ' ) Q_RESULT WHERE ' || a_CLMNM || ' = ''1''';


		OPEN CURREC_SYAIN FOR strSQL;

		rowcnt := 0;

		LOOP

			fetch CURREC_SYAIN into retrec_SYAIN;
			exit when CURREC_SYAIN%notfound;

			PIPE ROW(retrec_SYAIN);

		END LOOP;

		CLOSE CURREC_SYAIN;

		RETURN;

		exception when others then
			dbms_output.put_line('********ERROR********');
			dbms_output.put_line('ErrorCode : ' || sqlcode);
			dbms_output.put_line('ErrorMessage : ' || sqlerrm);

			RAISE_APPLICATION_ERROR(sqlcode,sqlerrm);

	END GET_AUTHUSR;

END CAAP0001;
/
CREATE OR REPLACE PACKAGE BODY CAAP0002
/******************************************************
System	:	コラボレーション
New		:	20170627
Name	:	S.Ito
--------
Mod1	:	
Name	:	
--------
権限テーブル配布
******************************************************/
IS

	/******************************************************
	New		:	20170627
	Name	:	S.Ito
	--------
	Mod1	:	
	Name	:	
	--------
	テーブル配布処理
	BASETABLEをTARGETTABLEにコピーする
	カラム情報はBASETABLEを正とする
	******************************************************/
	PROCEDURE TRANSFER_TABLE
	(
		a_BASETABLE		IN	VARCHAR2
		,a_TARGETTABLE	IN	VARCHAR2
	)
	IS
		result NUMBER;
		transSql VARCHAR2(32000);
		deleteSql VARCHAR2(1000);
	BEGIN
		
		--旧データ削除
		deleteSql := null;
		deleteSql := 'DELETE FROM :TARGETTABLE';
		--bind
		deleteSql := REPLACE(deleteSql, ':TARGETTABLE', a_TARGETTABLE );
		
		EXECUTE IMMEDIATE deleteSql;		
		
		--テーブル配布
		transSql := null;
		transSql := transSql || '
			INSERT INTO :TARGETTABLE
			(
				:COLUMNNAME
			)
			SELECT
				:COLUMNNAME
			FROM
				:BASETABLE
		';
		
		--bind
		transSql := REPLACE(transSql, ':TARGETTABLE', a_TARGETTABLE );
		transSql := REPLACE(transSql, ':BASETABLE', a_BASETABLE );
		transSql := REPLACE(transSql, ':COLUMNNAME', GET_COLUMN(a_BASETABLE) );
		
		EXECUTE IMMEDIATE transSql;
		
		COMMIT;
	
		exception when others then
			dbms_output.put_line('********ERROR********');
			dbms_output.put_line('ErrorCode : ' || sqlcode);
			dbms_output.put_line('ErrorMessage : ' || sqlerrm);
			ROLLBACK;
			
			RAISE_APPLICATION_ERROR(-20000,sqlerrm);
	
	END TRANSFER_TABLE;

	/******************************************************
	New		:	20170627
	Name	:	S.Ito
	--------
	Mod1	:	
	Name	:	
	--------
	テーブル情報読取
	******************************************************/	
	FUNCTION GET_COLUMN
	(
		a_BASETABLE		IN	VARCHAR2
	)
	RETURN VARCHAR2
	IS
		result VARCHAR2(4000);
	BEGIN
		
		SELECT
			wmsys.wm_concat(COLUMN_NAME)
		INTO
			result
		FROM
			ALL_TAB_COLUMNS
		WHERE
			UPPER(TABLE_NAME) = a_BASETABLE
		GROUP BY
			TABLE_NAME
		;		
		
		RETURN result;
	
		exception when others then
			dbms_output.put_line('********ERROR********');
			dbms_output.put_line('ErrorCode : ' || sqlcode);
			dbms_output.put_line('ErrorMessage : ' || sqlerrm);
			
			RAISE_APPLICATION_ERROR(-20000,sqlerrm);
	
	END GET_COLUMN;
	
END CAAP0002;
/
CREATE OR REPLACE PACKAGE BODY CAAP0003 AS
/********************************************************************************
*   システム        :   プロジェクトビューワ
*   プログラムＩＤ  :   CAAP0003
*   処理名          :   共通パッケージ
*   作成日          :   2018/01/27
*   作成者          :   S.Egami
*   更新日/更新者   :
*   更新内容        :
********************************************************************************/
    FUNCTION getTP619 RETURN NUMBER
    IS
        CURSOR csr1 IS SELECT * FROM PL_TP619;                                 -- TP619＠連携DB用カーソル
        TYPE recType1 IS TABLE OF TP619_WORK%ROWTYPE INDEX BY BINARY_INTEGER;  -- WORK用型
        rec1 recType1;

        CURSOR csr2 IS SELECT * FROM TP619_WORK;                               -- TP619_WORK用カーソル
        TYPE recType2 IS TABLE OF TP619%ROWTYPE INDEX BY BINARY_INTEGER;       -- TP619用型
        rec2 recType2;

        cnt NUMBER;

        c_SYSID VARCHAR2(100) := 'CAAP0003';

    BEGIN

        -- ◆◆◆◆　連携DBからCAAスキーマにデータを保存(連携DB→WORK)　◆◆◆◆

        -- TP619_WORK(一時保管テーブル)を削除する。
        EXECUTE IMMEDIATE 'TRUNCATE TABLE TP619_WORK';

        -- TP619_WORKへ連携DBの情報を登録する。
        setLog('[START] INSERT INTO TP619_WORK',c_SYSID);
        OPEN csr1;
        LOOP
            FETCH csr1 BULK COLLECT INTO rec1 LIMIT 100000;
            EXIT WHEN rec1.COUNT = 0;
            BEGIN
                FORALL i IN 1..rec1.COUNT
                    INSERT INTO TP619_WORK VALUES rec1(i);
            END;

            -- 一度コミットする。
           COMMIT;
        END LOOP;
        CLOSE csr1;
        setLog('[END  ] INSERT INTO TP619_WORK',c_SYSID);

        -- ◆◆◆◆　連携DBからCAAスキーマにデータを保存(連携DB→WORK)　◆◆◆◆

        -- 処理速度向上のため、INDEXを削除
        setLog('[START] DROP INDEX TP619',c_SYSID);
        FOR rec IN (SELECT index_name FROM user_indexes WHERE table_name = 'TP619' AND table_owner = 'CAA') LOOP
            EXECUTE IMMEDIATE 'DROP INDEX ' || rec.index_name;
        END LOOP;
        setLog('[END  ] DROP INDEX TP619',c_SYSID);

        -- TP619を削除する。(★debug)
        SELECT COUNT(*) INTO cnt FROM TP619;     -- 削除する前にメモリに作成する。
        setLog('[START] DELETE TP619',c_SYSID);
        DELETE FROM TP619;
        setLog('[END  ] DELETE TP619',c_SYSID);

        setLog('[START] INSERT TP619',c_SYSID);
        -- TP619へTP619_WORKの情報を登録する。(★debug)
        INSERT INTO TP619 SELECT * FROM TP619_WORK;
        /*OPEN csr2;
        LOOP
            FETCH csr2 BULK COLLECT INTO rec2 LIMIT 100000;
            EXIT WHEN rec2.COUNT = 0;
            BEGIN
                FORALL i IN 1..rec2.COUNT
                    INSERT INTO TP619 VALUES rec2(i);
            END;
        END LOOP;*/
        -- コミットする。
        COMMIT;
        setLog('[END  ] INSERT TP619',c_SYSID);

        -- INDEXを再作成
        setLog('[START] CREATE INDEX TP619',c_SYSID);
        EXECUTE IMMEDIATE 'CREATE UNIQUE INDEX CAA.TP619_UK ON CAA.TP619 (BKNCD, KTJUN, NOKID) PCTFREE 10 INITRANS 2 MAXTRANS 255 TABLESPACE USERS STORAGE(INITIAL 64K NEXT 1M MINEXTENTS 1 MAXEXTENTS 2147483645 BUFFER_POOL DEFAULT) LOGGING VISIBLE';

        EXECUTE IMMEDIATE 'CREATE INDEX CAA.TP619_IXA ON CAA.TP619 (JIGSYO, KIS, CDKTEI) PCTFREE 10 INITRANS 2 MAXTRANS 255 TABLESPACE USERS STORAGE(INITIAL 64K NEXT 1M MINEXTENTS 1 MAXEXTENTS 2147483645 BUFFER_POOL DEFAULT) LOGGING VISIBLE';

        EXECUTE IMMEDIATE 'CREATE INDEX CAA.TP619_IXB ON CAA.TP619 (SSDSPDAY) PCTFREE 10 INITRANS 2 MAXTRANS 255 TABLESPACE USERS STORAGE(INITIAL 64K NEXT 1M MINEXTENTS 1 MAXEXTENTS 2147483645 BUFFER_POOL DEFAULT) LOGGING VISIBLE';

        EXECUTE IMMEDIATE 'CREATE INDEX CAA.TP619_IXC ON CAA.TP619 (SSDEPDAY) PCTFREE 10 INITRANS 2 MAXTRANS 255 TABLESPACE USERS STORAGE(INITIAL 64K NEXT 1M MINEXTENTS 1 MAXEXTENTS 2147483645 BUFFER_POOL DEFAULT) LOGGING VISIBLE';

        EXECUTE IMMEDIATE 'CREATE INDEX CAA.TP619_IXD ON CAA.TP619 (BSDAY) PCTFREE 10 INITRANS 2 MAXTRANS 255 TABLESPACE USERS STORAGE(INITIAL 64K NEXT 1M MINEXTENTS 1 MAXEXTENTS 2147483645 BUFFER_POOL DEFAULT) LOGGING VISIBLE';

        EXECUTE IMMEDIATE 'CREATE INDEX CAA.TP619_IXF ON CAA.TP619 (NOKID) PCTFREE 10 INITRANS 2 MAXTRANS 255 TABLESPACE USERS STORAGE(INITIAL 64K NEXT 1M MINEXTENTS 1 MAXEXTENTS 2147483645 BUFFER_POOL DEFAULT) LOGGING VISIBLE ';

        EXECUTE IMMEDIATE 'CREATE INDEX CAA.TP619_IXG ON CAA.TP619 (BKATAN, CDJ619, JIGSYO, TANT) PCTFREE 10 INITRANS 2 MAXTRANS 255 TABLESPACE USERS STORAGE(INITIAL 64K NEXT 1M MINEXTENTS 1 MAXEXTENTS 2147483645 BUFFER_POOL DEFAULT) LOGGING VISIBLE';

        EXECUTE IMMEDIATE 'CREATE INDEX CAA.TP619_IXH ON CAA.TP619 (JIGSYO, GOKI, CDPLN2, CDJ619) PCTFREE 10 INITRANS 2 MAXTRANS 255 TABLESPACE USERS STORAGE(INITIAL 64K NEXT 1M MINEXTENTS 1 MAXEXTENTS 2147483645 BUFFER_POOL DEFAULT) LOGGING VISIBLE';

        EXECUTE IMMEDIATE 'CREATE INDEX CAA.TP619_IXI ON CAA.TP619 (FGHEN) PCTFREE 10 INITRANS 2 MAXTRANS 255 TABLESPACE USERS STORAGE(INITIAL 64K NEXT 1M MINEXTENTS 1 MAXEXTENTS 2147483645 BUFFER_POOL DEFAULT) LOGGING VISIBLE';

        EXECUTE IMMEDIATE 'CREATE INDEX CAA.TP619_IXJ ON CAA.TP619 (BKNCD, CDKTEI, KIS) PCTFREE 10 INITRANS 2 MAXTRANS 255 TABLESPACE USERS STORAGE(INITIAL 64K NEXT 1M MINEXTENTS 1 MAXEXTENTS 2147483645 BUFFER_POOL DEFAULT) LOGGING VISIBLE';

        EXECUTE IMMEDIATE 'CREATE INDEX CAA.TP619_IXK ON CAA.TP619 (NODOKI) PCTFREE 10 INITRANS 2 MAXTRANS 255 TABLESPACE USERS STORAGE(INITIAL 64K NEXT 1M MINEXTENTS 1 MAXEXTENTS 2147483645 BUFFER_POOL DEFAULT) LOGGING VISIBLE';
        setLog('[END  ] CREATE INDEX TP619',c_SYSID);
        COMMIT;

        RETURN 0;

    EXCEPTION
        WHEN OTHERS THEN
            setLog(SQLERRM(SQLCODE),'ERROR:'|| c_SYSID);
             -- ロールバック実行
            ROLLBACK;
            RETURN -1;
    END getTP619;

    -- ログ更新処理
    PROCEDURE setLog(task IN VARCHAR2,SYSID IN VARCHAR2)
    IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        DELETE FROM LOGTBL WHERE LOGDATE < SYSDATE - 30;
        INSERT INTO LOGTBL VALUES(LOGTBL_SEQNO.NEXTVAL,SYSDATE,task, SYSID);
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE(SQLERRM);
            ROLLBACK;
    END setLog;

END CAAP0003;
/
CREATE OR REPLACE PACKAGE BODY CAP_AUTH_GET AS

/*****************************************************************************/
/***  
チームポータルの権限カテゴリIDとユーザーを指定し、
アクセス権の有無を確認する。

0:暗黙の拒否、1:許可、2:明示的な拒否
***/
/*****************************************************************************/
FUNCTION F_GET_SECG(
    i_AUTHCTGID IN VARCHAR2,--権限カテゴリID
    i_USRSEQ IN NUMBER, --ユーザー管理番号
    i_SSYSTEMID IN VARCHAR2 --サブシステムID
)RETURN VARCHAR2 
AS
    ret CBT_PRMI.PRMI%TYPE;--返却値
    rec CBV_SECG_TABLE := CBV_SECG_TABLE();
BEGIN   
    --初期値は暗黙の拒否
    ret := CONST.PRMI_IMP_DENIAL;
    --「指定したユーザーのセキュリティグループを取得」F_GET_USR_SECGメソッドでパラメータ.ユーザー管理番号のセキュリティグループを取得
    rec := CBP_PRMI_ACS_GET.F_GET_USR_SECG(i_USRSEQ);
    
    FOR row IN (
        SELECT 
            cr.PRMI
        FROM 
            CBT_PRMI cr
            INNER JOIN (
                select 
                    SECGVIEWSEQ 
                from 
                    CBM_SSYSUSE cs 
                where 
                    exists (
                        select 'X' from TABLE(rec) us
                        where cs.SECGVIEWSEQ = us.SECGVIEWSEQ
                    ) 
                    and cs.SSYSTEMID = i_SSYSTEMID 
            ) seq 
            ON seq.SECGVIEWSEQ = cr.SECGVIEWSEQ
            INNER JOIN CBM_AUTH ca 
            ON ca.AUTHID = cr.AUTHID
            AND ca.AUTHCTGID = i_AUTHCTGID  
        ORDER BY PRMI DESC
    ) LOOP
        ret := row.PRMI;
        EXIT;
    END LOOP;

    RETURN ret;
END F_GET_SECG;

/*****************************************************************************/
/***  
チームポータルの権限カテゴリIDとユーザーを指定し、
ユーザの権限一覧を取得する。
***/
/*****************************************************************************/
FUNCTION F_GET_AUTHLIST(
    i_AUTHCTGID IN VARCHAR2,--権限カテゴリID
    i_USRSEQ IN NUMBER,--ユーザー管理番号
    i_SSYSTEMID IN VARCHAR2 --サブシステムID
)RETURN CBT_AUTHLIST
AS
    --カウンタ
    i PLS_INTEGER; 
    ret CBT_AUTHLIST := CBT_AUTHLIST();--返却値
    rec CBV_SECG_TABLE := CBV_SECG_TABLE();
BEGIN
    i := 1;
    --「指定したユーザーのセキュリティグループを取得」F_GET_USR_SECGメソッドでパラメータ.ユーザー管理番号のセキュリティグループを取得
    rec := CBP_PRMI_ACS_GET.F_GET_USR_SECG(i_USRSEQ);
    
    --権限カテゴリIDから権限IDを取得する（複数）
    FOR row IN (
        SELECT 
            auth.AUTHID
        FROM 
            CBM_SSYSUSE cs
            INNER JOIN CBM_SSYSAUTHROLEACS ccs 
            ON ccs.SSYSROLESEQ = cs.SSYSROLESEQ
            AND ccs.PRMI = CONST.PRMI_PERMISSION
            INNER JOIN CBM_AUTH auth 
            ON auth.AUTHID = ccs.AUTHID 
            AND auth.AUTHCTGID = i_AUTHCTGID
        WHERE 
            EXISTS (
                select 'X' from TABLE(rec) ug 
                where ug.SECGVIEWSEQ = cs.SECGVIEWSEQ 
            )
            AND cs.SSYSTEMID = i_SSYSTEMID
        GROUP BY auth.AUTHID
    ) LOOP
        ret.EXTEND;--コレクションの枠追加
        ret(i) := TYPE_AUTHLIST(row.AUTHID);
        i := i + 1;
    END LOOP;
        
    RETURN ret;
END F_GET_AUTHLIST;

/*****************************************************************************/
/***  
チームポータルの権限IDを指定し、
そのロールが付与されているユーザ一覧を取得する。
***/
/*****************************************************************************/
FUNCTION F_GET_AUTHROLE_USR(
    i_AUTHID IN VARCHAR2 --権限ID
)RETURN CBT_AUTHROLE_USR
AS
    --カウンタ
    i PLS_INTEGER;
    ret CBT_AUTHROLE_USR := CBT_AUTHROLE_USR();--返却値
    rec CBM_USR_TABLE := CBM_USR_TABLE();
BEGIN
    i := 1;
    --サブファンクション：指定した権限IDの対象ユーザーを取得
    rec := CAP_AUTH_GET.F_GET_AUTH_USR(i_AUTHID);

    FOR row IN (
        SELECT
            ur.USRSEQ
            ,ur.USRNM
            ,cu.VAL as DPMTNM
        FROM
            TABLE(rec) ur
            INNER JOIN CBT_USRATTRINF cu
            ON cu.USRSEQ = ur.USRSEQ
            AND cu.KEY = 'CBUA_USR_DPMT'
        ORDER BY ur.USRSEQ
    ) LOOP
        ret.EXTEND;--コレクションの枠追加
        ret(i) := TYPE_AUTHROLE_USR(
            row.USRSEQ
            ,row.USRNM
            ,row.DPMTNM
        );
        i := i + 1;
    END LOOP;

    RETURN ret;
END F_GET_AUTHROLE_USR;

--サブファンクション：指定した権限IDの対象ユーザーを取得
--条件マスタによる条件管理はしない
FUNCTION F_GET_AUTH_USR (
  i_AUTHID IN VARCHAR2 --権限ID
) RETURN CBM_USR_TABLE 
AS
    --カウンタ
    i PLS_INTEGER;
    flg PLS_INTEGER;--重複確認用フラグ
    w_SSKUSRSEQ NUMBER;--組織ユーザ管理番号組織ユーザ管理番号
    w_KBNSEQ NUMBER;--区分
    ret CBM_USR_TABLE := CBM_USR_TABLE();--返却値
    rec CBM_SSKMEM_TABLE := CBM_SSKMEM_TABLE();
BEGIN 
    i := 1;
    FOR ROW IN (
        SELECT 
            SSKUSRSEQ
            ,KBNSEQ
        FROM 
            CBV_SECG cvg 
        WHERE 
            EXISTS (
                --SECGVIEWSEQでユーザを紐づけ
                select 
                    'X' 
                from 
                    CBM_SSYSAUTHROLEACS css
                    inner join CBM_SSYSUSE cse 
                    on cse.SSYSROLESEQ = css.SSYSROLESEQ
                where 
                    css.AUTHID = i_AUTHID
                    and css.PRMI = CONST.PRMI_PERMISSION
                    and cse.SECGVIEWSEQ = cvg.SECGVIEWSEQ
            )
    )LOOP
        w_SSKUSRSEQ := ROW.SSKUSRSEQ;
        w_KBNSEQ := ROW.KBNSEQ;
        --ユーザの場合
        IF w_KBNSEQ = CONST.KBN_USR THEN
            FOR row IN (
                SELECT 
                    USRSEQ,USRKBN,MAIL,
                    USRNM,SYKIID,SYKMID,
                    DELFLG,DYSET,DYUPD,
                    USRSET,USRUPD,PRGUPD,
                    VERSION,LCFLG
                FROM 
                    CBM_USR 
                WHERE 
                    USRSEQ = w_SSKUSRSEQ
                    AND DELFLG = CONST.DELFLG_ENA
            ) LOOP
                flg := 0;
                FOR j IN 1..ret.count LOOP
                    IF ret(j).USRSEQ = row.USRSEQ THEN
                        flg := 1 ;
                        EXIT;
                    END IF;
                END LOOP;
                IF flg = 0 THEN    
                    ret.EXTEND;--コレクションの枠追加
                    ret(i) := TYPE_CBM_USR(
                        row.USRSEQ,row.USRKBN,row.MAIL,
                        row.USRNM,row.SYKIID,row.SYKMID,
                        row.DELFLG,row.DYSET,row.DYUPD,
                        row.USRSET,row.USRUPD,row.PRGUPD,
                        row.VERSION,row.LCFLG
                    );
                    i := i + 1;
                END IF;
            END LOOP;    
        END IF;
    
        --組織の場合
        IF w_KBNSEQ = CONST.KBN_SSK THEN
            -- 組織構成マスタから組織区分を取得
            FOR row IN (
                SELECT 
                    SSKKBN
                FROM 
                    CBM_SSKKSI 
                WHERE 
                    SSKSEQ = w_SSKUSRSEQ
                    AND TRUNC(SYSDATE) BETWEEN TKYSTDY AND TKYEDDY
            ) LOOP
                --組織区分がﾌﾟﾗｲﾍﾞｰﾄｸﾞﾙｰﾌﾟ(5)の場合
                IF row.SSKKBN = CONST.SSKKBN_PVT THEN
                	--F_GET_SSK_USRSを呼び出しユーザー一覧を取得する
                    rec := CBP_SSKKNR_SSK_GET.F_GET_SSK_USRS(TRUNC(SYSDATE),w_SSKUSRSEQ);
                ELSE
                --組織区分がﾌﾟﾗｲﾍﾞｰﾄｸﾞﾙｰﾌﾟ(5)以外の場合
                	--F_GET_SSK_ALLUSRを呼び出し配下すべてのユーザー一覧を取得する
                    rec := CBP_SSKKNR_SSK_GET.F_GET_SSK_ALLUSRS(TRUNC(SYSDATE),w_SSKUSRSEQ);  
                END IF;
    
                FOR row2 IN (
                    SELECT 
                        cs.USRSEQ,cs.USRKBN,cs.MAIL,
                        cs.USRNM,cs.SYKIID,cs.SYKMID,
                        cs.DELFLG,cs.DYSET,cs.DYUPD,
                        cs.USRSET,cs.USRUPD,cs.PRGUPD,
                        cs.VERSION,cs.LCFLG
                    FROM 
                        CBM_USR cs
                    WHERE
                        EXISTS (
                            select 'X' from TABLE(rec) USR 
                            where USR.USRSEQ = cs.USRSEQ
                        )
                        AND cs.DELFLG = CONST.DELFLG_ENA
                ) LOOP                                
                    flg := 0;
                    FOR j IN 1..ret.count LOOP
                        IF ret(j).USRSEQ = row2.USRSEQ THEN
                            flg := 1 ;
                            EXIT;
                        END IF;
                    END LOOP;
                    IF flg = 0 THEN
                        ret.EXTEND;--コレクションの枠追加
                        ret(i) := TYPE_CBM_USR(
                            row2.USRSEQ,row2.USRKBN,row2.MAIL,
                            row2.USRNM,row2.SYKIID,row2.SYKMID,
                            row2.DELFLG,row2.DYSET,row2.DYUPD,
                            row2.USRSET,row2.USRUPD,row2.PRGUPD,
                            row2.VERSION,row2.LCFLG
                        );
                        i := i + 1;
                    END IF;
                END LOOP;
            END LOOP;    
        END IF;
    END LOOP;
    
    RETURN ret;
END F_GET_AUTH_USR;


END CAP_AUTH_GET;
/
CREATE OR REPLACE PACKAGE BODY CAP_AUTHLIST_UPDATE
/******************************************************
System	:	コラボレーション
New		:	20181205
Name	:	S.Ito
--------
Mod1	:	
Name	:	
--------
DBLINKで権限を取得するため、実テーブルに保存する
******************************************************/
IS
	--コラボ権限テーブル削除
	FUNCTION DELETE_CAA_AUTHLIST RETURN NUMBER;
	
	--コラボ権限テーブルデータ挿入
	FUNCTION INSERT_CAA_AUTHLIST(
		i_AUTHCTGID IN VARCHAR2,
		i_SSYSTEMID IN VARCHAR2
	) RETURN NUMBER;
	
  
  	--コラボ権限テーブル削除
	FUNCTION DELETE_CBM_SSKMEM( i_USRID IN VARCHAR2 ) RETURN NUMBER;
	
	--コラボ権限テーブルデータ挿入
	FUNCTION INSERT_CBM_SSKMEM( i_USRID IN VARCHAR2) RETURN NUMBER;
  
	/******************************************************
	New		:	20181205
	Name	:	S.Ito
	--------
	Mod1	:	
	Name	:	
	--------
	閲覧権限更新
	******************************************************/
	PROCEDURE UPDATE_AUTHLIST_TBL
	IS
		result NUMBER;
    		CURSOR GET_AUTHLIST_CUR IS
        	select SYSMST_ID.ID AS USRID,
                CASE MST_PORTAL.PRIVILEGE 
                WHEN '01' then 'CSE_SIYOKNR_010'
                WHEN '10' then 'CSE_SIYOKNR_020'
                WHEN '20' then 'CSE_SIYOKNR_020'
                WHEN '30' then 'CSE_SIYOKNR_020'
                
                WHEN '40' then 'CSE_SIYOKNR_010'
                WHEN '50' then 'CSE_SIYOKNR_010'
                WHEN '60' then 'CSE_SIYOKNR_020'
                
                WHEN '90' then 'CSE_SIYOKNR_030'
                WHEN '99' then 'CSE_SIYOKNR_090'
                WHEN '80' then 'CSE_SIYOKNR_021'
                END AS AUTHID
                from SYSMST_ID,MST_PORTAL where MST_PORTAL.LINK = 'CSE1' AND SYSMST_ID.NO = MST_PORTAL.NO 
                
                MINUS 
                select CAA_AUTHLIST.USRID,CAA_AUTHLIST.AUTHID from CAA_AUTHLIST where SSYSTEMID = 'CSE';
                GET_AUTHLIST_REC	GET_AUTHLIST_CUR%ROWTYPE;
	BEGIN
	
  						OPEN GET_AUTHLIST_CUR;
						LOOP
						    FETCH GET_AUTHLIST_CUR INTO GET_AUTHLIST_REC ;
                  EXIT WHEN GET_AUTHLIST_CUR%NOTFOUND OR GET_AUTHLIST_CUR%NOTFOUND IS NULL ;
                  --コラボ権限既存削除と追加
                  result := DELETE_CBM_SSKMEM(GET_AUTHLIST_REC.USRID);
                  result := INSERT_CBM_SSKMEM(GET_AUTHLIST_REC.USRID);
            END LOOP ;

		--コラボ権限テーブル削除
		result := DELETE_CAA_AUTHLIST();
		IF result = -1 THEN
			ROLLBACK;
			RETURN;
		END IF;

		--コラボ権限テーブルデータ挿入
		result := INSERT_CAA_AUTHLIST('CSE_SIYOKNR','CSE');
		IF result = -1 THEN
			ROLLBACK;
			RETURN;
		END IF;
		
		result := INSERT_CAA_AUTHLIST('CCL_SEKNR','CCL');
		IF result = -1 THEN
			ROLLBACK;
			RETURN;
		END IF;
	
		COMMIT;
	
		exception when others then
			dbms_output.put_line('********ERROR********');
			dbms_output.put_line('ErrorCode : ' || sqlcode);
			dbms_output.put_line('ErrorMessage : ' || sqlerrm);
			ROLLBACK;
	
	END UPDATE_AUTHLIST_TBL;

	/******************************************************
	New		:	20181205
	Name	:	S.Ito
	--------
	Mod1	:	
	Name	:	
	--------
	コラボ権限テーブル削除
	******************************************************/
	FUNCTION DELETE_CAA_AUTHLIST RETURN NUMBER
	IS

	BEGIN

		--コラボ権限テーブル削除
		DELETE FROM CAA_AUTHLIST;
	
		RETURN 0;
	
		exception when others then
			dbms_output.put_line('********ERROR********');
			dbms_output.put_line('ErrorCode : ' || sqlcode);
			dbms_output.put_line('ErrorMessage : ' || sqlerrm);
			RETURN -1;
	
	END DELETE_CAA_AUTHLIST;

	/******************************************************
	New		:	20181205
	Name	:	S.Ito
	--------
	Mod1	:	
	Name	:	
	--------
	コラボ権限テーブルデータ挿入
	******************************************************/
	FUNCTION INSERT_CAA_AUTHLIST(
		i_AUTHCTGID IN VARCHAR2,
		i_SSYSTEMID IN VARCHAR2
	) RETURN NUMBER
	IS

	BEGIN

		--コラボ権限テーブルデータ挿入
		FOR recCBM_LGIN IN (
				SELECT
					CBP_UTIL_CSE.USRSEQ_TO_LGINID(CBM_LGIN.USRSEQ) AS LGINID,CBM_LGIN.USRSEQ
				FROM
					CBM_LGIN,CBM_SSKMEM
				WHERE
					NOT CBP_UTIL_CSE.USRSEQ_TO_LGINID(CBM_LGIN.USRSEQ) IS NULL
          AND CBM_LGIN.USRSEQ = CBM_SSKMEM.USRSEQ
          AND CBM_SSKMEM.TKYEDDY > SYSDATE
				GROUP
					BY LGINID,CBM_LGIN.USRSEQ
		) LOOP			
			FOR recAUTHLIST IN (
				SELECT
					AUTHID
				FROM
					TABLE(CAP_AUTH_GET.F_GET_AUTHLIST(i_AUTHCTGID,recCBM_LGIN.USRSEQ,i_SSYSTEMID))
			) LOOP
				--dbms_output.put_line(recAUTHLIST.AUTHID);
				INSERT INTO CAA_AUTHLIST(
					SSYSTEMID
					,AUTHCTGID
					,USRSEQ
					,USRID
					,AUTHID
					,DYSET
					,DYUPD
					,USRSET
					,USRUPD
					,PRGUPD
					,VERSION
				) VALUES (
					i_SSYSTEMID
					,i_AUTHCTGID
					,recCBM_LGIN.USRSEQ
					,recCBM_LGIN.LGINID
					,recAUTHLIST.AUTHID
					,SYSDATE
					,NULL
					,'BATCH'
					,NULL
					,PROGRAM_ID
					,1
				);
			END LOOP;
		END LOOP;
	
		RETURN 0;
	
		exception when others then
			dbms_output.put_line('********ERROR********');
			dbms_output.put_line('ErrorCode : ' || sqlcode);
			dbms_output.put_line('ErrorMessage : ' || sqlerrm);
			RETURN -1;
	
	END INSERT_CAA_AUTHLIST;

	/******************************************************
	New		:	20220906
	Name	:	L.Yi
	--------
	Mod1	:	
	Name	:	
	--------
	コラボ権限テーブル削除
	******************************************************/
	FUNCTION DELETE_CBM_SSKMEM( i_USRID IN VARCHAR2 ) RETURN NUMBER
	IS

	BEGIN

		--コラボ権限テーブル削除(権限変更時の対応)
		DELETE FROM CBM_SSKMEM where USRSEQ = (select USRSEQ from CBM_LGIN where LGINID = i_USRID) and SSKSEQ in (select SSKSEQ from CBM_SSKKSI where SSKSEQ <> '6521' and PSSKSEQ = 6360); --仕様書表示したくない方を除く
	
		RETURN 0;
	
		exception when others then
			dbms_output.put_line('********ERROR********');
			dbms_output.put_line('ErrorCode : ' || sqlcode);
			dbms_output.put_line('ErrorMessage : ' || sqlerrm);
			RETURN -1;
	
	END DELETE_CBM_SSKMEM;

	/******************************************************
	New		:	20220906
	Name	:	L.Yi
	--------
	Mod1	:	
	Name	:	
	--------
	コラボ権限テーブルデータ挿入
	******************************************************/
	FUNCTION INSERT_CBM_SSKMEM( i_USRID IN VARCHAR2) RETURN NUMBER
	IS

	BEGIN

		--コラボ権限テーブルデータ挿入
INSERT INTO CBM_SSKMEM 
(SEQNO,USRSEQ,SSKSEQ,TKYSTDY,TKYEDDY,DYSET,DYUPD,USRSET,USRUPD,PRGUPD,VERSION)
 VALUES
(CBS_SSKMEM_SEQNO.NEXTVAL,(select USRSEQ from CBM_LGIN where LGINID = i_USRID),(
select 
CASE MST_PORTAL.PRIVILEGE 
WHEN '01' then 6361
WHEN '10' then 9421
WHEN '20' then 6362
WHEN '30' then 9420

WHEN '40' then 9423
WHEN '50' then 9424
WHEN '60' then 9425
WHEN '90' then 6363
WHEN '99' then 6364
WHEN '80' then 6366
END AS SSKSEQ
from SYSMST_ID,MST_PORTAL where MST_PORTAL.LINK = 'CSE1' AND SYSMST_ID.NO = MST_PORTAL.NO AND SYSMST_ID.ID = i_USRID),
'0001/01/01','9999/12/31',current_timestamp,current_timestamp,'C28228','C28228','BATCH',1)
;
	
		RETURN 0;
	
		exception when others then
			dbms_output.put_line('********ERROR********');
			dbms_output.put_line('ErrorCode : ' || sqlcode);
			dbms_output.put_line('ErrorMessage : ' || sqlerrm);
			RETURN -1;
	
	END INSERT_CBM_SSKMEM;



END CAP_AUTHLIST_UPDATE;
/
CREATE OR REPLACE PACKAGE BODY HYBS AS

	TM_START TIMESTAMP := NULL;
	TM_LAP   TIMESTAMP := NULL;

	---------------------------------------------------------------------------
	-- エラーメッセージ配列セット関数
	---------------------------------------------------------------------------
	PROCEDURE SET_ERRMSGS
		(P_ERRMSGS	IN OUT	ERR_MSG_ARRAY,
		 P_NO		IN		NUMBER   := NULL,
		 P_KEKKA	IN		NUMBER	 := NULL,
		 P_ID		IN		VARCHAR2 := NULL,
		 P_MSG1		IN		VARCHAR2 := NULL,
		 P_MSG2		IN		VARCHAR2 := NULL,
		 P_MSG3		IN		VARCHAR2 := NULL,
		 P_MSG4		IN		VARCHAR2 := NULL,
		 P_MSG5		IN		VARCHAR2 := NULL )	IS

		V_ERRMSG			ERR_MSG;		-- エラーメッセージオブジェクト
	BEGIN
		-- 引数のエラーメッセージにて、エラーメッセージオブジェクトの初期化
		V_ERRMSG := ERR_MSG(P_NO,P_KEKKA,P_ID,
							SUBSTRB(P_MSG1,1,1000),
							SUBSTRB(P_MSG2,1,1000),
							SUBSTRB(P_MSG3,1,1000),
							SUBSTRB(P_MSG4,1,1000),
							SUBSTRB(P_MSG5,1,1000),
							NULL,NULL  );

		-- エラーメッセージ配列が初期化されていない場合
		IF P_ERRMSGS IS NULL THEN
			-- エラーメッセージ配列の初期化(エラーメッセージのセット)
			P_ERRMSGS := ERR_MSG_ARRAY(V_ERRMSG);

		-- エラーメッセージ配列が最大保持件数以下の場合
		ELSIF P_ERRMSGS.COUNT < P_ERRMSGS.LIMIT THEN
			-- エラーメッセージ配列にNULL要素を追加
			P_ERRMSGS.EXTEND(1);
			-- コピー追加した要素に引数のエラーメッセージオブジェクトを上書き
			P_ERRMSGS(P_ERRMSGS.COUNT) := V_ERRMSG;

		-- エラーメッセージ配列が最大保持件数以上の場合
		ELSE
			RAISE TOO_MANY_ERRORS;
		END IF;
	END SET_ERRMSGS;

	---------------------------------------------------------------------------
	-- エラーメッセージ配列セット関数2 3.8.9.5 (2007/09/29) PG、ステップ名称追加
	---------------------------------------------------------------------------
	PROCEDURE SET_ERRMSGS2
		(P_ERRMSGS	IN OUT	ERR_MSG_ARRAY,
		 P_NO		IN		NUMBER   := NULL,
		 P_KEKKA	IN		NUMBER	 := NULL,
		 P_PG		IN		VARCHAR2 := NULL,
		 P_STEP		IN		VARCHAR2 := NULL,
		 P_ID		IN		VARCHAR2 := NULL,
		 P_MSG1		IN		VARCHAR2 := NULL,
		 P_MSG2		IN		VARCHAR2 := NULL,
		 P_MSG3		IN		VARCHAR2 := NULL,
		 P_MSG4		IN		VARCHAR2 := NULL,
		 P_MSG5		IN		VARCHAR2 := NULL )	IS

		V_ERRMSG			ERR_MSG;		-- エラーメッセージオブジェクト
	BEGIN
		-- 引数のエラーメッセージにて、エラーメッセージオブジェクトの初期化
		V_ERRMSG := ERR_MSG(P_NO,P_KEKKA,P_ID,
							SUBSTRB(P_MSG1,1,1000),
							SUBSTRB(P_MSG2,1,1000),
							SUBSTRB(P_MSG3,1,1000),
							SUBSTRB(P_MSG4,1,1000),
							SUBSTRB(P_MSG5,1,1000),
							P_PG,P_STEP  );

		-- エラーメッセージ配列が初期化されていない場合
		IF P_ERRMSGS IS NULL THEN
			-- エラーメッセージ配列の初期化(エラーメッセージのセット)
			P_ERRMSGS := ERR_MSG_ARRAY(V_ERRMSG);

		-- エラーメッセージ配列が最大保持件数以下の場合
		ELSIF P_ERRMSGS.COUNT < P_ERRMSGS.LIMIT THEN
			-- エラーメッセージ配列にNULL要素を追加
			P_ERRMSGS.EXTEND(1);
			-- コピー追加した要素に引数のエラーメッセージオブジェクトを上書き
			P_ERRMSGS(P_ERRMSGS.COUNT) := V_ERRMSG;

		-- エラーメッセージ配列が最大保持件数以上の場合
		ELSE
			RAISE TOO_MANY_ERRORS;
		END IF;
	END SET_ERRMSGS2;

	---------------------------------------------------------------------------
	-- エラーメッセージ配列最大値オーバーメッセージセット関数
	---------------------------------------------------------------------------
	PROCEDURE SET_LIMITOVER
		(P_ERRMSGS	IN OUT	ERR_MSG_ARRAY) IS
	BEGIN
		P_ERRMSGS(P_ERRMSGS.COUNT).NO   := 0;
		P_ERRMSGS(P_ERRMSGS.COUNT).ID   := 'ERRXXXXX';
		P_ERRMSGS(P_ERRMSGS.COUNT).MSG1 := 'There are too many errors.';
		P_ERRMSGS(P_ERRMSGS.COUNT).MSG2 := NULL;
		P_ERRMSGS(P_ERRMSGS.COUNT).MSG3 := NULL;
		P_ERRMSGS(P_ERRMSGS.COUNT).MSG4 := NULL;
		P_ERRMSGS(P_ERRMSGS.COUNT).MSG5 := NULL;
	END SET_LIMITOVER;

	---------------------------------------------------------------------------
	-- 経過時刻セット関数
	---------------------------------------------------------------------------
	PROCEDURE SET_TIMEMSG
		(P_ERRMSGS	IN OUT	ERR_MSG_ARRAY,
		 P_ID		IN		VARCHAR2 := NULL,
		 P_MSG1		IN		VARCHAR2 := NULL )
	IS
		TM_NOW TIMESTAMP := SYSTIMESTAMP;
	BEGIN
		IF P_ERRMSGS IS NULL THEN TM_START := TM_NOW; TM_LAP := TM_NOW; END IF;

		SET_ERRMSGS(P_ERRMSGS,0,'1',P_ID
						,ltrim(to_char(TM_NOW-TM_LAP  ,'SSSSS.ff5'),'+0 :')
						,ltrim(to_char(TM_NOW-TM_START,'SSSSS.ff5'),'+0 :')
						,P_MSG1);
		TM_LAP := TM_NOW;
	END SET_TIMEMSG;

	---------------------------------------------------------------------------
	-- エラーメッセージ配列出力関数 3.8.9.5 (2007/09/29)
	---------------------------------------------------------------------------
	PROCEDURE OUTPUT_ERRMSGS
		(P_ERRMSGS	IN	ERR_MSG_ARRAY,
		 P_JOBID	IN	VARCHAR2,
		 P_PGNAME	IN	VARCHAR2) IS
	BEGIN
		IF P_ERRMSGS IS NOT NULL THEN
			FOR I IN 1..P_ERRMSGS.COUNT LOOP
				--ログ出力
				LOCAL_MSG_RTN(P_ERRMSGS(I).PG
							,P_ERRMSGS(I).STEP
							,P_ERRMSGS(I).ID || ' ' ||
							 P_ERRMSGS(I).MSG1 || ' ' ||
							 P_ERRMSGS(I).MSG2 || ' ' ||
							 P_ERRMSGS(I).MSG3 || ' ' ||
							 P_ERRMSGS(I).MSG4 || ' ' ||
							 P_ERRMSGS(I).MSG5
							,P_JOBID
							,P_PGNAME);
			END LOOP;
		END IF;
	END OUTPUT_ERRMSGS;

	---------------------------------------------------------------------------
	-- エラーメッセージ配列のステータス最大値取得関数 3.8.9.5 (2007/09/29)
	---------------------------------------------------------------------------
	FUNCTION GET_MAX_KEKKA
		(P_ERRMSGS	IN	ERR_MSG_ARRAY,
		 P_ROWNO	IN	NUMBER := 1
		) RETURN NUMBER -- 4.3.1.1 (2008/10/08) 検索開始行番号を指定できるように修正
	IS
		L_COUNT NUMBER(5) := 0;
		L_KEKKA NUMBER(1) := 0;
	BEGIN
		IF P_ERRMSGS IS NOT NULL THEN
			FOR L_COUNT IN P_ROWNO..P_ERRMSGS.COUNT LOOP
				IF L_KEKKA < P_ERRMSGS(L_COUNT).KEKKA THEN
					L_KEKKA := P_ERRMSGS(L_COUNT).KEKKA;
				END IF;
			END LOOP;
		END IF;
		RETURN L_KEKKA;
	END GET_MAX_KEKKA;

END HYBS;
/
CREATE OR REPLACE PACKAGE BODY LAAP00001 AS
/********************************************************************************
*   システム        :   ハヤブサ共通
*   プログラムＩＤ  :   LAAP00001
*   処理名          :   共通処理系 共通パッケージ
*   作成日          :   2009/02/10
*   作成者          :   S.OKUHIRA
*   更新日/更新者   :
*   更新内容        :
********************************************************************************/

	/********************************************************************************
	*   プログラムＩＤ  :   closeDBLINK
	*   処理名          :   DBリンククローズ処理（セッション内すべて切断）
	*   作成日          :   2009/12/28
	*   作成者          :   S.OKUHIRA
	*   更新日/更新者   :
	*   更新内容        :
	********************************************************************************/
	FUNCTION closeDBLINK RETURN NUMBER
	IS
		-- DBリンク切断件数
		numCnt		NUMBER;

		-- DBリンクカーソル
		CURSOR DBLINK_CUR IS
			SELECT A.DB_LINK				-- DBリンク名
			  FROM V$DBLINK A				-- セッション内DBリンク接続情報
			 INNER JOIN SYS.LINK$ B			-- SYSのリンク情報
			    ON A.DB_LINK = B.NAME
			 WHERE B.FLAG IN ('0', '2');	-- 共有DBリンクでないもの
		DBLINK_CUR_R	DBLINK_CUR%ROWTYPE;

	BEGIN

		-- 切断リンク数を初期化する
		numCnt := 0;

		-- セッションユーザスキーマのDBリンクをすべて切断する
		OPEN DBLINK_CUR;
		LOOP
			FETCH DBLINK_CUR INTO DBLINK_CUR_R;
			EXIT WHEN DBLINK_CUR%NOTFOUND OR DBLINK_CUR%NOTFOUND IS NULL;
				-- データベースリンクを切断する
				numCnt := numCnt + closeDBLINK(DBLINK_CUR_R.DB_LINK);
		END LOOP;
		CLOSE DBLINK_CUR;

		-- DBリンク切断件数を返す
		RETURN numCnt;

	END closeDBLINK;

	/********************************************************************************
	*   プログラムＩＤ  :   closeDBLINK
	*   処理名          :   DBリンククローズ処理（DBリンク名指定）
	*   作成日          :   2009/02/10
	*   作成者          :   S.OKUHIRA
	*   更新日/更新者   :   2009/12/28
	*   更新内容        :   PROCEDUREをFUNCTIONに変更
	********************************************************************************/
	FUNCTION closeDBLINK(
		  inDbLinkNm	IN	VARCHAR2		-- DBリンク名
	) RETURN NUMBER
	IS
	BEGIN

		-- 指定データベースリンクを切断する
		EXECUTE IMMEDIATE 'ALTER SESSION CLOSE DATABASE LINK ' || inDbLinkNm;

		-- 切断した場合、1を返す
		RETURN 1;

	EXCEPTION
		WHEN OTHERS THEN
			-- DBLINK が OPENされていない場合は
			--「ORA-02081: データベース・リンクがオープンしていません。」の例外が発生するが、
			-- この場合は何もする必要がないので exception の catch だけしてスルーする
			-- 切断していないので0を返す
			RETURN 0;

	END closeDBLINK;

END LAAP00001;
/
CREATE OR REPLACE PACKAGE BODY LAAP00002 AS
/********************************************************************************
*   システム        :   ハヤブサ共通(本体)
*   プログラムＩＤ  :   LAAP00002
*   処理名          :   共通処理系 共通パッケージ
*   作成日          :   2009/11/11
*   作成者          :   hiro
*   更新日/更新者   :
*   更新内容        :
********************************************************************************/

	/********************************************************************************
	*   プログラムＩＤ  :   getNmsya
	*   処理名          :   社員マスタより社員名を取得
	*   作成日          :   2009/11/11
	*   作成者          :   hiro
	*   引数            :   ARG1:検索する社員番号
	*                   :   ARG2:コード表示(NULL:非表示, NULL以外:表示)
	*                   :   ARG3:書式(0:氏名, 1:氏, 2:名)
	*                   :   ARG4:言語(ja:日本語, en:英語, zh:簡体, zw:繁体)
	*   更新日/更新者   :
	*   更新内容        :
	********************************************************************************/
	FUNCTION getNmsya
	( inSYAIN IN SYAIN_MST.SYAIN%TYPE
	, inDSPCD IN VARCHAR2 DEFAULT NULL
	, inMODE IN PLS_INTEGER DEFAULT 0
	, inLANG IN VARCHAR2 DEFAULT 'ja'
	) RETURN VARCHAR2 IS
		recData CurNMSYA%ROWTYPE;
		retOutData VARCHAR2(2000);
	BEGIN
		OPEN  curNmsya (inSYAIN);
			FETCH curNmsya INTO recData;
			IF curNMSYA%FOUND = TRUE THEN
				-- 名前
				IF inLANG = 'en' THEN
					retOutData := recData.NMSYA;
				ELSIF inLANG = 'zh' THEN
					retOutData := recData.NMSYA;
				ELSIF inLANG = 'zw' THEN
					retOutData := recData.NMSYA;
				ELSE
					retOutData := recData.NMSYA;
				END IF;
				-- コード表示
				IF inDSPCD IS NOT NULL THEN
					retOutData := inSYAIN || inDSPCD || retOutData;
				END IF;
			END IF;
		CLOSE curNmsya;
		RETURN retOutData;
	EXCEPTION
		WHEN OTHERS THEN
			IF curNmsya%ISOPEN = TRUE THEN
				CLOSE curNmsya;
			END IF;
			RETURN NULL;
	END getNmsya;

	/********************************************************************************
	*   プログラムＩＤ  :   getEmail
	*   処理名          :   社員マスタよりメールアドレスを取得
	*   作成日          :   2009/11/11
	*   作成者          :   hiro
	*   引数            :   ARG1:検索する社員番号
	*                   :   ARG2:名前表示(0:非表示, 1:表示)
	*                   :   ARG3:書式(0:氏名, 1:氏, 2:名)
	*                   :   ARG4:言語(ja:日本語, en:英語, zh:簡体, zw:繁体)
	*   更新日/更新者   :
	*   更新内容        :
	********************************************************************************/
	FUNCTION getEmail
	( inSYAIN IN SYAIN_MST.SYAIN%TYPE
	, inDSPNM IN PLS_INTEGER DEFAULT 0
	, inMODE IN PLS_INTEGER DEFAULT 0
	, inLANG IN VARCHAR2 DEFAULT 'ja'
	) RETURN VARCHAR2 IS
		recData curEmail%ROWTYPE;
		retOutData VARCHAR2(2000);
	BEGIN
		OPEN  curEmail (inSYAIN);
			FETCH curEmail INTO recData;
			IF curEmail%FOUND = TRUE THEN
				-- Email
				retOutData := recData.EMAIL;
				-- 名前表示
				IF inDSPNM IS NOT NULL THEN
					-- 名前
					IF inLANG = 'en' THEN
						retOutData := recData.NMSYA || '<' || retOutData || '>';
					ELSIF inLANG = 'zh' THEN
						retOutData := recData.NMSYA || '<' || retOutData || '>';
					ELSIF inLANG = 'zw' THEN
						retOutData := recData.NMSYA || '<' || retOutData || '>';
					ELSE
						retOutData := recData.NMSYA || '<' || retOutData || '>';
					END IF;
				END IF;
			END IF;
		CLOSE curEmail;
		RETURN retOutData;
	EXCEPTION
		WHEN OTHERS THEN
			IF curEmail%ISOPEN = TRUE THEN
				CLOSE curEmail;
			END IF;
			RETURN NULL;
	END getEmail;

	/********************************************************************************
	*   プログラムＩＤ  :   getBknnm
	*   処理名          :   物件情報より物件名を取得
	*   作成日          :   2009/11/11
	*   作成者          :   hiro
	*   引数            :   ARG1:検索する物件CD
	*                   :   ARG2:コード表示(NULL:非表示, NULL以外:表示)
	*   更新日/更新者   :
	*   更新内容        :
	********************************************************************************/
	FUNCTION getBknnm
	( inBKNCD IN PA21.BKNCD%TYPE
	, inDSPCD IN VARCHAR2 DEFAULT NULL
	) RETURN VARCHAR2 IS
		retOutData VARCHAR2(2000);
	BEGIN
		OPEN  curBknnm (inBKNCD, inDSPCD);
			FETCH curBknnm INTO retOutData;
		CLOSE curBknnm;
		RETURN retOutData;
	EXCEPTION
		WHEN OTHERS THEN
			IF curBknnm%ISOPEN = TRUE THEN
				CLOSE curBknnm;
			END IF;
			RETURN NULL;
	END getBknnm;

	/********************************************************************************
	*   プログラムＩＤ  :   getNonsnm
	*   処理名          :   物件情報より納入先名を取得
	*   作成日          :   2009/11/11
	*   作成者          :   hiro
	*   引数            :   ARG1:検索する物件CD
	*                   :   ARG2:コード表示(NULL:非表示, NULL以外:表示)
	*   更新日/更新者   :
	*   更新内容        :
	********************************************************************************/
	FUNCTION getNonsnm
	( inBKNCD IN PA21.BKNCD%TYPE
	, inDSPCD IN VARCHAR2 DEFAULT NULL
	) RETURN VARCHAR2 IS
		retOutData VARCHAR2(2000);
	BEGIN
		OPEN  curNonsnm (inBKNCD, inDSPCD);
			FETCH curNonsnm INTO retOutData;
		CLOSE curNonsnm;
		RETURN retOutData;
	EXCEPTION
		WHEN OTHERS THEN
			IF curNonsnm%ISOPEN = TRUE THEN
				CLOSE curNonsnm;
			END IF;
			RETURN NULL;
	END getNonsnm;

	/********************************************************************************
	*   プログラムＩＤ  :   getPdnm
	*   処理名          :   大項目マスタより大項目名を取得
	*   作成日          :   2009/11/11
	*   作成者          :   hiro
	*   引数            :   ARG1:検索するシステム
	*                   :   ARG2:検索する言語
	*                   :   ARG3:検索する大項目コード
	*                   :   ARG4:コード表示(NULL:非表示, NULL以外:表示)
	*                   :   ARG5:エラー時の戻り値
	*   更新日/更新者   :   2010/09/15	S.OKUHIRA
	*   更新内容        :   エラー時の戻り値を設定できるよう変更
	********************************************************************************/
	FUNCTION getPdnm
	( inSYSTEM_ID IN MST01.SYSTEM_ID%TYPE
	, inLANG      IN MST01.LANG%TYPE
	, inPDSEQ     IN MST01.PDSEQ%TYPE
	, inDSPCD     IN VARCHAR2 DEFAULT NULL
	, inRTNERR    IN VARCHAR2 DEFAULT NULL
	) RETURN VARCHAR2 IS
		retOutData VARCHAR2(2000);
	BEGIN
		retOutData := inRTNERR;
		OPEN  curPdnm (inSYSTEM_ID, inLANG, inPDSEQ, inDSPCD);
			FETCH curPdnm INTO retOutData;
		CLOSE curPdnm;
		RETURN retOutData;
	EXCEPTION
		WHEN OTHERS THEN
			IF curPdnm%ISOPEN = TRUE THEN
				CLOSE curPdnm;
			END IF;
			RETURN inRTNERR;
	END getPdnm;

	/********************************************************************************
	*   プログラムＩＤ  :   getPsnm
	*   処理名          :   中項目マスタより中項目名を取得
	*   作成日          :   2009/11/11
	*   作成者          :   hiro
	*   引数            :   ARG1:検索するシステム
	*                   :   ARG2:検索する言語
	*                   :   ARG3:検索する大項目コード
	*                   :   ARG4:検索する中項目コード
	*                   :   ARG5:コード表示(NULL:非表示, NULL以外:表示)
	*                   :   ARG6:エラー時の戻り値
	*   更新日/更新者   :   2010/09/15	S.OKUHIRA
	*   更新内容        :   エラー時の戻り値を設定できるよう変更
	********************************************************************************/
	FUNCTION getPsnm
	( inSYSTEM_ID IN MST02.SYSTEM_ID%TYPE
	, inLANG      IN MST02.LANG%TYPE
	, inPDSEQ     IN MST02.PDSEQ%TYPE
	, inPSSEQ     IN MST02.PSSEQ%TYPE
	, inDSPCD     IN VARCHAR2 DEFAULT NULL
	, inRTNERR    IN VARCHAR2 DEFAULT NULL
	) RETURN VARCHAR2 IS
		retOutData VARCHAR2(2000);
	BEGIN
		retOutData := inRTNERR;
		OPEN  curPsnm (inSYSTEM_ID, inLANG, inPDSEQ, inPSSEQ, inDSPCD);
			FETCH curPsnm INTO retOutData;
		CLOSE curPsnm;
		RETURN retOutData;
	EXCEPTION
		WHEN OTHERS THEN
			IF curPsnm%ISOPEN = TRUE THEN
				CLOSE curPsnm;
			END IF;
			RETURN inRTNERR;
	END getPsnm;

	/********************************************************************************
	*   プログラムＩＤ  :   getPmnm
	*   処理名          :   小項目マスタより小項目名を取得
	*   作成日          :   2009/11/11
	*   作成者          :   hiro
	*   引数            :   ARG1:検索するシステム
	*                   :   ARG2:検索する言語
	*                   :   ARG3:検索する大項目コード
	*                   :   ARG4:検索する中項目コード
	*                   :   ARG5:検索する小項目コード
	*                   :   ARG6:コード表示(NULL:非表示, NULL以外:表示)
	*                   :   ARG7:エラー時の戻り値
	*   更新日/更新者   :   2010/09/15	S.OKUHIRA
	*   更新内容        :   エラー時の戻り値を設定できるよう変更
	********************************************************************************/
	FUNCTION getPmnm
	( inSYSTEM_ID IN MST03.SYSTEM_ID%TYPE
	, inLANG      IN MST03.LANG%TYPE
	, inPDSEQ     IN MST03.PDSEQ%TYPE
	, inPSSEQ     IN MST03.PSSEQ%TYPE
	, inPMSEQ     IN MST03.PMSEQ%TYPE
	, inDSPCD     IN VARCHAR2 DEFAULT NULL
	, inRTNERR    IN VARCHAR2 DEFAULT NULL
	) RETURN VARCHAR2 IS
		retOutData VARCHAR2(2000);
	BEGIN
		retOutData := inRTNERR;
		OPEN  curPmnm (inSYSTEM_ID, inLANG, inPDSEQ, inPSSEQ, inPMSEQ, inDSPCD);
			FETCH curPmnm INTO retOutData;
		CLOSE curPmnm;
		RETURN retOutData;
	EXCEPTION
		WHEN OTHERS THEN
			IF curPmnm%ISOPEN = TRUE THEN
				CLOSE curPmnm;
			END IF;
			RETURN inRTNERR;
	END getPmnm;


	/********************************************************************************
	*   プログラムＩＤ  :   GETLBLNAME
	*   処理名          :   ラベルリソース取得
	*   作成日          :   2013/08/06
	*   作成者          :   D.TSUTSUMI
	*   補足            :   井上さんが作成したファンクションを流用
	********************************************************************************/
	FUNCTION GETLBLNAME (
		  inSYSTEM_ID	IN	VARCHAR2				-- システムID
		, inLANG		IN	VARCHAR2				-- 言語
		, inCLM			IN	VARCHAR2				-- カラム
		, inLBLTYPE		IN	VARCHAR2 DEFAULT '0'	-- 0:名前(長)  1:名前(短)
	) RETURN VARCHAR2 IS

	retOutData		GEA08.LNAME%TYPE;
	getLNAME		GEA08.LNAME%TYPE;
	getSNAME		GEA08.SNAME%TYPE;

	BEGIN
		SELECT LNAME, SNAME INTO getLNAME, getSNAME
		FROM	GEA08
		WHERE	SYSTEM_ID	= inSYSTEM_ID
		AND		LANG		= inLANG
		AND		CLM			= inCLM
		AND		FGJ			= '1';


		retOutData := getLNAME;
		IF inLBLTYPE = '1' AND getSNAME IS NOT NULL THEN
			-- 『名前(短)』を設定。但し『名前(短)』が設定されていなければ『名前(長)』を返す
			retOutData := getSNAME;
		END IF;

		RETURN retOutData;

	EXCEPTION
		WHEN OTHERS THEN
			RETURN NULL;

	END GETLBLNAME;



	/********************************************************************************
	*   プログラムＩＤ  :   DATE_CHECK
	*   処理名          :   村田日付チェック
	*   作成日          :   2013/10/21
	*   作成者          :   AIKO.INOUE
	*   補足            :
	********************************************************************************/
	FUNCTION DATE_CHECK (
		  inCLNDY		IN	VARCHAR2				-- カレンダ日付
	) RETURN VARCHAR2 IS

	retOutData		GEA08.LNAME%TYPE;
	L_TQKBN			LAA01.TQKBN%TYPE;

	BEGIN
		SELECT	TQKBN
		INTO	L_TQKBN
		FROM	LAA01
		WHERE	CLNDY 		= inCLNDY;

		-- 定休日チェック
		IF L_TQKBN = '1' THEN
			retOutData := '1';
		END IF;
		RETURN retOutData;

	EXCEPTION
		WHEN OTHERS THEN
			RETURN NULL;

	END DATE_CHECK;

END LAAP00002;
/
CREATE OR REPLACE PACKAGE BODY RGP10212
AS
	strTMSET	RG11.TMSET%TYPE		:= TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS');
	strPRGUPD	RG11.PRGUPD%TYPE	:= 'RGP10212';
	w_l		NUMBER;

	ERR001	EXCEPTION;	--異常定義
/********************************************************************************/
/*	C H E C K _  D B															*/
/********************************************************************************/
	PROCEDURE CHECK_DB
	(
		P_KEKKA			OUT	NUMBER			-- エラー結果(0:正常 1:警告 2:異常)
		,P_ERRMSGS		OUT	ERR_MSG_ARRAY	-- エラーのあるときのエラーメッセージ配列
		,P_NAMES		IN	VARCHAR2
		,P_SYSARGS		IN	SYSARG_ARRAY	-- 引数 SYSTEMデータ
		,P_RG0212ARG	IN	RG0212ARG_ARRAY	-- 引数 USERデータ
	)
	IS
	kmz VARCHAR2(20);
	P_FGED RG11.FGED%TYPE	:= '0'		;
	P_COUNT2	number					;
	P_COUNT3	number					;
	P_FGHBN		RG08.FGHBN%TYPE			;
	P_KBNHT		RG08.KBNHT%TYPE			;
	P_FSNNO		RG35.FSNNO%TYPE			;
	P_KO		RG35.KO%TYPE			;
	P_PN		RG35.OYA%TYPE			;
	wk_CNT		number					;

	CURSOR CUR1 IS SELECT FSNNO,KO FROM TABLE(RGP00009.FETCH_RG103(P_PN,'0'))X,RG08 Y
		WHERE FGHBN = '1' 
		AND X.KO = Y.PN
		AND	NVL(KAIHAI,'-')	!=	'D'
		AND FSNNO != 'C';

	CURSOR CUR2 IS SELECT FSNNO,KO FROM TABLE(RGP00009.FETCH_RG103(P_PN,'0'))
		WHERE SU IS NULL AND FSNNO NOT IN ('C','Z');

	BEGIN

		-- 70件以上の一括出図はエラー 20050727 T.NASU
		IF P_SYSARGS.COUNT > 70 THEN
			HYBS.SET_ERRMSGS (
				P_ERRMSGS			-- エラーメッセージ配列
				,1					-- 行番号
				,2					-- エラー結果(0:正常 1:警告 2:異常)
				,'RGE2167'			-- 一度に出図できるのは７０件までです。
				,'70'
			);
			P_KEKKA := 2;
			RETURN;
		END IF;

		FOR  I IN 1..P_SYSARGS.COUNT LOOP
			w_l := I;
			/* 旧データIDチェック */
			BEGIN
				IF P_RG0212ARG(I).OLDID IS NOT NULL THEN
					HYBS.SET_ERRMSGS (
						P_ERRMSGS			-- エラーメッセージ配列
						,P_SYSARGS(I).NO	-- 行番号
						,2					-- エラー結果(0:正常 1:警告 2:異常)
						,'RGM1206'			-- 現行部品表から出図されている標準PLは出図できません。PL = {0}
						,P_RG0212ARG(I).PN
					);
					P_KEKKA := 2;
					RETURN;
				END IF;
			EXCEPTION
				WHEN OTHERS THEN
					BEGIN
					LOGOUT(
					212
					,'RGP10212'
					,2
					,SUBSTR(SQLERRM,1,100)
					,'CHECK_DB　旧データIDチェックエラー'
					,SUBSTR(SQLCODE ,1,100)
					,'品番=' || P_RG0212ARG(I).PN || ',旧データID=' || P_RG0212ARG(I).OLDID
					);
					END;
			END;

			/* #品番チェック */
			BEGIN
				IF INSTR(P_RG0212ARG(I).PN,'*') > 0 OR INSTR(P_RG0212ARG(I).PN,'#') > 0 THEN
					HYBS.SET_ERRMSGS (
						P_ERRMSGS			-- エラーメッセージ配列
						,P_SYSARGS(I).NO	-- 行番号
						,2					-- エラー結果(0:正常 1:警告 2:異常)
						,'RGE2045'			-- #品番は出図できません。キー{0}
						,P_RG0212ARG(I).PN
					);
					P_KEKKA := 2;
				END IF;
			EXCEPTION
				WHEN OTHERS THEN
					BEGIN
					LOGOUT(
					212
					,'RGP10212'
					,2
					,SUBSTR(SQLERRM,1,100)
					,'CHECK_DB　#品番チェックエラー'
					,SUBSTR(SQLCODE ,1,100)
					,'品番=' || P_RG0212ARG(I).PN
					);
					END;
			END;

			/* 廃番チェック */
			BEGIN
				SELECT FGHBN INTO P_FGHBN FROM RG08 WHERE PN = P_RG0212ARG(I).PN;
				IF P_FGHBN = '1' THEN
					HYBS.SET_ERRMSGS (
						P_ERRMSGS
						,P_SYSARGS(I).NO
						,2
						,'RGE2074'			-- 廃番になっているPLは出図できません。PL NO={0}
						,P_RG0212ARG(I).PN
						);
					P_KEKKA := 2;
				END IF;
			EXCEPTION
				WHEN OTHERS THEN
					BEGIN
					LOGOUT(
					212
					,'RGP10212'
					,2
					,SUBSTR(SQLERRM,1,100)
					,'CHECK_DB　廃番チェックエラー'
					,SUBSTR(SQLCODE ,1,100)
					,'品番=' || P_RG0212ARG(I).PN
					);
					END;
			END;

			/* 標準特殊チェック */
			BEGIN
				SELECT KBNHT INTO P_KBNHT FROM RG08 WHERE PN = P_RG0212ARG(I).PN AND KBNPN = '1';
				IF P_KBNHT = '1' THEN
					HYBS.SET_ERRMSGS (
						P_ERRMSGS
						,P_SYSARGS(I).NO
						,2
						,'RGE2075'			-- SP PLは出図できません。キー{0}
						,P_RG0212ARG(I).PN
						);
					P_KEKKA := 2;
				END IF;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					NULL;
				WHEN OTHERS THEN
					BEGIN
					LOGOUT(
					212
					,'RGP10212'
					,2
					,SUBSTR(SQLERRM,1,100)
					,'CHECK_DB　標準特殊チェックエラー'
					,SUBSTR(SQLCODE ,1,100)
					,'品番=' || P_RG0212ARG(I).PN
					);
					END;
			END;


			/* 機構別部品明細表ヘッダ存在チェック */
			BEGIN
				SELECT COUNT(*) INTO P_COUNT2 FROM RG11 WHERE PL = P_RG0212ARG(I).PN ;

				IF P_COUNT2 = 0 THEN
					HYBS.SET_ERRMSGS (
						P_ERRMSGS
						,P_SYSARGS(I).NO
						,2
						,'RGE2047'			-- 標準構成ヘッダが登録されていません。PL NO={0}
						,P_RG0212ARG(I).PN
						);
					P_KEKKA := 2;
				/* ELSE */
					/* --- 組図NO自動登録機能削除 修正リクエスト133
					SELECT KMZNO INTO kmz FROM RG11 WHERE PL = P_RG0212ARG(I).PN ;

					IF kmz IS NULL THEN
						UPDATE RG11 --ヘッダに組図NOを登録
						SET KMZNO = P_RG0212ARG(I).PN
						WHERE PL = P_RG0212ARG(I).PN;

						UPDATE RG08 -- 品番マスタにも反映
						SET FGRZM = '1',
						ZUBAN  = P_RG0212ARG(I).PN
						WHERE PN = P_RG0212ARG(I).PN;

						HYBS.SET_ERRMSGS (
						P_ERRMSGS
						,P_SYSARGS(I).NO
						,2
						,'RGE0082'			-- 組図NOが登録されていません　PL NO{0}
						,P_RG0212ARG(I).PN
						);
						P_KEKKA := 2;

					END IF ;
					*/
				END IF;
			EXCEPTION
				WHEN OTHERS THEN
					BEGIN
					LOGOUT(
					212
					,'RGP10212'
					,2
					,SUBSTR(SQLERRM,1,100)
					,'CHECK_DB　機構別部品明細表ヘッダ存在チェックエラー'
					,SUBSTR(SQLCODE ,1,100)
					,'品番=' || P_RG0212ARG(I).PN
					);
					END;
			END;

			/* 編集フラグチェック */
			BEGIN
				SELECT FGED INTO P_FGED FROM RG11 WHERE PL = P_RG0212ARG(I).PN;
				IF P_FGED = '1' THEN
					NULL;
				ELSE
					IF RGP00001.GET_KBNPN(P_RG0212ARG(I).PN) = '1' THEN
						SELECT	COUNT(*)
						INTO	P_COUNT3
						FROM	RG08 A,
								RG103 B
						WHERE	A.PN				=	B.KO
						AND		A.KBNPN				=	'2'
						AND		A.KBNHT				IN	('0','1')
						AND		NVL(A.FGHBN,'0')	!=	'1'
						AND		B.OYA				=	P_RG0212ARG(I).PN
						AND		B.FSNNO				!=	'C'
						AND		B.DYEND				=	'99999999'
						AND		NVL(B.KAIHAI,'-')	!=	'D'
						AND		NVL(B.KORVSN,0)		<	NVL(RGP00010.GET_RVSN(B.KO),0);
						IF P_COUNT3 > 0 THEN
							-- 未出図のROOT行が存在しない場合、ROOT行作成(下位に古い40品番を持つPLは編集中にしてしまう)
							SELECT	/*+ INDEX(RG103 RG103_SB) */
									COUNT(SEQ)
							INTO	wk_CNT
							FROM	RG103
							WHERE	OYA		= 'ROOT'
							AND		KO		= P_RG0212ARG(I).PN	
							AND		DYSTR	= '99999999'
							AND		DYEND	= '99999999';

							IF wk_CNT = 0 THEN
								INSERT INTO RG103(
									SEQ							,
									OYA							,KO							,
									KORVSN						,
									SU							,
									DYSTR						,DYEND						,
									SEQNO						,KBNSSR						,
									TMSET						,TMUPD						,
									USRSET						,USRUPD						,
									PRGSET						,PRGUPD
								) VALUES(
									RG03S01.NEXTVAL				,
									'ROOT'						,P_RG0212ARG(I).PN			,
									RGP00010.GET_RVSN(P_RG0212ARG(I).PN)					,
									1							,
									'99999999'					,'99999999'					,
									1							,'0'						,
									strTMSET					,strTMSET					,
									P_RG0212ARG(I).USRSET		,P_RG0212ARG(I).USRSET		,
									strPRGUPD					,strPRGUPD
								);
							END IF;

							UPDATE	RG11
							SET		FGED	=	'1'
							WHERE	PL		=	P_RG0212ARG(I).PN;
						ELSE
							HYBS.SET_ERRMSGS (
								P_ERRMSGS				,
								P_SYSARGS(I).NO			,
								2						,
								'RGE2053'				,	-- 編集されていない標準PLは、出図できません。PL NO={0}
								P_RG0212ARG(I).PN
							);
							P_KEKKA := 2;
						END IF;
					ELSE
						HYBS.SET_ERRMSGS (
							P_ERRMSGS					,
							P_SYSARGS(I).NO				,
							2							,
							'RGE2053'					,	-- 編集されていない標準PLは、出図できません。PL NO={0}
							P_RG0212ARG(I).PN
						);
						P_KEKKA := 2;
					END IF;
				END IF;
			EXCEPTION
				WHEN OTHERS THEN
					LOGOUT(
						212
						,'RGP10212'
						,2
						,SUBSTR(SQLERRM,1,100)
						,'CHECK_DB　編集フラグチェックエラー'
						,SUBSTR(SQLCODE ,1,100)
						,'品番=' || P_RG0212ARG(I).PN
					);
			END;

			/* 図面存在チェック */
			/*
			BEGIN
				SELECT COUNT(*) INTO P_COUNT3 FROM RG54 WHERE PN LIKE P_RG0212ARG(I).PN||'%' ;

				IF P_COUNT3 = 0 THEN
					HYBS.SET_ERRMSGS (
						P_ERRMSGS
						,P_SYSARGS(I).NO
						,2
						,'RGE2048'			-- 図面が登録されていません。PL NO={0}
						,P_RG0212ARG(I).PN
						);
					P_KEKKA := 2;
				END IF;
			EXCEPTION
				WHEN OTHERS THEN
					BEGIN
					LOGOUT(
					212
					,'RGP10212'
					,2
					,SUBSTR(SQLERRM,1,100)
					,'CHECK_DB　図面存在チェックエラー'
					,SUBSTR(SQLCODE ,1,100)
					,'品番=' || P_RG0212ARG(I).PN
					);
					END;
			END;
			*/

			/* 構成存在チェック */
			BEGIN
				SELECT	COUNT(*)
				INTO	P_COUNT2
				FROM	RG103
				WHERE	OYA				=	P_RG0212ARG(I).PN
				AND		DYEND			=	'99999999'
				AND		NVL(KAIHAI,' ')	!=	'D';
			EXCEPTION
				WHEN OTHERS THEN
					BEGIN
					LOGOUT(
					212
					,'RGP10212'
					,2
					,SUBSTR(SQLERRM,1,100)
					,'CHECK_DB　構成存在チェックエラー'
					,SUBSTR(SQLCODE ,1,100)
					,'品番=' || P_RG0212ARG(I).PN
					);
					END;
			END;

			/* 行を追加し、同じ行を削除した場合など、DYSTRが'99999999'のデータがなくなり、出図できなくなるので廃止
			BEGIN
				SELECT COUNT(*) INTO P_COUNT2 FROM RG103
					WHERE
						OYA		=	P_RG0212ARG(I).PN AND
						FSNNO	!=	'C'			AND
						DYSTR	=	'99999999'	AND
						DYEND	=	'99999999'	;

				IF P_COUNT2 = 0 THEN
					HYBS.SET_ERRMSGS (
						P_ERRMSGS
						,P_SYSARGS(I).NO
						,2
						,'RGE2003')			-- 標準部品表に下位構成が未登録。
					P_KEKKA := 2;
				END IF;
			EXCEPTION
				WHEN OTHERS THEN
					BEGIN
					LOGOUT(
					212
					,'RGP10212'
					,2
					,SUBSTR(SQLERRM,1,100)
					,'CHECK_DB　下位構成未登録構エラー'
					,SUBSTR(SQLCODE ,1,100)
					,'品番=' || P_RG0212ARG(I).PN
					);
					END;
			END;
			*/

			/* 構成廃番フラグ存在チェック */
			BEGIN
				SELECT
					COUNT(*) INTO P_COUNT2
				FROM TABLE(RGP00009.FETCH_RG103(P_RG0212ARG(I).PN,'0'))X,RG08 Y
				WHERE FGHBN	=	'1'
				AND	X.KO	=	Y.PN
				AND	NVL(KAIHAI,'-')	!=	'D'
				AND	X.FSNNO != 'C';

				IF P_COUNT2 > 0 THEN
					HYBS.SET_ERRMSGS (
						P_ERRMSGS
						,P_SYSARGS(I).NO
						,2
						,'RGE2078'			-- 構成の中に、廃番になっている品番が登録されています。PL NO={0}
						,P_RG0212ARG(I).PN
						);

					P_PN :=P_RG0212ARG(I).PN;

					OPEN CUR1;
					LOOP
						FETCH CUR1 INTO P_FSNNO,P_KO;

						EXIT WHEN CUR1%NOTFOUND;

						HYBS.SET_ERRMSGS (
							P_ERRMSGS
							,P_SYSARGS(I).NO
							,2
							,'RGE2080'			-- 廃番になっている品番 = {0}　風船NO = {1}　PL NO = {2}
							,P_KO
							,P_FSNNO
							,P_PN
							);

					END LOOP;

					CLOSE CUR1;
					P_KEKKA := 2;
				END IF;
			EXCEPTION
				WHEN OTHERS THEN
					BEGIN
					LOGOUT(
					212
					,'RGP10212'
					,2
					,SUBSTR(SQLERRM,1,100)
					,'CHECK_DB　構成廃番フラグ存在チェックエラー'
					,SUBSTR(SQLCODE ,1,100)
					,'品番=' || P_RG0212ARG(I).PN
					);
					END;
			END;

			/* 構成数量NULLチェック */
			--補材対応 2004/06/11
			BEGIN
				SELECT
					COUNT(*) INTO P_COUNT2
				FROM TABLE(RGP00009.FETCH_RG103(P_RG0212ARG(I).PN,'0'))
				WHERE
					SU		IS NULL				AND
					FSNNO	!=	'C'				AND
					SUBSTR(FSNNO,1,1) != 'Z'	AND
					KO IS NOT NULL				;

				IF P_COUNT2 > 0 THEN
					HYBS.SET_ERRMSGS (
						P_ERRMSGS
						,P_SYSARGS(I).NO
						,2
						,'RGE2079'	-- 構成の中に、コメント・図面品番以外で、数量が登録されていない品番が存在します。PL NO={0}
						,P_RG0212ARG(I).PN
						);

					P_PN :=P_RG0212ARG(I).PN;

					OPEN CUR2;
					LOOP
						FETCH CUR2 INTO P_FSNNO,P_KO;

						EXIT WHEN CUR2%NOTFOUND;

						HYBS.SET_ERRMSGS (
							P_ERRMSGS
							,P_SYSARGS(I).NO
							,2
							,'RGE2081'			-- 数量が登録されていない品番 = {0}　風船NO = {1}　PL NO = {2}
							,P_KO
							,P_FSNNO
							,P_PN
							);

					END LOOP;

					CLOSE CUR2;

					P_KEKKA := 2;
				END IF;

			EXCEPTION
				WHEN OTHERS THEN
					BEGIN
					LOGOUT(
					212
					,'RGP10212'
					,2
					,SUBSTR(SQLERRM,1,100)
					,'CHECK_DB　構成数量NULLチェックエラー'
					,SUBSTR(SQLCODE ,1,100)
					,'品番=' || P_RG0212ARG(I).PN
					);
					END;
			END;

		END LOOP;


	END CHECK_DB;
/********************************************************************************/
/*	I N S E R T _ D B															*/
/********************************************************************************/
	PROCEDURE INSERT_DB
	(
		P_KEKKA		OUT	NUMBER			-- エラー結果(0:正常 1:警告 2:異常)
		,P_ERRMSGS	OUT	ERR_MSG_ARRAY	-- エラーのあるときのエラーメッセージ配列
		,P_COUNT	IN	NUMBER			-- 行番号
		,P_SYS		IN	SYSARG			-- 引数 SYSTEMデータ
		,P_RG0212	IN	RG0212ARG		-- 引数 USERデータ
	)
	IS
	P_COUNT2 number;
	P_COUNT3 number;
	BEGIN
		/* 旧データクリア */
		BEGIN
			IF P_COUNT = 1 THEN
				P_COUNT2 := 0;
				SELECT COUNT(*) INTO P_COUNT2 FROM RGW025 WHERE DSEQ = P_RG0212.DSEQ;
				IF P_COUNT2 != 0 THEN
					DELETE RGW025 WHERE DSEQ = P_RG0212.DSEQ;
				END IF;

				P_COUNT2 := 0;
				SELECT COUNT(*) INTO P_COUNT2 FROM RGW027 WHERE DSEQ = P_RG0212.DSEQ;
				IF P_COUNT2 != 0 THEN
					DELETE RGW027 WHERE DSEQ = P_RG0212.DSEQ;
				END IF;

				P_COUNT2 := 0;
				SELECT COUNT(*) INTO P_COUNT2 FROM RGW028 WHERE DSEQ = P_RG0212.DSEQ;
				IF P_COUNT2 != 0 THEN
					DELETE RGW028 WHERE DSEQ = P_RG0212.DSEQ;
				END IF;

				P_COUNT2 := 0;
				SELECT COUNT(*) INTO P_COUNT2 FROM RGW029 WHERE DSEQ = P_RG0212.DSEQ;
				IF P_COUNT2 != 0 THEN
					DELETE RGW029 WHERE DSEQ = P_RG0212.DSEQ;
				END IF;

				P_COUNT2 := 0;
				SELECT COUNT(*) INTO P_COUNT2 FROM RGW030 WHERE DSEQ = P_RG0212.DSEQ;
				IF P_COUNT2 != 0 THEN
					DELETE RGW030 WHERE DSEQ = P_RG0212.DSEQ;
				END IF;

			END IF ;
		EXCEPTION
			WHEN OTHERS THEN
				BEGIN
				LOGOUT(
				212
				,'RGP10212'
				,2
				,SUBSTR(SQLERRM,1,100)
				,'INSERT_DB　旧データクリア'
				,SUBSTR(SQLCODE ,1,100)
				,'DSEQ=' || P_RG0212.DSEQ
				);
				END;
		END;
		/*** 選択されたPLを登録 ***/
		BEGIN
			INSERT INTO RGW025
			(
				DSEQ				--DSEQ
				,STDPL				--PL NO
				,TMSET				--登録日時
				,TMUPD				--更新日時
				,USRSET				--登録者
				,USRUPD				--更新者
				,PRGSET				--登録ＰＲＧ
				,PRGUPD				--更新ＰＲＧ
			)
			VALUES
			(
				P_RG0212.DSEQ		--DSEQ
				,P_RG0212.PN		--PL NO
				,strTMSET			--登録日時
				,strTMSET			--更新日時
				,P_RG0212.USRSET	--登録者
				,P_RG0212.USRSET	--更新者
				,strPRGUPD			--登録ＰＲＧ
				,strPRGUPD			--更新ＰＲＧ
			);
		EXCEPTION
			WHEN OTHERS THEN
				BEGIN
				LOGOUT(
				212
				,'RGP10212'
				,2
				,SUBSTR(SQLERRM,1,100)
				,'INSERT_DB　ワークテーブルRGW025追加エラー'
				,SUBSTR(SQLCODE ,1,100)
				,'DSEQ=' || P_RG0212.DSEQ || ' ' || 'PL NO=' || P_RG0212.PN
				);
				END;
		END;
		P_KEKKA := 0;

	EXCEPTION
		WHEN OTHERS THEN
			BEGIN
			LOGOUT(
			212
			,'RGP10212'
			,2
			,SUBSTR(SQLERRM,1,100)
			,'INSERT_DB　エラー'
			,SUBSTR(SQLCODE ,1,100)
			,'DSEQ=' || P_RG0212.DSEQ || ' ' || 'PL NO=' || P_RG0212.PN
			);
			END;
	END INSERT_DB;

/********************************************************************************/
/*	C O M M O N _ F U N C _ D B													*/
/********************************************************************************/
	PROCEDURE COMMON_FUNC_DB
	(
		P_KEKKA		OUT	NUMBER			-- エラー結果(0:正常 1:警告 2:異常)
		,P_ERRMSGS	OUT	ERR_MSG_ARRAY	-- エラーのあるときのエラーメッセージ配列
		,P_COUNT	IN	NUMBER			-- 行番号
		,P_SYS		IN	SYSARG			-- 引数 SYSTEMデータ
		,P_RG0212	IN	RG0212ARG		-- 引数 USERデータ
	)
	IS
	p_syrno VARCHAR2(7) ;
	p_synn	RGW026.synn%type;
	p_sysa	RGW026.sysa%type;
	P_NMBK	RG60.NMBK%TYPE;
	P_DSEQ	RGW030.DSEQ%TYPE;
	P_STDPL	RGW025.STDPL%TYPE;
	P_COUNT2	NUMBER;
	CURSOR CUR_RGW030_1 IS SELECT DSEQ,STDPL FROM RGW030 WHERE DSEQ = P_DSEQ GROUP BY DSEQ,STDPL ORDER BY STDPL;
	CURSOR CUR_RGW030_2 IS SELECT DSEQ,STDPL,PNOD,PNNW FROM RGW030 WHERE DSEQ = P_DSEQ AND STDPL = P_STDPL ORDER BY FSNNO;
	BEGIN
		BEGIN
			SELECT	NMBK
			INTO	P_NMBK
			FROM	RG60
			WHERE	USERID = P_RG0212.USRSET;
		EXCEPTION
			WHEN OTHERS THEN
				LOGOUT(
				212
				,'RGP10212'
				,2
				,SUBSTR(SQLERRM,1,100)
				,'COMMON_FUNC　部署取得エラー'
				,SUBSTR(SQLCODE ,1,100)
				,'DSEQ=' || P_RG0212.DSEQ
				);
		END;
		SELECT	COUNT(*)
		INTO	P_COUNT2
		FROM	RGW026
		WHERE	USRSET = P_RG0212.USRSET;
		IF P_COUNT2 = 0 THEN
			/* 出図連絡箋WKにデータ挿入 */
			BEGIN
			
				INSERT INTO RGW026
				(
					DSEQ			--DSEQ
					,KBNHNK			--変更理由
					,FGSHTK			--水平展開要否
					,NMBK			--部署
					,TMSET			--登録日時
					,TMUPD			--更新日時
					,USRSET			--登録者
					,USRUPD			--更新者
					,PRGSET			--登録ＰＲＧ
					,PRGUPD			--更新ＰＲＧ
				)
				VALUES
				(
					P_RG0212.DSEQ
					,NULL			--修正リクエストNO20167対応
				--	,'8'			--0:設計ミス 1:SEミス 2:客先起因 3:製造ミス 4: 5: 6: 7: 8:その他 9:工事ミス
					,'0'			--0:不要 1:必要
					,P_NMBK
					,strTMSET
					,strTMSET
					,P_RG0212.USRSET
					,P_RG0212.USRSET
					,strPRGUPD
					,strPRGUPD
				);
			EXCEPTION
				WHEN OTHERS THEN
					BEGIN
					LOGOUT(
					212
					,'RGP10212'
					,2
					,SUBSTR(SQLERRM,1,100)
					,'COMMON_FUNC　出図連絡箋WKにデータ挿入エラー'
					,SUBSTR(SQLCODE ,1,100)
					,'DSEQ=' || P_RG0212.DSEQ
					);
					END;
			END;
		END IF;
		P_KEKKA := 0;

		/* 標準図配布明細表WKに新品番のデータ挿入  */
		BEGIN
			INSERT INTO RGW029 (
				DSEQ		--DSEQ
				,STDPL		--親品番
				,FSNNO		--風船NO
				,PNNW		--子品番
				,TMSET		--登録日時
				,TMUPD		--更新日時
				,USRSET		--登録者
				,USRUPD		--更新者
				,PRGSET		--登録ＰＲＧ
				,PRGUPD		--更新ＰＲＧ
			)
			SELECT
				P_RG0212.DSEQ
				,A.OYA
				,A.FSNNO
				,A.KO
				,strTMSET
				,strTMSET
				,P_RG0212.USRSET
				,P_RG0212.USRSET
				,strPRGUPD
				,strPRGUPD
			FROM RG103 A,RG08 B
			WHERE
				A.OYA		IN	(SELECT STDPL FROM RGW025 WHERE DSEQ =  P_RG0212.DSEQ)	AND
				A.DYSTR	=	'99999999'												AND
				A.DYEND	=	'99999999'												AND
				A.KO		IS NOT NULL													AND
				A.FSNNO	!= 'C'														AND
				A.OYA   = B.PN	AND
				B.KBNHT = '0'	AND
				nvl(A.KAIHAI,' ') not in  ('D')  ;
		EXCEPTION
			WHEN OTHERS THEN
				BEGIN
				LOGOUT(
				212
				,'RGP10212'
				,2
				,SUBSTR(SQLERRM,1,100)
				,'COMMON_FUNC　標準図配布明細表WKに新部品データ挿入エラー'
				,SUBSTR(SQLCODE ,1,100)
				,'DSEQ=' || P_RG0212.DSEQ
				);
				END;
		END;

		/* 標準図配布明細表WKに旧品番のデータ挿入 */
		BEGIN
			INSERT INTO RGW028 (
				DSEQ		--DSEQ
				,STDPL		--親品番
				,FSNNO		--風船NO
				,PNOD		--子品番
				,TMSET		--登録日時
				,TMUPD		--更新日時
				,USRSET		--登録者
				,USRUPD		--更新者
				,PRGSET		--登録ＰＲＧ
				,PRGUPD		--更新ＰＲＧ
			)
			SELECT /*+ rule */
				P_RG0212.DSEQ
				,a.OYA
				,a.FSNNO
				,a.KO
				,strTMSET
				,strTMSET
				,P_RG0212.USRSET
				,P_RG0212.USRSET
				,StrPRGUPD
				,strPRGUPD
			FROM RG103 a,RG08 B,RGW025 c
			WHERE
				c.DSEQ			=	P_RG0212.DSEQ		AND
				c.STDPL			=	a.OYA				AND
				A.OYA			=	B.PN				AND
				B.KBNHT			=	'0'					AND
				a.KO			IS NOT NULL				AND
				a.DYSTR			!=	'99999999'			AND
				a.DYEND			=	'99999999'			AND
				EXISTS (SELECT 'X'
						FROM RG103
						WHERE a.OYA = OYA
						AND a.FSNNO = FSNNO
						and ko is not null
						and nvl(kaihai,' ') != 'M'
						and DYSTR = '99999999'
						and DYEND = '99999999'
						);
		EXCEPTION
			WHEN OTHERS THEN
				BEGIN
				LOGOUT(
				212
				,'RGP10212'
				,2
				,SUBSTR(SQLERRM,1,100)
				,'COMMON_FUNC　標準図配布明細表WKに旧部品データ挿入エラー'
				,SUBSTR(SQLCODE ,1,100)
				,'DSEQ=' || P_RG0212.DSEQ
				);
				END;
		END;

		/* 標準図配布明細表WKに旧部品と新部品の両方あるデータを挿入 */
		BEGIN
			INSERT INTO RGW030 (
				DSEQ	--DSEQ
				,STDPL	--親品番
				,FSNNO	--風船NO
				,PNNW	--新品番
				,PNOD	--旧品番
				,TMSET	--登録日時
				,TMUPD	--更新日時
				,USRSET	--登録者
				,USRUPD	--更新者
				,PRGSET	--登録ＰＲＧ
				,PRGUPD	--更新ＰＲＧ
			)
			SELECT
				P_RG0212.DSEQ
				,B.STDPL
				,B.FSNNO
				,B.PNNW
				,A.PNOD
				,strTMSET
				,strTMSET
				,P_RG0212.USRSET
				,P_RG0212.USRSET
				,strPRGUPD
				,strPRGUPD
			FROM RGW028 A,RGW029 B
			WHERE
				A.DSEQ				=	P_RG0212.DSEQ	AND
				B.DSEQ				=	P_RG0212.DSEQ	AND
				A.STDPL||A.FSNNO	=	B.STDPL||B.FSNNO ;
		EXCEPTION
			WHEN OTHERS THEN
				BEGIN
				LOGOUT(
				212
				,'RGP10212'
				,2
				,SUBSTR(SQLERRM,1,100)
				,'COMMON_FUNC　標準図配布明細表WKに新旧部品（共通品）データ挿入エラー'
				,SUBSTR(SQLCODE ,1,100)
				,'DSEQ=' || P_RG0212.DSEQ
				);
				END;
		END;

		/* 標準図配布明細表WKに新品番のみのデータを挿入  */
		BEGIN
			INSERT INTO RGW030 (
				DSEQ	--DSEQ
				,STDPL	--親品番
				,FSNNO	--風船NO
				,PNOD	--旧品番
				,TMSET	--登録日時
				,TMUPD	--更新日時
				,USRSET	--登録者
				,USRUPD	--更新者
				,PRGSET	--登録ＰＲＧ
				,PRGUPD	--更新ＰＲＧ
			)
			SELECT
				P_RG0212.DSEQ
				,STDPL
				,FSNNO
				,PNOD
				,strTMSET
				,strTMSET
				,P_RG0212.USRSET
				,P_RG0212.USRSET
				,strPRGUPD
				,strPRGUPD
			FROM RGW028
			WHERE
				DSEQ	=	P_RG0212.DSEQ	AND
				(DSEQ||STDPL||FSNNO) NOT IN (SELECT DSEQ||STDPL||FSNNO FROM RGW029 WHERE DSEQ = P_RG0212.DSEQ);
		EXCEPTION
			WHEN OTHERS THEN
				BEGIN
				LOGOUT(
				212
				,'RGP10212'
				,2
				,SUBSTR(SQLERRM,1,100)
				,'COMMON_FUNC　標準図配布明細表WKに新旧部品（旧部品のみ）データ挿入エラー'
				,SUBSTR(SQLCODE ,1,100)
				,'DSEQ=' || P_RG0212.DSEQ
				);
				END;
		END;

		/* 標準図配布明細表WKに旧品番のみのデータを挿入 */
		BEGIN
			INSERT INTO RGW030 (
				DSEQ	--DSEQ
				,STDPL	--親品番
				,FSNNO	--風船NO
				,PNNW	--新品番
				,TMSET	--登録日時
				,TMUPD	--更新日時
				,USRSET	--登録者
				,USRUPD	--更新者
				,PRGSET	--登録ＰＲＧ
				,PRGUPD	--更新ＰＲＧ
			)
			SELECT
				P_RG0212.DSEQ
				,STDPL
				,FSNNO
				,PNNW
				,strTMSET
				,strTMSET
				,P_RG0212.USRSET
				,P_RG0212.USRSET
				,strPRGUPD
				,strPRGUPD
			FROM RGW029
			WHERE
				DSEQ	=	P_RG0212.DSEQ AND
				(DSEQ||STDPL||FSNNO) NOT IN (SELECT DSEQ||STDPL||FSNNO FROM RGW028 WHERE DSEQ = P_RG0212.DSEQ);
		EXCEPTION
			WHEN OTHERS THEN
				BEGIN
				LOGOUT(
				212
				,'RGP10212'
				,2
				,SUBSTR(SQLERRM,1,100)
				,'COMMON_FUNC　標準図配布明細表WKに新旧部品（新部品のみ）データ挿入エラー'
				,SUBSTR(SQLCODE ,1,100)
				,'DSEQ=' || P_RG0212.DSEQ
				);
				END;
		END;


		P_DSEQ := P_RG0212.DSEQ;
		FOR REC_RGW030_1 IN CUR_RGW030_1 LOOP
			BEGIN
				/* 標準図配布明細表WKにPLデータを挿入 */
				INSERT INTO RGW027 (
					DSEQ	--DSEQ
					,SEQ
					,STDPL
					,PNOD	--親品番
					,CDSYR
					,CDGKN
					,CDRYU
					,TMSET
					,TMUPD
					,USRSET
					,USRUPD
					,PRGSET
					,PRGUPD
				) VALUES (
					REC_RGW030_1.DSEQ
					,RGW027S01.NEXTVAL
					,REC_RGW030_1.STDPL
					,''
					,''
					,''
					,''
					,strTMSET
					,strTMSET
					,P_RG0212.USRSET
					,P_RG0212.USRSET
					,strPRGUPD
					,strPRGUPD
					);
			EXCEPTION
				WHEN OTHERS THEN
					BEGIN
					LOGOUT(
					212
					,'RGP10212'
					,2
					,SUBSTR(SQLERRM,1,100)
					,'COMMON_FUNC　標準図配布明細表WKに新旧部品（旧PL NO）データ挿入エラー'
					,SUBSTR(SQLCODE ,1,100)
					,'DSEQ=' || P_RG0212.DSEQ
					);
					END;
			END;

			P_DSEQ := P_RG0212.DSEQ;
			P_STDPL := REC_RGW030_1.STDPL;
			FOR REC_RGW030_2 IN CUR_RGW030_2 LOOP
				BEGIN
					/* 標準図配布明細表WKに旧品番と新品番のデータを挿入 */
					INSERT INTO RGW027 (
						DSEQ
						,SEQ
						,STDPL
						,PNOD
						,PNNW
						,CDSYR
						,CDGKN
						,CDRYU
						,TMSET
						,TMUPD
						,USRSET
						,USRUPD
						,PRGSET
						,PRGUPD
					) VALUES (
						REC_RGW030_2.DSEQ
						,RGW027S01.NEXTVAL
						,NULL
						,REC_RGW030_2.PNOD
						,REC_RGW030_2.PNNW
						,''
						,''
						,''
						,strTMSET
						,strTMSET
						,P_RG0212.USRSET
						,P_RG0212.USRSET
						,strPRGUPD
						,strPRGUPD
					);
				EXCEPTION
					WHEN OTHERS THEN
						BEGIN
						LOGOUT(
						212
						,'RGP10212'
						,2
						,SUBSTR(SQLERRM,1,100)
						,'COMMON_FUNC　標準図配布明細表WKに新旧部品（2）データ挿入エラー'
						,SUBSTR(SQLCODE ,1,100)
						,'DSEQ=' || P_RG0212.DSEQ
						);
						END;
				END;
			END LOOP;
		END LOOP;

		/* 出図連絡箋の出図区分を設定 */
		BEGIN
			p_syrno := '';

			SELECT MAX(SYRNO) INTO p_syrno FROM RG11 X,RGW025 Y WHERE X.PL = Y.STDPL AND Y.DSEQ = P_RG0212.DSEQ;

			IF p_syrno IS NOT NULL THEN
				-- 変更前データがあれば、出図区分は変更
				UPDATE RGW026
				SET
					SZKBN	=	3
					,SNZKBN	=	3
				WHERE
					DSEQ	=	P_RG0212.DSEQ;
			ELSE
				-- 変更前データがなければ、出図区分は新図（部品図）
				UPDATE RGW026
				SET
					SZKBN	=	1
					,SNZKBN	=	3
				WHERE
					DSEQ	=	P_RG0212.DSEQ;
			END IF ;
			
		
		EXCEPTION
			WHEN OTHERS THEN
				BEGIN
				LOGOUT(
				212
				,'RGP10212'
				,2
				,SUBSTR(SQLERRM,1,100)
				,'COMMON_FUNC　出図連絡箋　出図区分設定エラー'
				,SUBSTR(SQLCODE ,1,100)
				,'DSEQ=' || P_RG0212.DSEQ
				);
				END;
		END;

		p_synn := null;
		p_sysa := null;
		/*** 承認・照査の取得 ***/
		BEGIN
			SELECT SYNN,SYSA 
			INTO p_synn,p_sysa
			FROM RG11 X,RGW025 Y
			WHERE X.PL = Y.STDPL
			AND Y.DSEQ = P_RG0212.DSEQ
			AND ROWNUM = 1;
		EXCEPTION
			WHEN OTHERS THEN
				p_synn := null;
				p_sysa := null;
		END;
		BEGIN
			UPDATE RGW026
			SET SYNN = p_synn
			,	SYSA = p_sysa
			WHERE DSEQ = 	P_RG0212.DSEQ;
		EXCEPTION
			WHEN OTHERS THEN
				BEGIN
				LOGOUT(
				212
				,'RGP10212'
				,2
				,SUBSTR(SQLERRM,1,100)
				,'COMMON_FUNC　出図連絡箋　承認、照査設定エラー'
				,SUBSTR(SQLCODE ,1,100)
				,'DSEQ=' || P_RG0212.DSEQ
				);
				END;
		END;

	EXCEPTION
		WHEN OTHERS THEN
			BEGIN
			LOGOUT(
			212
			,'RGP10212'
			,2
			,SUBSTR(SQLERRM,1,100)
			,'COMMON_FUNC　エラー'
			,SUBSTR(SQLCODE ,1,100)
			,'DSEQ=' || P_RG0212.DSEQ
			);
			END;
	END COMMON_FUNC_DB;

/********************************************************************************/
/*	S E T _ L O C K															*/
/********************************************************************************/
	PROCEDURE SET_LOCK
	(
		P_KEKKA			OUT	NUMBER			-- エラー結果(0:正常 1:警告 2:異常)
		,P_ERRMSGS		OUT	ERR_MSG_ARRAY	-- エラーのあるときのエラーメッセージ配列
		,P_SYSARGS		IN	SYSARG_ARRAY	-- 引数 SYSTEMデータ
		,P_RG0212ARG	IN	RG0212ARG_ARRAY	-- 引数 USERデータ
	)
	IS
		--ログインユーザが管理者で、かつロックユーザと異なる際のスキップフラグ
		P_ROOTSKIP NUMBER;
		P_PNARR PN_ARRAY;
		W_USRNM RG60.NMUSRJP%TYPE;
	BEGIN
		FOR  I IN 1..P_SYSARGS.COUNT LOOP
			P_ROOTSKIP := 0;
			BEGIN
				-- ロックテーブルに未登録の品番は、未ロック状態で登録
				INSERT INTO RG103LOCK
				(
					PN
					,FGLOCK
					,TMLOCK
					,USRLOCK
					,TMSET
					,TMUPD
					,USRSET
					,USRUPD
				)
				SELECT DISTINCT
					RG103.KO
					,'0'
					,NULL
					,NULL
					,strTMSET
					,strTMSET
					,P_RG0212ARG(I).USRSET
					,P_RG0212ARG(I).USRSET
				FROM RG103
				WHERE
					RG103.KO IN (
						SELECT DISTINCT RG103.KO
						FROM RG103, RG08
						WHERE
							RG08.PN =  RG103.KO
							AND NOT (RG08.KBNHT = '1' AND RG08.KBNPN = '1') --SP10品番を除外
						--出図対象から親方向に向かって検索
						START WITH KO = P_RG0212ARG(I).PN
							AND KORVSN = (SELECT NVL(MAX(KORVSN), 0) FROM RG103 WHERE KO = P_RG0212ARG(I).PN)
						CONNECT BY PRIOR OYA = KO
					)
					AND NOT EXISTS(  --RG103LOCKに存在しないデータのみ登録
						SELECT RG103LOCK.PN
						FROM RG103LOCK
						WHERE RG103.KO =  RG103LOCK.PN
					);

				-- 出図データ行ロック
				SELECT
					RG103LOCK.PN BULK COLLECT INTO P_PNARR
				FROM RG103LOCK 
				WHERE
					RG103LOCK.PN IN (
						SELECT DISTINCT RG103.KO
						FROM RG103, RG08
						WHERE
							RG08.PN =  RG103.KO
							AND NOT (RG08.KBNHT = '1' AND RG08.KBNPN = '1') --SP10品番を除外
						--出図対象から親方向に向かって検索
						START WITH KO = P_RG0212ARG(I).PN
							AND KORVSN = (SELECT NVL(MAX(KORVSN), 0) FROM RG103 WHERE KO = P_RG0212ARG(I).PN)
						CONNECT BY PRIOR OYA = KO
					)
				FOR UPDATE;

				-- 出図ロック確認
				FOR RG103LOCK_01 IN (
					SELECT 
						USRLOCK, --ロックユーザID
						PN --PLNo
					FROM RG103LOCK 
					WHERE
						RG103LOCK.PN IN (
							SELECT DISTINCT RG103.KO
							FROM RG103, RG08
							WHERE
								RG08.PN =  RG103.KO
								AND NOT (RG08.KBNHT = '1' AND RG08.KBNPN = '1') --SP10品番を除外
							--出図対象から親方向に向かって検索
							START WITH KO = P_RG0212ARG(I).PN
								AND KORVSN = (SELECT NVL(MAX(KORVSN), 0) FROM RG103 WHERE KO = P_RG0212ARG(I).PN)
							CONNECT BY PRIOR OYA = KO
						)
						AND FGLOCK = '1' --ロック有り
						AND USRLOCK <> P_RG0212ARG(I).USRSET --ロックユーザがログインユーザ以外
				) LOOP
					IF P_RG0212ARG(I).USRROLE = 'root' THEN
						--管理者の場合はエラーにしない
						P_ROOTSKIP := 1;
						EXIT;
					END IF;

					W_USRNM := RGP00001.GET_NMUSRJP(RG103LOCK_01.USRLOCK);

					HYBS.SET_ERRMSGS (
						P_ERRMSGS			-- エラーメッセージ配列
						,P_SYSARGS(I).NO	-- 行番号
						,2					-- エラー結果(0:正常 1:警告 2:異常)
						,'RGE1031'			-- #他ユーザが出図中のため、出図できません。USER={0}、PL NO={1}
						,W_USRNM
						,RG103LOCK_01.PN
					);
					P_KEKKA := 2;
				END LOOP;

				-- エラーが有る場合はスキップ
				IF P_KEKKA = 2 THEN
					CONTINUE;
				END IF;

				-- 出図ロック
				IF P_ROOTSKIP = 0 THEN
					UPDATE  RG103LOCK
					SET
						FGLOCK = '1', --ロックフラグ
						USRLOCK = P_RG0212ARG(I).USRSET,  --ロックユーザ
						TMLOCK = strTMSET, --ロック日時
						USRUPD = P_RG0212ARG(I).USRSET,
						TMUPD = strTMSET
					WHERE
						RG103LOCK.PN IN (
							SELECT DISTINCT RG103.KO
							FROM RG103, RG08
							WHERE
								RG08.PN =  RG103.KO
								AND NOT (RG08.KBNHT = '1' AND RG08.KBNPN = '1') --SP10品番を除外
							--出図対象から親方向に向かって検索
							START WITH KO = P_RG0212ARG(I).PN
								AND KORVSN = (SELECT NVL(MAX(KORVSN), 0) FROM RG103 WHERE KO = P_RG0212ARG(I).PN)
							CONNECT BY PRIOR OYA = KO
						)
						AND (FGLOCK IS NULL OR FGLOCK <> '1'); --ロックなし
				END IF;
			EXCEPTION
				WHEN OTHERS THEN
					BEGIN
					LOGOUT(
					212
					,'RGP10212'
					,2
					,SUBSTR(SQLERRM,1,100)
					,'SET_LOCK　出図ロック処理エラー'
					,SUBSTR(SQLCODE ,1,100)
					,'品番=' || P_RG0212ARG(I).PN
					);
				END;
			END;
		END LOOP;

	END SET_LOCK;
/********************************************************************************/
/*	M A I N - R T N																*/
/********************************************************************************/
	PROCEDURE RG10212
	(
		P_KEKKA			OUT	NUMBER			-- エラー結果(0:正常 1:警告 2:異常)
		,P_ERRMSGS		OUT	ERR_MSG_ARRAY	-- エラーのあるときのエラーメッセージ配列
		,P_NAMES		IN	VARCHAR2
		,P_SYSARGS		IN	SYSARG_ARRAY	-- 引数 SYSTEMデータ
		,P_RG0212ARG	IN	RG0212ARG_ARRAY	-- 引数 USERデータ
	)
	IS
		I	NUMBER;
	BEGIN

		P_KEKKA := 0;

		CHECK_DB( P_KEKKA,P_ERRMSGS,P_NAMES,P_SYSARGS,P_RG0212ARG );

		IF P_KEKKA = 2 THEN
			RETURN;
		END IF;

		SET_LOCK( P_KEKKA,P_ERRMSGS,P_SYSARGS,P_RG0212ARG );

		IF P_KEKKA = 2 THEN
			RETURN;
		END IF;

		FOR  I IN 1..P_SYSARGS.COUNT LOOP
			w_l := I;

			INSERT_DB( P_KEKKA,P_ERRMSGS,I,P_SYSARGS(I),P_RG0212ARG(I) );

		END LOOP;

		IF P_KEKKA = 2 THEN
			RETURN;
		END IF;

		COMMON_FUNC_DB(P_KEKKA,P_ERRMSGS,1,P_SYSARGS(1),P_RG0212ARG(1) );


--		COMMIT;		コミットしないでください。

		EXCEPTION
			WHEN ERR001	THEN
--				ROLLBACK;			ロールバックしないでください。
				BEGIN
				LOGOUT(
				212
				,'RGP10212'
				,2
				,SUBSTR(SQLERRM,1,100)
				,'ERR001　エラー'
				,SUBSTR(SQLCODE ,1,100)
				,'DSEQ=' || P_RG0212ARG(I).DSEQ
				);
				END;

				P_KEKKA :=2;

			WHEN HYBS.TOO_MANY_ERRORS THEN
--				ROLLBACK;
				HYBS.SET_LIMITOVER(P_ERRMSGS);

			WHEN OTHERS THEN
--				ROLLBACK;
				BEGIN
				LOGOUT(
				212
				,'RGP10212'
				,2
				,SUBSTR(SQLERRM,1,100)
				,'MAIN_RTN　エラー'
				,SUBSTR(SQLCODE ,1,100)
				,'DSEQ=' || P_RG0212ARG(I).DSEQ
				);
				END;

	END RG10212;

END RGP10212;
/
CREATE OR REPLACE PACKAGE BODY RGP10542A AS
PROCEDURE RG10542A (
	 P_KEKKA	OUT	NUMBER			-- 処理結果(0:正常 1:警告 2:異常)
	,P_ERRMSGS	OUT	ERR_MSG_ARRAY	-- エラーメッセージ配列
	,P_CURSOR	OUT	CUST_CURSOR		-- 結果カーソル
	,P_SYSARGS	IN	ARG_ARRAY 		-- 条件配列
) IS

/*********************************************************/
/*  変数宣言                                             */
/*********************************************************/
	-- グローバル変数
	B_RC			BOOLEAN				:=	TRUE;	-- 戻り値
	B_ERRFLG		BOOLEAN				:=	TRUE;	-- 戻り値
	N_EXISTS_COUNT	NUMBER  := 0;		-- 存在カウント
    HNB_CNT         NUMBER              :=  1500;   -- 出図上限数

	-- 条件配列変数
	P_YKNO			RGW038.YKNO%TYPE	:=	P_SYSARGS(1);	-- 要求番号
	P_SZKBN			VARCHAR2(1)			:=	P_SYSARGS(2);	-- 出図区分
	P_SNZKBN		VARCHAR2(1)			:=	P_SYSARGS(3);	-- 新図区分
	P_GAMENKBN		VARCHAR2(1)			:=	P_SYSARGS(4);	-- 画面区分
	P_PWBS			VARCHAR2(4)			:=	P_SYSARGS(5);	-- 配布先ＰＷＢＳ
	P_SERVER_URL	VARCHAR2(200)		:=	P_SYSARGS(6);	-- サーバーＵＲＬ
	P_USERID		RG35.USRSET%TYPE	:=	P_SYSARGS(7);	-- ログインユーザー
	P_SYRNO			RG84.SYRNO%TYPE		:=	P_SYSARGS(8);	-- 処理NO(3DEX用)

	WK_SYRNO		RG84.SYRNO%TYPE;

	WK_ERRFLG		BOOLEAN				:=	FALSE;
	WK_PGID			VARCHAR2(20);
	WK_ERRMSG		VARCHAR2(100);
	WK_SQLCODE		VARCHAR2(100);
	WK_CNT			NUMBER;
	WK_PLNO			RG35.KO%TYPE;
	WK_OYA			RG35.OYA%TYPE;
	WK_FSNNO		RG35.FSNNO%TYPE;

	-- 2013/11/20 ADD START
	PO_STATUS		VARCHAR2(1);						/*  ｽﾃｰﾀｽ         */
	PO_ERRMSGS		VARCHAR2(2000);						/*  ｴﾗｰﾒｯｾｰｼﾞ     */
	PI_SYSTEM_ID	VARCHAR2(2)			:= 'RG';		/*  ｼｽﾃﾑID        */
	PI_USER 		VARCHAR2(10)		:= P_SYSARGS(7);/*	ﾛｸﾞｲﾝﾕｰｻﾞｰ    */
	PI_PGPID		VARCHAR2(20)		:= 'RG0542';	/*	親PGID        */
	PI_SEQJKR		NUMBER;								/*	時系列SEQ     */
	PI_IDTBL		VARCHAR2(10)		:= 'RGW810';	/*	ﾃｰﾌﾞﾙID       */
	PI_BKNCD		RG32.BKNCD%TYPE;					/*	物件C         */
	PI_PWBS			RG32.PWBS%TYPE;						/*	P-WBS         */
	-- 2013/11/20 ADD END

	ERROR001		EXCEPTION;
	ERROR002		EXCEPTION;
	ERROR003		EXCEPTION;
	ERROR004		EXCEPTION;

	CURSOR RGW038_C01 IS
			SELECT	SMKID,SYRNO
			FROM	RGW038
			WHERE	YKNO = P_YKNO
			 AND	NVL(FGTORI,' ') != '1'
			ORDER BY SMKID;

	RGW038_rec		RGW038_C01%ROWTYPE;

	CURSOR RG35_C01 IS
			SELECT	SEQ,OYA,KO,SYRNO,DYSZM,KAIHAI,KORVSN,STDSEQ,RGP00001.GET_KBNPN(KO) KBNPN
			FROM	RG35 A
			WHERE	SMKID = RGW038_rec.SMKID
			 AND	KBNSS = '1';

	RG35_rec01		RG35_C01%ROWTYPE;

/*********************************************************/
/*  メイン処理                                           */
/*********************************************************/
BEGIN

	-- 正常終了
	P_KEKKA := 0;

	-- 2013/11/20 ADD START
	-- 時系列SEQ採番
	RGP00824.RG00824(	PO_STATUS,
						PO_ERRMSGS,
						PI_SYSTEM_ID,
						PI_USER,
						PI_PGPID,
						PI_IDTBL,
						PI_SEQJKR ) ;
	-- 2013/11/20 ADD END

	-- 本処理番号採番
	OPEN	RGW038_C01;
	LOOP
		FETCH	RGW038_C01
		INTO	RGW038_rec;
		EXIT WHEN RGW038_C01%NOTFOUND;

		-- 同一機番、同一階層(親)、同一風船重複チェック
		-- 親と風船でグループ化して、2件以上あるものを抽出
		BEGIN
			SELECT OYA,FSNNO,COUNT(*)
			INTO WK_OYA,WK_FSNNO,WK_CNT
			FROM (
				SELECT	A.OYA,A.FSNNO
				FROM	RG35 A
				WHERE	A.SMKID	= RGW038_rec.SMKID
				AND		NVL(A.KAIHAI,' ') != 'D'
				AND		A.FSNNO != 'C'
				AND		A.KO IS NOT NULL
				AND (	(A.DYSTR != '99999999' AND A.DYEND = '99999999' AND NOT EXISTS
							(SELECT 'X' FROM RG35 X WHERE X.SMKID = A.SMKID AND X.OYA = A.OYA AND X.FSNNO = A.FSNNO AND X.DYSTR = '99999999' AND X.DYEND = '99999999')
						) OR
						(A.DYSTR  = '99999999' AND A.DYEND = '99999999' AND EXISTS
							(SELECT 'Y' FROM RG35 Y WHERE Y.SMKID = A.SMKID AND Y.OYA = A.OYA AND Y.FSNNO = A.FSNNO AND Y.DYSTR = '99999999' AND Y.DYEND = '99999999')
						)
				)
			)
			GROUP BY OYA,FSNNO
			HAVING COUNT(*) > 1;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				WK_CNT := 0;
		END;

		IF WK_CNT > 0 THEN
			RAISE ERROR004;
		END IF;

		IF P_GAMENKBN = '3' THEN
			-- 3DEXからの出図の場合、3DEX側から渡される処理NOを使用
			WK_SYRNO := P_SYRNO;
		ELSE
			-- 画面からの出図の場合、新規採番
			WK_SYRNO := RGP00001.GET_SYRNO;
		END IF;

		/* 処理NO欠番調査用 */
		LOGOUT(
		542				 -- 画面ID(NXT_DEBUG_CONTROLのKEY)
		,'RGP10542'			 -- パッケージ名
		,2				 -- 変更不要
		,SUBSTR(SQLERRM,1,100)	 	 -- 変更不要
		,'出図処理開始'	 -- 例外が発生した処理の名前
		,SUBSTR(SQLCODE ,1,100)		 -- 変更不要
		,'SYRNO=' || WK_SYRNO || 'SMKID=' || RGW038_rec.SMKID ||  'USERID=' || P_USERID 		 -- 例外発生時のSMKID,SYRNOなどの値
		);

		-- 出図連絡箋
		UPDATE	RG84
		SET		SYRNO	= WK_SYRNO
		WHERE	SMKID	= RGW038_rec.SMKID
		 AND	( SYRNO like 'B%'
		 OR	SYRNO like 'H%'  );

		-- 出図対象機番SEQ WK
		UPDATE	RGW038
		SET		SYRNO	= WK_SYRNO
		WHERE	YKNO	= P_YKNO
		 AND	SMKID	= RGW038_rec.SMKID;

		-- 出図エラー表示用WK
		UPDATE	RGW039
		SET		SYRNO	= WK_SYRNO
		WHERE	YKNO	= P_YKNO
		 AND	SMKID	= RGW038_rec.SMKID;

		-- 2013/11/20 ADD START
		-- 変更前スナップショット作成
		RGP00808.RG00808(	PO_STATUS,
							PO_ERRMSGS,
							PI_SYSTEM_ID,
							PI_USER,
							PI_PGPID,
							PI_SEQJKR,
							RGW038_rec.SMKID,
							WK_SYRNO ) ;
		-- 2013/11/20 ADD END

	END LOOP;
	CLOSE RGW038_C01;


	-- ＰＬ・４０の時、風船違いで同品番が存在すれば、'1'(出図)にする(念の為)
	-- 10541A1で行うべきだが､出図構成確定画面(RG0540)で明示的に出図指示Fが外された場合はエラーとしたい為
	OPEN	RGW038_C01;
	LOOP
		FETCH	RGW038_C01
		INTO	RGW038_rec;
		EXIT WHEN RGW038_C01%NOTFOUND;

		OPEN	RG35_C01;
		LOOP
			FETCH	RG35_C01
			INTO	RG35_rec01;
			EXIT WHEN RG35_C01%NOTFOUND;

			-- 出図対象外チェック
			IF RGP00010.CHECK_SYUTUZU_EXCLUDED(RGW038_rec.SMKID, RG35_rec01.KO) = '1' THEN
				WK_PLNO := RG35_rec01.KO;
				RAISE ERROR003;
			END IF;

			IF RG35_rec01.KBNPN IN ('1','2') THEN

				SELECT	COUNT(*)
				INTO	WK_CNT
				FROM	RG35
				WHERE	SMKID	= RGW038_rec.SMKID
				 AND	OYA		= RG35_rec01.OYA
				 AND	KO		= RG35_rec01.KO
				 AND	FSNNO	!= 'C'
				 AND	SYRNO IS NULL
				 AND	NVL(KBNSS,'0') IN ('0','2')
				 AND	DYEND	= '99999999'
				 AND	KORVSN	!=	'0'					-- 2016/11/14 ADD Ver0は同時出図しなくてもよい
				-- 2016/11/14 ADD 下位構成に出図指示が立っている場合のみ風船違い同一ＰＬを出図対象とする
				 AND	EXISTS	(	SELECT	X.OYA
									FROM	RG35 X
									WHERE	X.SMKID			=	RGW038_rec.SMKID
									AND		X.OYA			=	RG35.KO
									AND		X.DYEND			=	'99999999'
									AND		( X.FGSSJ		=	'1'
											  OR  X.DYSTR	=	'99999999' )
						)
				;

				IF WK_CNT > 0 THEN
					UPDATE	RG35
					SET		KBNSS	= '1'
					WHERE	SMKID	= RGW038_rec.SMKID
					 AND	OYA		= RG35_rec01.OYA
					 AND	KO		= RG35_rec01.KO
					 AND	FSNNO	!= 'C'
					 AND	SYRNO IS NULL
					 AND	NVL(KBNSS,'0') IN ('0','2')
					 AND	DYEND	= '99999999';
				END IF;

			END IF;

		END LOOP;
		CLOSE RG35_C01;

	END LOOP;
	CLOSE RGW038_C01;

	SELECT	COUNT(*)
	INTO	WK_CNT
	FROM	RGW038 A ,RG35 B
	WHERE	A.YKNO  = P_YKNO
	 AND	A.SMKID = B.SMKID
	 AND	NVL(B.KBNSS,' ') = '1';
	IF WK_CNT > HNB_CNT THEN
		WK_ERRMSG := 'サーバーの負荷軽減のため、出図明細件数を'||TO_CHAR(HNB_CNT)||'件以内で出図してください。'||WK_CNT||'件';
		RAISE ERROR001;
	END IF;

	OPEN	RGW038_C01;
	LOOP
		FETCH	RGW038_C01
		INTO	RGW038_rec;
		EXIT WHEN RGW038_C01%NOTFOUND;

		-- (0)変更前構成情報ＷＫ作成
		RGP10542A0.RG10542A0(RGW038_rec.SMKID,RGW038_rec.SYRNO,P_USERID,B_RC,WK_ERRMSG,WK_SQLCODE);
		IF B_RC = FALSE THEN
			WK_PGID := 'RGP10542A0';
			RAISE ERROR001;
		END IF;

		-- ①仕向先構成バージョンアップ
		RGP10542A1.RG10542A1(RGW038_rec.SMKID,RGW038_rec.SYRNO,P_USERID,B_RC,WK_ERRMSG,WK_SQLCODE,P_GAMENKBN);
		IF B_RC = FALSE THEN
			WK_PGID := 'RGP10542A1';
			RAISE ERROR001;
		END IF;

		-- ②仕向先構成 出図処理完了
		RGP10542A2.RG10542A2(RGW038_rec.SMKID,RGW038_rec.SYRNO,P_GAMENKBN,P_SNZKBN,P_USERID,B_RC,WK_ERRMSG,WK_SQLCODE);
		IF B_RC = FALSE THEN
			WK_PGID := 'RGP10542A2';
			RAISE ERROR001;
		END IF;

		-- ③標準構成リリース
		RGP10542A3.RG10542A3(RGW038_rec.SMKID,RGW038_rec.SYRNO,P_USERID,B_RC,WK_ERRMSG,WK_SQLCODE,P_GAMENKBN);
		IF B_RC = FALSE THEN
			WK_PGID := 'RGP10542A3';
			RAISE ERROR001;
		END IF;

		-- ④製造情報取得
		RGP10542A4.RG10542A4(RGW038_rec.SMKID,RGW038_rec.SYRNO,P_SZKBN,P_USERID,B_RC,WK_ERRMSG,WK_SQLCODE);
		IF B_RC = FALSE THEN
			WK_PGID := 'RGP10542A4';
			RAISE ERROR001;
		END IF;

		-- ⑤仕向先構成表示順維持
		RGP10542A5.RG10542A5(RGW038_rec.SMKID,P_USERID,B_RC,WK_ERRMSG,WK_SQLCODE);
		IF B_RC = FALSE THEN
			WK_PGID := 'RGP10542A5';
			RAISE ERROR001;
		END IF;

		-- ⑥機番明細更新
		IF P_SZKBN != '8' THEN
			-- 出図区分＝新図 且つ 新図区分=完了 以外は 新図区分= NULL 2005/11/11 T.NASu
			IF P_SZKBN != '1' AND P_SNZKBN = '3' THEN
				 P_SNZKBN := NULL;
			END IF;

			RGP10542A6.RG10542A6(RGW038_rec.SMKID,RGW038_rec.SYRNO,P_SNZKBN,P_USERID,B_RC,WK_ERRMSG,WK_SQLCODE);
			IF B_RC = FALSE THEN
				WK_PGID := 'RGP10542A6';
				RAISE ERROR001;
			END IF;
		END IF;

		-- ⑦新生産伝送データ作成１
		RGP10542A7.RG10542A7(RGW038_rec.SMKID,RGW038_rec.SYRNO,P_USERID,B_RC,WK_ERRMSG,WK_SQLCODE);
		IF B_RC = FALSE THEN
			WK_PGID := 'RGP10542A7';
			RAISE ERROR001;
		END IF;

		-- ⑧初期処理Ｎｏセット
		RGP10542A8.RG10542A8(RGW038_rec.SMKID,RGW038_rec.SYRNO,P_USERID,B_RC,WK_ERRMSG,WK_SQLCODE);
		IF B_RC = FALSE THEN
			WK_PGID := 'RGP10542A8';
			RAISE ERROR001;
		END IF;

		-- ⑨出図連絡箋更新
		IF P_SZKBN != '8' THEN
			RGP10542A9.RG10542A9(RGW038_rec.SYRNO,P_USERID,B_RC,WK_ERRMSG,WK_SQLCODE);
			IF B_RC = FALSE THEN
				WK_PGID := 'RGP10542A9';
				RAISE ERROR001;
			END IF;
		END IF;

		-- ⑩メール送信ワーク登録
		IF P_SZKBN != '8' THEN
			RGP10542A10.RG10542A10(RGW038_rec.SMKID,RGW038_rec.SYRNO,P_SZKBN,P_GAMENKBN,P_PWBS,P_SERVER_URL,P_USERID,B_RC,WK_ERRMSG,WK_SQLCODE);
			IF B_RC = FALSE THEN
				WK_PGID := 'RGP10542A10';
				RAISE ERROR001;
			END IF;
		END IF;

		-- 帳票作成(出図連絡箋) 2007
		RGP10542A21.RG10542A21(RGW038_rec.SYRNO,RGW038_rec.SMKID,P_USERID,B_RC,WK_ERRMSG,WK_SQLCODE);
		IF B_RC = FALSE THEN
			WK_PGID := 'RGP10542A21';
			RAISE ERROR001;
		END IF;

		-- 印刷要求登録
		RGP10542A22.RG10542A22(RGW038_rec.SMKID,RGW038_rec.SYRNO,P_USERID,B_RC,WK_ERRMSG,WK_SQLCODE);
		IF B_RC = FALSE THEN
			WK_PGID := 'RGP10542A22';
			RAISE ERROR001;
		END IF;

		-- ⑪出図処理区分初期化
		RGP10542A11.RG10542A11(RGW038_rec.SMKID,P_USERID,B_RC,WK_ERRMSG,WK_SQLCODE);
		IF B_RC = FALSE THEN
			WK_PGID := 'RGP10542A11';
			RAISE ERROR001;
		END IF;

		-- 11.5 標準ー仕向 の差分を追加(補材、補材以外含む) 2015/07/17移動
		HOZAI_INS(RGW038_rec.SMKID,RGW038_rec.SYRNO);

		-- ⑫新生産伝送データ作成２
		RGP10542A12.RG10542A12(RGW038_rec.SMKID,RGW038_rec.SYRNO,P_USERID,B_RC,WK_ERRMSG,WK_SQLCODE);
		IF B_RC = FALSE THEN
			WK_PGID := 'RGP10542A12';
			RAISE ERROR001;
		END IF;

		-- ⑬出図時スナップショット作成 20050414 T.NASU A
		B_RC := RGP11406S1.SET_KZPRINT_QUEUE(RGW038_rec.SYRNO);
		IF B_RC = FALSE THEN
			WK_PGID := 'SET_KZPRINT_QUEUE';
			RAISE ERROR001;
		END IF;

		RGP10542A13.RG10542A13(RGW038_rec.SMKID,RGW038_rec.SYRNO,P_USERID,B_RC,WK_ERRMSG,WK_SQLCODE);
		IF B_RC = FALSE THEN
			WK_PGID := 'RGP10542A13';
			RAISE ERROR001;
		END IF;

		-- 出図実績FL抜き出し 2005/12/17 T.NASu
		RGP10542A14.RG10542A14(RGW038_rec.SMKID,RGW038_rec.SYRNO,P_USERID,B_RC,WK_ERRMSG,WK_SQLCODE);
		IF B_RC = FALSE THEN
			WK_PGID := 'RGP10542A14';
			RAISE ERROR001;
		END IF;

		-- 出図区分＝'8:DB登録'の時は、持ちCに '0'をｾｯﾄ
		BEGIN
			UPDATE	RG35
			   SET	CDMT = DECODE(P_SZKBN,'9','0',CDMT)
			 WHERE	SMKID = RGW038_rec.SMKID
			   AND	SYRNO = RGW038_rec.SYRNO
			;
		EXCEPTION
			WHEN OTHERS THEN
				WK_PGID := '{#RG35}';
				RAISE ERROR002;
		END;

--		HOZAI_INS(RGW038_rec.SMKID,RGW038_rec.SYRNO);		-- 2015/07/17 RL送信前に移動
--		HOZAI_INS_SERCH(RGW038_rec.SMKID,RGW038_rec.SYRNO);

		-- 2013/11/20 ADD START
		-- 変更後スナップショット作成
		RGP00809.RG00809(	PO_STATUS,
							PO_ERRMSGS,
							PI_SYSTEM_ID,
							PI_USER,
							PI_PGPID,
							RGW038_rec.SMKID ) ;
		RGP00810.RG00810(	PO_STATUS,
							PO_ERRMSGS,
							PI_SYSTEM_ID,
							PI_USER,
							PI_PGPID,
							PI_SEQJKR,
							RGW038_rec.SMKID,
							RGW038_rec.SYRNO ) ;
		-- 2013/11/20 ADD END

		LOGOUT(
		542				 -- 画面ID(NXT_DEBUG_CONTROLのKEY)
		,'RGP10542'			 -- パッケージ名
		,2				 -- 変更不要
		,SUBSTR(SQLERRM,1,100)	 	 -- 変更不要
		,'出図処理1'	 -- 例外が発生した処理の名前
		,SUBSTR(SQLCODE ,1,100)		 -- 変更不要
		,'SYRNO=' || RGW038_rec.SYRNO || 'SMKID=' || RGW038_rec.SMKID ||  'USERID=' || P_USERID 		 -- 例外発生時のSMKID,SYRNOなどの値
		);

--
	END LOOP;
	CLOSE RGW038_C01;

	-- 2013/11/20 ADD START
	RGP00822.RG00822(	PO_STATUS,
						PO_ERRMSGS,
						PI_USER,
						PI_USER,
						PI_PGPID,
						PI_SEQJKR
					);
	RGP00823.RG00823(	PO_STATUS,
						PO_ERRMSGS,
						PI_USER,
						PI_USER,
						PI_PGPID,
						PI_SEQJKR
					);
	--連携対象外物件は、処理対象から外す
	SELECT COUNT(*) INTO WK_CNT FROM RG808 A,RG32 B
	WHERE A.BKNCD = B.BKNCD
	AND   B.SMKID = RGW038_rec.SMKID;
	IF WK_CNT != 0 THEN
		UPDATE RG801 SET KBSYR = '9' WHERE SEQJKR = PI_SEQJKR;
	END IF;
	-- 変更後スナップショット作成(機番)
	SELECT	BKNCD,		PWBS
	INTO	PI_BKNCD,	PI_PWBS
	FROM	RG32
	WHERE	SMKID	=	RGW038_rec.SMKID;
	RGP00815.RG00815(	PO_STATUS,
						PO_ERRMSGS,
						PI_SYSTEM_ID,
						PI_USER,
						PI_PGPID,
						PI_SEQJKR,
						PI_BKNCD,
						PI_PWBS ) ;
	-- 2013/11/20 ADD END

	LOGOUT(
	542				 -- 画面ID(NXT_DEBUG_CONTROLのKEY)
	,'RGP10542'			 -- パッケージ名
	,2				 -- 変更不要
	,SUBSTR(SQLERRM,1,100)	 	 -- 変更不要
	,'出図処理終了'	 -- 例外が発生した処理の名前
	,SUBSTR(SQLCODE ,1,100)		 -- 変更不要
	,'SYRNO=' || RGW038_rec.SYRNO || 'SMKID=' || RGW038_rec.SMKID ||  'USERID=' || P_USERID 		 -- 例外発生時のSMKID,SYRNOなどの値
	);

	-- 検索用カーソル作成(何かカーソルを返さないとエラーになる)
	OPEN P_CURSOR FOR
		SELECT SYSDATE FROM DUAL;
	RETURN;

/*********************************************************/
/*  例外処理                                             */
/*********************************************************/
EXCEPTION

	WHEN ERROR001 THEN
		ROLLBACK;
		HYBS.SET_ERRMSGS(P_ERRMSGS					-- エラーメッセージ配列
						,0							-- 行番号
						,2							-- エラー結果(0:正常 1:警告 2:異常)
						,'RGE0174'					-- ｼｽﾃﾑｴﾗｰが発生しました。{0}
						,WK_PGID||':'||WK_ERRMSG||':'||WK_SQLCODE);		-- エラーメッセージ引数{0}
		-- 異常終了
		P_KEKKA := 2;

	WHEN ERROR002 THEN
		ROLLBACK;
		HYBS.SET_ERRMSGS(P_ERRMSGS					-- エラーメッセージ配列
						,0							-- 行番号
						,2							-- エラー結果(0:正常 1:警告 2:異常)
						,'RGE0174'					-- ｼｽﾃﾑｴﾗｰが発生しました。{0}
						,WK_PGID||':'||SUBSTRB(SQLERRM,1,100)||':'||TO_CHAR(SQLCODE));		-- エラーメッセージ引数{0}
		-- 異常終了
		P_KEKKA := 2;

	WHEN ERROR003 THEN
		ROLLBACK;
		HYBS.SET_ERRMSGS(P_ERRMSGS					-- エラーメッセージ配列
						,0							-- 行番号
						,2							-- エラー結果(0:正常 1:警告 2:異常)
						,'RGE3120'					-- ｢PLNO：{0}は変更管理システムで出図ロック対象となっています。変更管理システム側で状況の確認をお願いします。｣
						,WK_PLNO);

		-- 異常終了
		P_KEKKA := 2;

	WHEN ERROR004 THEN
		ROLLBACK;
		HYBS.SET_ERRMSGS(P_ERRMSGS					-- エラーメッセージ配列
						,0							-- 行番号
						,2							-- エラー結果(0:正常 1:警告 2:異常)
						,'RGE3134'					-- ｢同一機番・同一親・同一風船内に複数の品番が存在します。親品番={0},風船={1}｣
						,WK_OYA
						,WK_FSNNO);

		-- 異常終了
		P_KEKKA := 2;

	-- エラー件数が保持最大数をオーバー
	WHEN HYBS.TOO_MANY_ERRORS THEN
		ROLLBACK;
		-- エラー件数最大数オーバーメッセージ設定
		HYBS.SET_LIMITOVER(P_ERRMSGS);

		-- 異常終了
		P_KEKKA := 2;

	-- その他例外
	WHEN OTHERS THEN
		ROLLBACK;
		-- エラーメッセージを配列パラメータ(P_ERRMSGS)に設定
		HYBS.SET_ERRMSGS(P_ERRMSGS						-- エラーメッセージ配列
						,0								-- 行番号
						,2								-- エラー結果(0:正常 1:警告 2:異常)
						,SQLCODE						-- エラーメッセージＩＤ
						,SUBSTRB(SQLERRM,1,100));		-- メッセージパラメータ１

		/* 処理NO欠番調査用 */
		LOGOUT(
		542				 -- 画面ID(NXT_DEBUG_CONTROLのKEY)
		,'RGP10542'			 -- パッケージ名
		,2				 -- 変更不要
		,SUBSTR(SQLERRM,1,100)	 	 -- 変更不要
		,'出図連絡箋作成時にエラー発生'	 -- 例外が発生した処理の名前
		,SUBSTR(SQLCODE ,1,100)		 -- 変更不要
		,'SYRNO=' || WK_SYRNO ||  'USERID=' || P_USERID 		 -- 例外発生時のSMKID,SYRNOなどの値
		);
		/* 処理NO欠番調査用 */

		-- 異常終了
		P_KEKKA := 9;

END RG10542A;

END RGP10542A;
/
CREATE OR REPLACE PACKAGE BODY SSYSTEM_MENU
AS

--本来はCB.CBP_UTILを使用したいが、VARCHAR2(10)であり、メールアドレス非対応の為、VARCHAR2(50)に変更したものをここで使用する。
--また、社外のユーザーだと変換対象のデータが無い可能性がある為、非表示。
FUNCTION USRSEQ_TO_LGINID(
    i_USRSEQ IN NUMBER
)RETURN VARCHAR2
AS
    w_LGINID VARCHAR2(50);
BEGIN
    SELECT
		LGINID
    INTO
        w_LGINID
    FROM
		CBM_LGIN
	WHERE
		USRSEQ = i_USRSEQ;

    RETURN w_LGINID;

--EXCEPTION
--    WHEN OTHERS THEN
--        RAISE_APPLICATION_ERROR(ERROR.CODE_20002,ERROR.MESG_20002);
--        RAISE;
END USRSEQ_TO_LGINID;

/*****************************************************************************/
/***  
ユーザー,権限IDを指定し、
そのユーザーが権限を持っているかを返す。 (0:未所持,1:所持)
***/
/*****************************************************************************/
FUNCTION F_HAS_AUTHID(
    i_USRSEQ IN VARCHAR2, --ユーザー管理番号
    i_AUTHID IN VARCHAR2
)RETURN VARCHAR2
AS
hasAuthId VARCHAR2(10);
BEGIN
    SELECT  count('X')
    	into hasAuthId
    FROM 
        CBV_SECG cvg 
    WHERE 
        EXISTS (
            --SECGVIEWSEQでユーザを紐づけ
            select 
                'X'               
            from 
                CBM_SSYSAUTHROLEACS css
                inner join CBM_SSYSUSE cse 
                on cse.SSYSROLESEQ = css.SSYSROLESEQ
                inner join CBM_SSYSAUTHROLE csr
                on css.SSYSROLESEQ = csr.SSYSROLESEQ
                inner join CBM_SSYSAUTHROLECTG csc
                on csr.SSYSROLECTGSEQ = csc.SSYSROLECTGSEQ

            where 
                cse.SSYSTEMID = csc.SSYSTEMID
                AND css.AUTHID = i_AUTHID
                and css.PRMI = CONST.PRMI_PERMISSION
                and cse.SECGVIEWSEQ = cvg.SECGVIEWSEQ
               
        )
        AND (
                --      20220714 修正   CBP_SSKKNR_SSK_GET.F_GET_USR_SSK を CBP_PRMI_ACS_GET.F_GET_USR_SECGに変更
                SSKUSRSEQ IN ( select SSKUSRSEQ from CBP_PRMI_ACS_GET.F_GET_USR_SECG(i_USRSEQ))
                AND KBNSEQ =CONST.KBN_SSK
                OR
                (SSKUSRSEQ =i_USRSEQ
                AND KBNSEQ =CONST.KBN_USR)
            );
    return hasAuthId;
END F_HAS_AUTHID;
/*****************************************************************************/
/***  
ユーザーを指定し、
そのユーザーが閲覧できるポータルのタブのAUTHIDを取得する
***/
/*****************************************************************************/
FUNCTION F_GET_AUTHID_SSYSTEM(
    i_USRSEQ IN VARCHAR2 --ユーザー管理番号
)RETURN CBT_AUTHLIST PIPELINED
AS
  CURSOR cAuthId
  IS          
    SELECT
    tbl.AUTHID
    FROM
    (
        SELECT
            cp.AUTHID
            , MAX(cp.PRMI) AS PRMI
        FROM
            TABLE (CBP_PRMI_ACS_GET.F_GET_USR_SECG(i_USRSEQ)) csc
            INNER JOIN CBT_PRMI cp
                ON cp.SECGVIEWSEQ = csc.SECGVIEWSEQ
                AND cp.CNDSEQ IN (
                    SELECT
                        cc.CNDSEQ
                    FROM
                        CBM_CND cc
                    WHERE
                        EXISTS (
                            SELECT
                                'X'
                            FROM
                                CBM_USR cu
                            WHERE
                                cu.USRSEQ = i_USRSEQ
                                AND (cc.SYKMID IS NULL OR cc.SYKMID = cu.SYKMID)
                                AND (
                                    cc.SYKIID IS NULL
                                    OR CBP_PRMI_ACS_GET.F_GET_USR_SKK(cu.SYKIID, cc.SYKIHKK, cc.SYKIID) = 1
                                )
                        )
                )
            INNER JOIN CBM_AUTH ca
                ON ca.AUTHID = cp.AUTHID
            INNER JOIN CBM_AUTHCTG cac
                ON ca.AUTHCTGID = cac.AUTHCTGID
                AND cac.AUTHKBN = '1'
        GROUP BY
            cp.AUTHID
    ) tbl
    WHERE
    tbl.PRMI =1;

BEGIN
  FOR row IN cAuthId LOOP
    pipe row(
        TYPE_AUTHLIST(row.AUTHID)
    );
  END LOOP;
   RETURN;
END F_GET_AUTHID_SSYSTEM;
/*****************************************************************************/
/***  
ユーザー管理番号を引数に
閲覧権限を持つサブシステムとサブシステム配下のタブ情報を取得する
***/
/*****************************************************************************/
FUNCTION F_GET_MENUS (
     i_USRSEQ IN VARCHAR2,
     i_SYSTEMID IN VARCHAR2 DEFAULT null,
     i_EXTERNALFLG IN NUMBER DEFAULT 0
) RETURN MENU_TABLE PIPELINED
AS
  w_url VARCHAR2(1000);
  CURSOR cSSYSTEM
  IS 
       WITH ROOTMENUS AS(
            SELECT
                app.SSYSTEMID as menuId
                ,null AS PARENTID
                , app.SSYSTEMNM as linkName
                , app.url
                , app.exurl
                , null as routerLink
                , app.DISPFLG as dispFlg
                --, rownum as DISPORDER
                , app.DISPORDER
                , app.INITIALDISPORDER
                --seqno--
                , app.dispSeqNo
                , app.orderSeqNo
                --version
                , app.dispVersion
                , app.orderVersion
            FROM
                TABLE(F_GET_AUTHID_SSYSTEM(i_USRSEQ)) ath
                RIGHT JOIN (
                    select
                        ssm.SSYSTEMID
                        , ssm.SSYSTEMNM
                        , ssm.AUTHID
                        , CAST(nvl(cstm_disp.VAL, 1) AS NUMBER(1)) as DISPFLG
                        , ssm.SSYSTEMURL as url
                        , ssm.SSYSTEMURL_EXT as exurl
                        , nvl(to_number(cstm_odr.VAL), ssm.DSPNO*100) as DISPORDER
                        , ssm.DSPNO *100 as INITIALDISPORDER
                        --seqno--
                        ,  cstm_disp.SEQNO as dispSeqNo
                        ,  cstm_odr.SEQNO as orderSeqNo
                        --version--
                        ,  cstm_disp.VERSION as dispVersion
                        ,  cstm_odr.VERSION as orderVersion
                    from
                        CBM_SSYSTEM ssm
                        left join CBT_CSTMINF cstm_disp
                            on cstm_disp.KEY = 'DISPLAY_PORTAL_TAB_' || ssm.SSYSTEMID
                            and cstm_disp.LGINID = USRSEQ_TO_LGINID(i_USRSEQ)
                        left join CBT_CSTMINF cstm_odr
                            on cstm_odr.KEY = 'ORDER_PORTAL_TAB_' || ssm.SSYSTEMID
                            and cstm_odr.LGINID = USRSEQ_TO_LGINID(i_USRSEQ)
                ) app
                    ON ath.AUTHID = app.AUTHID
             WHERE
             ath.AUTHID IS NOT NULL
             OR app.SSYSTEMID = i_SYSTEMID
        )

    SELECT 
        MENU.MENUID
        ,MENU.PARENTID
        ,MENU.LINKNAME
        ,MENU."URL"
        ,MENU.EXURL
        ,MENU.routerLink
        ,MENU.DISPFLG
        ,MENU.DISPORDER
        ,rownum as INITIALDISPORDER
        --seqno--
        ,MENU.dispSeqNo
        ,MENU.orderSeqNo
        --version--
        ,MENU.dispVersion
        ,MENU.orderVersion
    FROM
    (
        SELECT *
        FROM 
           (                
            SELECT 
                TAB.MENUID
                ,PARENTID
                ,LINKNAME
                ,"URL"
                , URL_EXT as exurl
                ,routerLink
                , CAST(nvl(cstm_disp.VAL, 1) AS NUMBER(1)) as DISPFLG
                , nvl(to_number(cstm_odr.VAL), TAB.DISPORDER) as DISPORDER
                , TAB.DISPORDER as INITIALDISPORDER
                --seqno--
                ,  cstm_disp.SEQNO as dispSeqNo
                ,  cstm_odr.SEQNO as orderSeqNo
                --version--
                ,  cstm_disp.VERSION as dispVersion
                ,  cstm_odr.VERSION as orderVersion
                FROM CBM_SSYSTEMMENU TAB
                LEFT JOIN CBT_CSTMINF cstm_disp
                    on cstm_disp.KEY = 'DISPLAY_PORTAL_TAB_' || TAB.MENUID
                    and cstm_disp.LGINID = USRSEQ_TO_LGINID(i_USRSEQ)
                LEFT JOIN CBT_CSTMINF cstm_odr
                    on cstm_odr.KEY = 'ORDER_PORTAL_TAB_' || TAB.MENUID
                    and cstm_odr.LGINID = USRSEQ_TO_LGINID(i_USRSEQ)
                --権限設定
                RIGHT JOIN (
                    SELECT
                    --        ssmAuth.menuId,
                    --        ssmAuth.authId menuAuth,
                    --        hasUsrAuth.authId as usrAuth
                        distinct ssmAuth.menuId
                      
                        
                     FROM 
                    --  ssystem_menuのAuthIdを分割  
                    (   
                        SELECT
                            A.menuId
                        ,REGEXP_SUBSTR(A.authId,'[^,]+', 1, lines.column_value) AS authId
                        FROM (
                             SELECT
                                menuId,authId
                            FROM CBM_SSYSTEMMENU
                        )a
                        ,TABLE( 
                            CAST(MULTISET( SELECT LEVEL FROM dual
                            CONNECT BY REGEXP_SUBSTR(A.authId, '[^,]+', 1, LEVEL) IS NOT NULL) AS sys.odciNumberList)
                        ) lines
                    ) ssmAuth
                    --  userが持っているAuthId一覧
                    left join (
                    
                        SELECT 
                            auth.AUTHID
                        FROM 
                            CBM_SSYSUSE cs
                            INNER JOIN CBM_SSYSAUTHROLEACS ccs 
                            ON ccs.SSYSROLESEQ = cs.SSYSROLESEQ
                            AND ccs.PRMI = CONST.PRMI_PERMISSION
                            INNER JOIN CBM_AUTH auth 
                            ON auth.AUTHID = ccs.AUTHID 
                        --            AND auth.AUTHCTGID = i_AUTHCTGID
                        WHERE 
                            EXISTS (
                                select 'X' from TABLE(CBP_PRMI_ACS_GET.F_GET_USR_SECG(i_USRSEQ)) ug 
                                where ug.SECGVIEWSEQ = cs.SECGVIEWSEQ 
--                                AND KBNSEQ =CONST.KBN_SSK
--                                OR
--                                (SSKUSRSEQ =i_USRSEQ
--                                AND KBNSEQ =CONST.KBN_USR)
                            )
                         --            AND cs.SSYSTEMID = i_SSYSTEMID
                        GROUP BY auth.AUTHID
                    ) hasUsrAuth
                    on hasUsrAuth.authId = ssmAuth.authId
                    where
                    ssmAuth.authId is null
                    or
                    hasUsrAuth.AUTHID is not null

                ) submenu
                on submenu.menuId = TAB.menuId
--                WHERE
--                --権限を持つシステム内のタグを取得する
--                (
--                    EXISTS (
--                            SELECT 'X'
--                            FROM 
--                            (
--                                SELECT
--                                    REGEXP_SUBSTR(A.value,'[^,]+', 1, lines.column_value) AS split_value
--                                FROM 
--                                    (SELECT
--                                        value
--                                    FROM (select TAB.AUTHID value from dual)
--                                    ) A
--                                ,TABLE( CAST(MULTISET( SELECT LEVEL FROM dual
--                                CONNECT BY REGEXP_SUBSTR(A.value, '[^,]+', 1, LEVEL) IS NOT NULL) AS sys.odciNumberList)) lines  
--                            ) AUTHLIST
--                            WHERE 
----                            EXISTS(
----                                select 'X'
----                                from TABLE(CAP_AUTH_GET.F_GET_AUTHROLE_USR(AUTHLIST.split_value))USR
----                                WHERE 
----                                USR.USRSEQ = i_USRSEQ
----                                    
----                            )
--
--                            --20210909 add F_HAS_AUTHID
--                            0 < SSYSTEM_MENU.F_HAS_AUTHID(i_USRSEQ,AUTHLIST.split_value) 
--                    )   
--                    OR TAB.AUTHID IS NULL
--                )   
--                AND  0<(SELECT count(*) FROM ROOTMENUS WHERE ROWNUM =1)
            UNION ALL
            SELECT *
            FROM ROOTMENUS  
            )
            ORDER BY INITIALDISPORDER
    )MENU
    ORDER BY MENU.DISPORDER;
         
BEGIN
  FOR row IN cSSYSTEM LOOP
    --URLに社内(社外)環境のURLを代入する。  
    IF i_EXTERNALFLG =1 AND row.EXURL IS NOT NULL THEN
        w_url := row.EXURL;
    ELSE
        w_url := row."URL";
    END IF;

    pipe row(
        TYPE_MENU( 
          row.MENUID,
          row.PARENTID,
          row.LINKNAME,
          w_url,
          row.ROUTERLINK,
          row.DISPFLG,
          row.DISPORDER,
          row.INITIALDISPORDER,  
          --seqno--
          row.dispSeqNo,
          row.orderSeqNo,
          --version
          row.dispVersion,
          row.orderVersion
        )
    );
  END LOOP;
   RETURN;
END F_GET_MENUS;

/*****************************************************************************/
/***  
 サブメニューの状態を取得する。（タブorサイドメニューか判断する）
***/
/*****************************************************************************/
FUNCTION F_SUBMENUFLG (
     i_USRSEQ IN VARCHAR2,
     i_SYSTEMID IN VARCHAR2
) RETURN TAB_TABLE PIPELINED
AS
  cstminfo TAB_TABLE := TAB_TABLE();
  i PLS_INTEGER :=1;
  CURSOR ctab
    IS 
       SELECT 
            key attrkey,
            NVL(VAL,0) attrval,
            LGINID lginid,
            SEQNO seqno,
            version version
        FROM
        CBT_CSTMINF cstminf
        WHERE
        cstminf.KEY = 'DISPLAY_SUBMENU_TAB_' || i_SYSTEMID
        --cstminf.KEY = 'DISPLAY_MENU_OLD'
        and cstminf.LGINID = USRSEQ_TO_LGINID(i_USRSEQ)
        and rownum =1;
BEGIN
    FOR row IN ctab LOOP
        pipe row(
            TYPE_TAB( 
                row.attrkey,
                row.attrval,
                row.lginid,
                row.seqno,
                row.version
            )
        );
    END LOOP;
        
  return;

END F_SUBMENUFLG;

/*****************************************************************************/
/***  
 PINがついているかどうかを判断する。
***/
/*****************************************************************************/
FUNCTION F_PINFLG (
     i_USERID IN VARCHAR2,
     i_SYSTEMID IN VARCHAR2
) RETURN TAB_TABLE PIPELINED
AS
  cstminfo TAB_TABLE := TAB_TABLE();
  i PLS_INTEGER :=1;
  CURSOR ctab
    IS 
       SELECT 
            key attrkey,
            NVL(VAL,0) attrval,
            LGINID lginid,
            SEQNO seqno,
            version version
        FROM
        CBT_CSTMINF cstminf
        WHERE
        cstminf.KEY = 'DISPLAY_SUBMENU_PIN_' || i_SYSTEMID
        --cstminf.KEY = 'DISPLAY_MENU_OLD'
        and cstminf.LGINID = i_USERID
        and rownum =1;
BEGIN
    FOR row IN ctab LOOP
        pipe row(
            TYPE_TAB( 
                row.attrkey,
                row.attrval,
                row.lginid,
                row.seqno,
                row.version
            )
        );
    END LOOP;
        
  return;

END F_PINFLG;

/*****************************************************************************/
/***  
メニューのお気に入り一覧を取得する
***/
/*****************************************************************************/
FUNCTION F_GET_FAVORITE (
     i_USRSEQ IN VARCHAR2
) RETURN FAVORITE_TABLE PIPELINED
AS
  CURSOR cfavorite
  IS 
    select *
    from
    (select
        TAB.menuId
        --display
        , CAST(nvl(cstm_disp.VAL, 1) AS NUMBER(1)) as DISPFLG
        --order
        , nvl(to_number(cstm_odr.VAL), TAB.DISPORDER) as DISPORDER
        --seqno
        , cstm_odr.SEQNO as orderSeqNo
        , cstm_disp.SEQNO as dispSeqNo
        --version
        , cstm_disp.VERSION as dispVersion
        , cstm_odr.VERSION as orderVersion
    from (select MENUID,DISPORDER
          from CBM_SSYSTEMMENU
          union
          select SSYSTEMID as MENUID,DSPNO as DISPORDER
          from CBM_SSYSTEM) TAB
    --order
    inner join CBT_CSTMINF cstm_disp
      on cstm_disp.KEY = 'DISPLAY_FAVORITE_TAB_' || TAB.menuId
      and cstm_disp.LGINID = USRSEQ_TO_LGINID(i_USRSEQ)
    --disp
    inner join CBT_CSTMINF cstm_odr
      on cstm_odr.KEY = 'ORDER_FAVORITE_TAB_' || TAB.menuId
      and cstm_odr.LGINID = USRSEQ_TO_LGINID(i_USRSEQ)
    )APP
    ORDER BY APP.DISPORDER;
         
BEGIN
  FOR row IN cfavorite LOOP
    pipe row(
        TYPE_FAVORITE( 
        row.MENUID,
        row.DISPFLG,
        row.DISPORDER,
        --seqno--
        row.ORDERSEQNO,
        row.DISPSEQNO,
        --version--
        row.DISPVERSION,
        row.ORDERVERSION
        )
    );
  END LOOP;
   RETURN;
END F_GET_FAVORITE;

/*****************************************************************************/
/***  
メニューの多言語を取得する。
***/
/*****************************************************************************/
FUNCTION F_GET_MULTILANG 
RETURN MULTILANG_TABLE PIPELINED
AS
  CURSOR cMultilang
  IS 
        SELECT LANGID AS LANG,CD AS MENUID ,DSPTXT AS LINKNAME
        FROM CBM_MLTILANG lang
            WHERE
                lang.TBLID = 'CBM_SSYSTEM'
            AND
                lang.CLMID = 'SSYSTEMID'
            
        UNION

        SELECT LANGID AS LANG, CD AS MENUID ,DSPTXT AS LINKNAME
        FROM CBM_MLTILANG lang
            WHERE
                lang.TBLID = 'CBM_SSYSTEMMENU'
            AND
                lang.CLMID = 'MENUID';
         
BEGIN
  FOR row IN cMultilang LOOP
    pipe row(
        TYPE_MULTILANG( 
        row.LANG,
        row.MENUID,
        row.LINKNAME
        )
    );
  END LOOP;
   RETURN;
END F_GET_MULTILANG;

/*****************************************************************************/
/***  
カスタムインフォメーションテーブルにログインIDと
KEYとそれに対応する値を登録する
***/
/*****************************************************************************/

PROCEDURE P_INS_CUSTOMEINFO(
  i_LGINID IN VARCHAR2, --ログインID
  i_ATTRKEY IN VARCHAR2, --KEY
  i_ATTRVAL IN VARCHAR2 --KEYに対応する値
) 
AS
BEGIN

        INSERT INTO
            CBT_CSTMINF
        (
            SEQNO
            ,LGINID
            ,KEY
            ,VAL
            ,PRGUPD
            ,DYSET
		    ,DYUPD
		    ,USRSET
		    ,USRUPD
		    ,VERSION
        )
        SELECT
            CBS_CSTMINF_SEQNO.nextval
            ,i_LGINID
            ,i_ATTRKEY
            ,i_ATTRVAL
            ,'CUSTOM_INFO'
            ,SYSTIMESTAMP
		    ,SYSTIMESTAMP
    		,i_LGINID
    		,i_LGINID
            ,1
        FROM DUAL;

EXCEPTION
	WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(ERROR.CODE_20999,ERROR.ERR_ROW||SQLERRM);
END P_INS_CUSTOMEINFO;

/*****************************************************************************/
/***  
カスタムインフォメーションテーブルを更新する
***/
/*****************************************************************************/

PROCEDURE P_UPD_CUSTOMEINFO(
  i_LGINID IN VARCHAR2, --更新対象のログインID
  i_ATTRKEY IN VARCHAR2, --更新対象のKEY
  i_ATTRVAL IN VARCHAR2, --更新対象のKEYに対応する値
  i_SEQNO IN VARCHAR2 --SEQNO
) 
AS
BEGIN

        UPDATE
            CBT_CSTMINF
        SET
            KEY = i_ATTRKEY
            ,VAL = i_ATTRVAL
            ,PRGUPD = 'CUSTOM_INFO'
    		,USRUPD = i_LGINID
    		,DYUPD = SYSTIMESTAMP
    		,VERSION = VERSION + 1
        WHERE
            SEQNO = i_SEQNO;

EXCEPTION
	WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(ERROR.CODE_20999,ERROR.ERR_ROW||SQLERRM);
END P_UPD_CUSTOMEINFO;

/*****************************************************************************/
/***  
カスタムインフォメーションテーブルを大量Insertする
***/
/*****************************************************************************/

PROCEDURE P_BULKINS_CUSTOMEINFO
(
    i_list IN SSYSTEM_MENU.CSTMINF_TABLE
) 
AS
  sql_str CLOB;
  sql_obj CLOB;
  BEGIN
  
    --insert対象のデータを作成する
    FOR i IN 1..i_list.count LOOP
        sql_obj := sql_obj || 'SELECT ' ;
        sql_obj := sql_obj ||    ''''||i_list(i).attrkey ||''''||' KEY,'; 
        sql_obj := sql_obj ||    ''''||i_list(i).attrval ||''''||' VAL, '; 
        sql_obj := sql_obj ||    ''''||i_list(i).lginid ||''''||' USERID '; 
        sql_obj := sql_obj || 'FROM DUAL UNION ALL ';
    END LOOP;
    sql_obj := SUBSTR (sql_obj,1,LENGTH(sql_obj)-10);
    --DBMS_OUTPUT.PUT_LINE(sql_obj);
    
    --SQL組み立て
    sql_str := '';
    sql_str := sql_str || ' INSERT ALL INTO                 ' ;
    sql_str := sql_str || '     CBT_CSTMINF                 ' ;
    sql_str := sql_str || ' (                               ' ;
    sql_str := sql_str || '     SEQNO                       ' ;
    sql_str := sql_str || '     ,LGINID                     ' ;
    sql_str := sql_str || '     ,KEY                        ' ;
    sql_str := sql_str || '     ,VAL                        ' ;
    sql_str := sql_str || '     ,PRGUPD                     ' ;
    sql_str := sql_str || '     ,DYSET                      ' ;
    sql_str := sql_str || '     ,DYUPD                      ' ;
    sql_str := sql_str || '     ,USRSET                     ' ;
    sql_str := sql_str || '     ,USRUPD                     ' ;
    sql_str := sql_str || '     ,VERSION                    ' ;
    sql_str := sql_str || ' )VALUES(                        ' ;
    sql_str := sql_str || '     CBS_CSTMINF_SEQNO.nextval   ' ;
    sql_str := sql_str || '     ,USERID                     ' ;
    sql_str := sql_str || '     ,KEY                        ' ;
    sql_str := sql_str || '     ,VAL                        ' ;
    sql_str := sql_str || '     ,''CUSTOM_INFO''            ' ;
    sql_str := sql_str || '     ,SYSTIMESTAMP               ' ;
    sql_str := sql_str || '     ,SYSTIMESTAMP               ' ;
    sql_str := sql_str || '     ,USERID                     ' ;
    sql_str := sql_str || '     ,USERID                     ' ;
    sql_str := sql_str || '     ,1                          ' ;
    sql_str := sql_str || ' )                               ' ;
    sql_str := sql_str || ' WITH BULKINS AS('||sql_obj||')  ' ;
    sql_str := sql_str || ' SELECT* FROM BULKINS            ' ;
                
                
    --DBMS_OUTPUT.PUT_LINE(sql_str);
    EXECUTE IMMEDIATE sql_str;
    commit; 
END P_BULKINS_CUSTOMEINFO;

/*****************************************************************************/
/***  
カスタムインフォメーションテーブルを大量更新する
***/
/*****************************************************************************/

PROCEDURE P_BULKUPD_CUSTOMEINFO
(
    i_list IN SSYSTEM_MENU.CSTMINF_TABLE
) 
AS
  sql_str CLOB;
  sql_obj CLOB;
  sql_seq CLOB;
  BEGIN
  
    --update対象のデータを作成する
    FOR i IN 1..i_list.count LOOP
        sql_obj := sql_obj ||' SELECT                                 ';
        sql_obj := sql_obj ||'     '''||i_list(i).seqno||''' SEQNO,   ';
        sql_obj := sql_obj ||'     '''||i_list(i).attrval||''' VAL,   ';
        sql_obj := sql_obj ||'     '''||i_list(i).lginid||''' USERID  ';
        sql_obj := sql_obj ||'FROM DUAL UNION ALL ';
	END LOOP;                 
    sql_obj := SUBSTR (sql_obj,1,LENGTH(sql_obj)-10); 
     
    
    --seqnoを作成する
    FOR i IN 1..i_list.count LOOP
        sql_seq := sql_seq || i_list(i).seqno||',';
	END LOOP;    
    sql_seq := SUBSTR (sql_seq,1,LENGTH(sql_seq)-1);            

    --SQL組み立て
    sql_str := '';                 
    sql_str := sql_str || ' UPDATE CBT_CSTMINF SET (                     ';
    sql_str := sql_str || '   VAL                                        ';
    sql_str := sql_str || '   ,"VERSION"                                 ';
    sql_str := sql_str || '   ,PRGUPD                                    ';
    sql_str := sql_str || '   ,DYUPD                                     ';
    sql_str := sql_str || '   ,USRUPD                                    ';
    sql_str := sql_str || ' ) = (                                        ';
    sql_str := sql_str || '   SELECT                                     ';
    sql_str := sql_str || '     VAL                                      ';
    sql_str := sql_str || '     ,CBT_CSTMINF."VERSION" +1 AS "VERSION"   ';
    sql_str := sql_str || '     ,''CUSTOM_INFO''                         ';
    sql_str := sql_str || '     ,SYSDATE                                 ';
    sql_str := sql_str || '     ,USERID                                  ';
    sql_str := sql_str || '   FROM('||sql_obj ||') UPDLIST               ';
    sql_str := sql_str || '   WHERE CBT_CSTMINF.SEQNO = UPDLIST.SEQNO    ';
    sql_str := sql_str || ' )                                            ';
    sql_str := sql_str || ' WHERE  CBT_CSTMINF.SEQNO in ('||sql_seq||')  ';
    
   -- DBMS_OUTPUT.PUT_LINE(sql_str);
    
    EXECUTE IMMEDIATE sql_str;
    commit; 
END P_BULKUPD_CUSTOMEINFO;

    
END SSYSTEM_MENU;
/
CREATE OR REPLACE procedure LOCAL_MSG_RTN(
	PI_PG		IN	varchar2,
	PI_STEP		IN	varchar2,
	PI_MSG		IN	varchar2,
	PI_JOBID	IN	varchar2,
	PI_PGNAME	IN	varchar2
	)
is
begin
	dbms_output.put_line(PI_PG || ',' ||
 						 PI_STEP || ',' ||
						 PI_MSG || ',' ||
						 PI_JOBID || ',' ||
						 PI_PGNAME);
end LOCAL_MSG_RTN;
/
CREATE SEQUENCE CBS_SSYSROLECTGSEQ
INCREMENT BY 1
START WITH 10
MAXVALUE 999999999999
MINVALUE 0
NOCYCLE 
CACHE 20
NOORDER 
NOSCALE
/
CREATE SEQUENCE CBS_SSYSROLESEQ
INCREMENT BY 1
START WITH 10
MAXVALUE 999999999999
MINVALUE 0
NOCYCLE 
CACHE 20
NOORDER 
NOSCALE
/
CREATE SEQUENCE LOGTBL_SEQNO
INCREMENT BY 1
START WITH 6631
MAXVALUE 999999999999
MINVALUE 1
NOCYCLE 
NOCACHE
NOORDER 
NOSCALE
/
CREATE SYNONYM BKN_SEC_LAA
 FOR BKN_SEC@DBSDT.LAA
/
CREATE SYNONYM CBM_AUTH
 FOR CB.CBM_AUTH
/
CREATE SYNONYM CBM_AUTHCTG
 FOR CB.CBM_AUTHCTG
/
CREATE SYNONYM CBM_CND
 FOR CB.CBM_CND
/
CREATE SYNONYM CBM_GRP_AUTHLIST
 FOR CB.CBM_GRP_AUTHLIST
/
CREATE SYNONYM CBM_KISYINF
 FOR CB.CBM_KISYINF
/
CREATE SYNONYM CBM_LGIN
 FOR CB.CBM_LGIN
/
CREATE SYNONYM CBM_MLTILANG
 FOR CB.CBM_MLTILANG
/
CREATE SYNONYM CBM_SSKINF
 FOR CB.CBM_SSKINF
/
CREATE SYNONYM CBM_SSKKSI
 FOR CB.CBM_SSKKSI
/
CREATE SYNONYM CBM_SSKKSI_TABLE
 FOR CB.CBM_SSKKSI_TABLE
/
CREATE SYNONYM CBM_SSKMEM
 FOR CB.CBM_SSKMEM
/
CREATE SYNONYM CBM_SSKMEM_TABLE
 FOR CB.CBM_SSKMEM_TABLE
/
CREATE SYNONYM CBM_USR
 FOR CB.CBM_USR
/
CREATE SYNONYM CBM_USR_TABLE
 FOR CB.CBM_USR_TABLE
/
CREATE SYNONYM CBP_PRMI_ACS_GET
 FOR CB.CBP_PRMI_ACS_GET
/
CREATE SYNONYM CBP_SSKKNR_SSK_GET
 FOR CB.CBP_SSKKNR_SSK_GET
/
CREATE SYNONYM CBP_SSKKNR_SSK_UPD
 FOR CB.CBP_SSKKNR_SSK_UPD
/
CREATE SYNONYM CBP_SSKKNR_USR_GET
 FOR CB.CBP_SSKKNR_USR_GET
/
CREATE SYNONYM CBP_SSKKNR_USR_UPD
 FOR CB.CBP_SSKKNR_USR_UPD
/
CREATE SYNONYM CBP_UTIL
 FOR CB.CBP_UTIL
/
CREATE SYNONYM CBP_UTIL_CSE
 FOR CB.CBP_UTIL_CSE
/
CREATE SYNONYM CBS_CSTMINF_SEQNO
 FOR CB.CBS_CSTMINF_SEQNO
/
CREATE SYNONYM CBS_SSKMEM_SEQNO
 FOR CB.CBS_SSKMEM_SEQNO
/
CREATE SYNONYM CBT_CSTMINF
 FOR CB.CBT_CSTMINF
/
CREATE SYNONYM CBT_PRMI
 FOR CB.CBT_PRMI
/
CREATE SYNONYM CBT_USERSEQCONVERT
 FOR CB.CBT_USERSEQCONVERT
/
CREATE SYNONYM CBT_USRATTRINF
 FOR CB.CBT_USRATTRINF
/
CREATE SYNONYM CBT_USRSEQLIST
 FOR CB.CBT_USRSEQLIST
/
CREATE SYNONYM CBV_SECG
 FOR CB.CBV_SECG
/
CREATE SYNONYM CBV_SECG_TABLE
 FOR CB.CBV_SECG_TABLE
/
CREATE SYNONYM CONST
 FOR CB.CONST
/
CREATE SYNONYM ERROR
 FOR CB.ERROR
/
CREATE SYNONYM GEA08
 FOR LAA.GEA08@DBSCT.LAA
/
CREATE SYNONYM HM17
 FOR MST_LAA.HM17
/
CREATE SYNONYM HYBS_LAA10
 FOR LAA.LAA10@DBSCT.LAA
/
CREATE SYNONYM HYBS_MST_ID
 FOR SSOSYS.MST_ID@DBSCT.SSOSYS
/
CREATE SYNONYM HYBS_MST01
 FOR LAA.MST01@DBSCT.LAA
/
CREATE SYNONYM HYBS_MST02
 FOR LAA.MST02@DBSCT.LAA
/
CREATE SYNONYM HYBS_MST03
 FOR LAA.MST03@DBSCT.LAA
/
CREATE SYNONYM HYBS_PIC01
 FOR LAA.PIC01@DBSCT.LAA
/
CREATE SYNONYM LAA01
 FOR MST_LAA.LAA01
/
CREATE SYNONYM LAA02
 FOR MST_LAA.LAA02
/
CREATE SYNONYM LMM101
 FOR LMM.LMM101@DBSCT.LMM
/
CREATE SYNONYM LMMM103
 FOR LMM.LMMM103@DBSCT.LMM
/
CREATE SYNONYM LMMM111
 FOR LMM.LMMM111@DBSCT.LMM
/
CREATE SYNONYM LMMM112
 FOR LMM.LMMM112@DBSCT.LMM
/
CREATE SYNONYM LMMM113
 FOR LMM.LMMM113@DBSCT.LMM
/
CREATE SYNONYM LMMM121
 FOR LMM.LMMM121@DBSCT.LMM
/
CREATE SYNONYM LMMM122
 FOR LMM.LMMM122@DBSCT.LMM
/
CREATE SYNONYM LMMP10002
 FOR LMM.LMMP10002@DBSCT.LMM
/
CREATE SYNONYM MST_BUKA
 FOR MST_SSOSYS.MST_BUKA
/
CREATE SYNONYM MST_ID
 FOR MST_SSOSYS.MST_ID
/
CREATE SYNONYM MST_PORTAL
 FOR MST_PORTAL@DBSCT.SSOSYS
/
CREATE SYNONYM MST_SYAIN
 FOR MST_SYAIN@DBSCT.SSOSYS
/
CREATE SYNONYM PA01
 FOR MST_LAA.PA01
/
CREATE SYNONYM PA02
 FOR MST_LAA.PA02
/
CREATE SYNONYM PA21
 FOR MST_LAA.PA21
/
CREATE SYNONYM PL_CLM_TA27
 FOR DBS5_USER.CAA_CLM_TA27@DBSAT.DBS5_USER
/
CREATE SYNONYM PL_TP619
 FOR CZ012048.TP619V04@HDB03_01.MURATEC.CO.JP
/
CREATE SYNONYM SSKSEQ_ARRAY
 FOR CB.SSKSEQ_ARRAY
/
CREATE SYNONYM SYAIN_MST
 FOR MST_LAA.SYAIN_MST
/
CREATE SYNONYM SYSMST_ID
 FOR MST_ID@DBSCT.SSOSYS
/
CREATE SYNONYM TYPE_CBM_SSKKSI
 FOR CB.TYPE_CBM_SSKKSI
/
CREATE SYNONYM TYPE_CBM_USR
 FOR CB.TYPE_CBM_USR
/
CREATE SYNONYM TYPE_GRP_AUTHLIST
 FOR CB.TYPE_GRP_AUTHLIST
/
CREATE SYNONYM TYPE_USRSEQLIST
 FOR CB.TYPE_USRSEQLIST
/
CREATE SYNONYM USR_AUTH_LAA
 FOR USR_AUTH@DBSDT.LAA
/
