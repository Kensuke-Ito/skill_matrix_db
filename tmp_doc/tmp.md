# ローカルDB構築手順

## 事前準備

- SQL実行は、VS Code の「SQL Developer」拡張機能の使用を想定。
- 接続方法・SQL実行方法は社内案内ページを参照。
- `SYS` の接続情報は以下の通り（パスワードは Oracle インストール時に設定したもの）。

### SQL実行手順（SYS接続後）

1. `SYS_connect` を右クリック
2. 「SQLワークシートを開く」
3. SQL入力
4. 右上の「スクリプトの実行」で実行

### コネクション準備

- `SYS` のほか、`CAA`・`CSG` もスキーマ作成後にコネクション作成しておく。

### 再構築時のクリーンアップ（必要時のみ）

すでに何度か構築を試している場合は、`SYS` で以下を実行して `CB` / `CAA` / `CSG` を削除する。

```sql
DROP USER CB CASCADE;
DROP USER CAA CASCADE;
DROP USER CSG CASCADE;
```

## 何をするか（概要）

Oracle DB に `CB` / `CAA` / `CSG` のスキーマを作成し、それぞれにダンプファイルを取り込んでローカルテストDBを構築する。

- `CB`: 社内システム全体のユーザーマスタ、ログイン、パスワード情報など
- `CAA`: システムアクセス許可などの権限マスタ
- `CSG`: スキルマトリックス用データテーブル

> `CB` / `CAA` の詳細は `\開発環境提供\01_コラボ\02_運用\01_権限設定\ER図\` を参照。

---

## 1. スキーマ作成

`SYS` で以下を実行し、スキーマ作成と `DBA` 付与を行う。

```sql
CREATE USER CB identified by CB;
GRANT DBA to CB;
CREATE USER CAA identified by CAA;
GRANT DBA to CAA;
CREATE USER CSG identified by CSG;
GRANT DBA to CSG;
```

## 2. CBダンプファイルインポート

1. `dmp_再連携ver.zip` をダウンロードして解凍
2. 同梱の「使用方法.txt」は無視
3. コマンドプロンプトで `CB.dmp` があるディレクトリへ移動
4. 次を実行（PowerShell不可）

```bash
imp userid='sys/<SYSパスワード>@localhost:1521/XEPDB1 as sysdba' file=CB.dmp fromuser=CB touser=CB log=imp_CB.log
```

5. 出力された `imp_CB.log` を Teams 上の `imp_CB_ok.log` と DIFF 比較し、一致ならOK

## 3. CBに必要な権限を付与

`SYS` で以下を実行。

```sql
GRANT EXECUTE ON DBMS_CRYPTO TO CB;
```

## 4. CAAへCBオブジェクト権限を付与

`SYS` で以下を実行。

- `ORA-04063: view "CB.CBV_NFTMPLT" にエラーがあります。` は無視してOK

```sql
DROP ROLE cb_to_caa_role;
CREATE ROLE cb_to_caa_role;

BEGIN
  -- テーブル
  FOR r IN (
    SELECT owner, table_name AS object_name
    FROM   all_tables
    WHERE  owner = 'CB'
  ) LOOP
    EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON '||
                      r.owner||'.'||r.object_name||' TO cb_to_caa_role';
  END LOOP;

  -- ビュー
  FOR r IN (
    SELECT owner, view_name AS object_name
    FROM   all_views
    WHERE  owner = 'CB'
  ) LOOP
    EXECUTE IMMEDIATE 'GRANT SELECT ON '||
                      r.owner||'.'||r.object_name||' TO cb_to_caa_role';
  END LOOP;

  -- シーケンス
  FOR r IN (
    SELECT sequence_owner AS owner, sequence_name AS object_name
    FROM   all_sequences
    WHERE  sequence_owner = 'CB'
  ) LOOP
    EXECUTE IMMEDIATE 'GRANT SELECT ON '||
                      r.owner||'.'||r.object_name||' TO cb_to_caa_role';
  END LOOP;

  -- プロシージャ/ファンクション/パッケージ
  FOR r IN (
    SELECT owner, object_name
    FROM   all_objects
    WHERE  owner = 'CB'
    AND    object_type IN ('PROCEDURE','FUNCTION','PACKAGE')
  ) LOOP
    EXECUTE IMMEDIATE 'GRANT EXECUTE ON '||
                      r.owner||'.'||r.object_name||' TO cb_to_caa_role';
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
```

## 5. CAAダンプファイル取込

1. コマンドプロンプトで `CAA.dmp` があるディレクトリへ移動
2. 次を実行（PowerShell不可）

```bash
imp userid='sys/<SYSパスワード>@localhost:1521/XEPDB1 as sysdba' file=CAA.dmp fromuser=CAA touser=CAA log=imp_CAA.log
```

3. `imp_CAA.log` を Teams 上の `imp_CAA_ok.log` と DIFF 比較し、一致ならOK

## 6. CAA1.sql〜CAA3.sql実行

VS Code で SQL ファイルを開き、右上「スクリプト実行」→ 接続で `CAA_connect` を選択。

### 6-1. CAA1_kawakami_modified.sql

- Teams内の `CAA1_kawakami_modified.sql` を実行
- ダンプファイル内の `CAA1.sql` は実行しない
- 以下エラーは無視してOK

```text
次のコマンドの開始中にエラーが発生しました : 行 210 -
CREATE OR REPLACE VIEW SAKU_USR……
```

### 6-2. CAA2.sql

- `CAA` フォルダ内の `CAA2.sql` を実行
- `CAA2.sql` は2回実行
- 以下のパッケージ系エラーは無視してOK

```text
PACKAGE CAAP0001
PACKAGE BODY CAAP0001
PACKAGE LAAP00002
PACKAGE BODY LAAP00002
PACKAGE RGP10212
PACKAGE BODY RGP10212
PACKAGE BODY CAAP0002
PACKAGE BODY CAAP0003
PACKAGE BODY CAP_AUTHLIST_UPDATE
PACKAGE BODY LAAP00001
PACKAGE BODY RGP10542A
PACKAGE BODY SSYSTEM_MENU
```

### 6-3. CAA3.sql

- `CAA` フォルダ内の `CAA3.sql` を実行

## 7. CSGスキーマに必要な権限付与

`SYS` で以下を実行。

```sql
DROP ROLE caa_to_csg_role;
CREATE ROLE caa_to_csg_role;

BEGIN
  -- テーブル
  FOR r IN (
    SELECT owner, table_name AS object_name
    FROM   all_tables
    WHERE  owner = 'CAA'
  ) LOOP
    EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON '||
                      r.owner||'.'||r.object_name||' TO caa_to_csg_role';
  END LOOP;

  -- ビュー
  FOR r IN (
    SELECT owner, view_name AS object_name
    FROM   all_views
    WHERE  owner = 'CAA'
  ) LOOP
    EXECUTE IMMEDIATE 'GRANT SELECT ON '||
                      r.owner||'.'||r.object_name||' TO caa_to_csg_role';
  END LOOP;

  -- シーケンス
  FOR r IN (
    SELECT sequence_owner AS owner, sequence_name AS object_name
    FROM   all_sequences
    WHERE  sequence_owner = 'CAA'
  ) LOOP
    EXECUTE IMMEDIATE 'GRANT SELECT ON '||
                      r.owner||'.'||r.object_name||' TO caa_to_csg_role';
  END LOOP;

  -- プロシージャ/ファンクション/パッケージ
  FOR r IN (
    SELECT owner, object_name
    FROM   all_objects
    WHERE  owner = 'CAA'
    AND    object_type IN ('PROCEDURE','FUNCTION','PACKAGE')
  ) LOOP
    EXECUTE IMMEDIATE 'GRANT EXECUTE ON '||
                      r.owner||'.'||r.object_name||' TO caa_to_csg_role';
  END LOOP;
END;
/

GRANT caa_to_csg_role TO CSG;
```

## 8. CSGのDB Script配下SQLを実行

`CSG` スキーマで以下順に実行する。

1. `TABLE` フォルダ
2. `CSG**/CSGM**.sql -> ADD_COLUMN`
3. `SEQUENCE` フォルダ
4. `FUNCTION` フォルダ
5. `VIEW` フォルダ
6. `INDEX` フォルダ（エラー発生あり）
7. `TRIGGER` フォルダ（`BIN$wrl...` のみエラーあり）
8. `SYNONYM` フォルダ

## 9. プログラム起動確認

別途「ローカル環境構築手順」に従い、ログイン可能であることを確認。

- この時点ではデータが表示されない想定

## 10. CSGデータ取込

1. `_DATA_sql_developer.sql` を `CSG` で実行
2. 右側に画面が表示された場合は `apply` を押す
3. 再アクセスし、テストデータ表示を確認
