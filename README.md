# skill_matrix/db ローカルDB（Docker版）

このディレクトリは、Oracle XE コンテナ上に `CB` / `CAA` / `CSG` を構築するためのセットアップです。

初回の `docker compose up -d` では `oracle/init` 配下のスクリプトが順番に実行され、永続ボリュームが空のときだけ DB が初期化されます。既存 DB への差分反映は初期化フローとは分離し、`oracle-csg-migrate` を明示実行する運用です。

## 目次

1. [概要](#1-概要)
2. [前提](#2-前提)
3. [対応OS](#3-対応os)
4. [ディレクトリ構成](#4-ディレクトリ構成)
5. [運用手順](#5-運用手順)
6. [DB接続情報](#6-db接続情報)
7. [注意事項](#7-注意事項)
8. [よくあるトラブル](#8-よくあるトラブル)

## 1. 概要

この環境でできること:

- `CB` / `CAA` / `CSG` スキーマの初期構築
- `CB` / `CAA` ダンプの import
- `CAA` SQL と `CSG` DBScript / テストデータの自動投入
- `oracle/sql/csg/migrations` 配下の差分 SQL の適用

初回初期化の自動化内容:

1. `CB` / `CAA` / `CSG` ユーザー作成
2. `CB` ダンプ import
3. `CB` への `DBMS_CRYPTO` 権限付与
4. `CAA -> CB` 権限付与（1回目）
5. `CAA` ダンプ import
6. `CAA1/2/3` 実行（`CAA2` は2回）
7. `CAA -> CB` 権限再付与（2回目）
8. `CAA` 依存オブジェクト再コンパイル（`CBV_USRINF`, `CBV_USRINF2`, `CAP_AUTH_GET`）
9. `CSG` に必要な `CAA` 権限付与
10. `CSG` DBScript 実行
11. `CSG` テストデータ SQL 実行

## 2. 前提

- Docker Desktop または Rancher Desktop が起動していること
- `docker compose` が利用できること
- dump ファイルは次のいずれかを配置していること
	- Data Pump 共有 dump: `oracle/dumps/cb/EXPORT_SCHEMA.DMP`
	- CAA 専用 Data Pump dump: `oracle/dumps/caa/EXPORT_SCHEMA.DMP`
	- legacy dump: `oracle/dumps/cb/cb.dmp` と `oracle/dumps/caa/caa.dmp`

### 2.1 dmp ファイルの取得と配置

`cb.dmp` / `caa.dmp` / `EXPORT_SCHEMA.DMP` はリポジトリに含めず、以下の SharePoint から取得してローカルに配置してください。

- 取得元: https://jmasystems.sharepoint.com/:u:/r/sites/msteams_2a7324/Shared%20Documents/20.%E3%82%B9%E3%82%AD%E3%83%AB%E3%83%9E%E3%83%88%E3%83%AA%E3%83%83%E3%82%AF%E3%82%B9/000000_%E5%85%B1%E9%80%9A/%E3%83%AD%E3%83%BC%E3%82%AB%E3%83%ABDB%E6%A7%8B%E7%AF%89%E9%96%A2%E4%BF%82/dmp_%E5%86%8D%E9%80%A3%E6%90%BAver.zip?csf=1&web=1&e=aHEzha

配置先:

- `oracle/dumps/cb/EXPORT_SCHEMA.DMP`（共有 dump の場合）
- `oracle/dumps/caa/EXPORT_SCHEMA.DMP`（CAA 専用 Data Pump dump を分離する場合）
- `oracle/dumps/cb/cb.dmp`
- `oracle/dumps/caa/caa.dmp`

例（zip 展開後に手動配置する場合）:

```bash
mkdir -p oracle/dumps/cb oracle/dumps/caa
# 共有 Data Pump dump を使う場合
cp <展開先>/EXPORT_SCHEMA.DMP oracle/dumps/cb/EXPORT_SCHEMA.DMP

# legacy dump を使う場合
cp <展開先>/cb.dmp oracle/dumps/cb/cb.dmp
cp <展開先>/caa.dmp oracle/dumps/caa/caa.dmp
```

## 3. 対応OS

### 3.1 macOS

- Intel Mac はそのまま利用できます。
- Apple Silicon では [docker-compose.yml](docker-compose.yml) で `linux/amd64` を指定しているため、エミュレーションで動作します。
- Docker Desktop では Rosetta / x86_64 emulation の有効化を推奨します。

### 3.2 Windows

- Windows 10/11 に対応しています。
- Docker Desktop の WSL2 backend を有効化してください。
- リポジトリは WSL 側のファイルシステムで扱うことを推奨します。
- PowerShell / Git Bash / WSL のいずれからでも `docker compose` を実行できます。

## 4. ディレクトリ構成

```text
.
├── docker-compose.yml
├── README.md
└── oracle/
	├── dumps/
	│   ├── cb/
	│   │   ├── EXPORT_SCHEMA.DMP
	│   │   └── cb.dmp
	│   └── caa/
	│       ├── EXPORT_SCHEMA.DMP
	│       └── caa.dmp
	├── init/
	│   ├── 01_create_users.sql
	│   ├── 02_grant_privileges.sql
	│   ├── 03_import_cb.sh
	│   ├── 04_grant_cb.sql
	│   ├── 05_exec_caa_to_cb.sql
	│   ├── 06_exec_caa_sqls.sh
	│   ├── 07_grant_csg.sql
	│   └── 08_exec_csg_scripts.sh
	└── sql/
		├── caa/
		│   ├── CAA1.sql
		│   ├── CAA2.SQL
		│   └── CAA3.SQL
		└── csg/
			├── migrations/
			│   └── 01_csg02_add_vr_columns.sql
			├── data/
			│   └── 10_csg_test_data.sql
			└── DBScript/
				├── TABLE/
				├── SEQUENCE/
				├── FUNCTION/
				├── VIEW/
				├── INDEX/
				├── TRIGGER/
				└── SYNONYM/
```

## 5. 運用手順

### 5.1 初回初期化

```bash
docker compose up -d
```

- 通常の `docker compose up -d` では `oracle-csg-migrate` は起動しません。
- 初回は 30～60 分かかります。

所要時間の目安:

- Oracle 起動: 5 分程度
- CB ダンプ import: 20～40 分
- CAA / CSG 初期化: 5～10 分

状態確認:

```bash
docker ps
docker logs oracle-xe | tail -50
until docker logs oracle-xe 2>&1 | grep -q 'DATABASE IS READY TO USE'; do echo "Waiting..." && sleep 30; done && echo "DONE"
```

### 5.1.1 通常の起動・停止

初期化完了後の日常的な起動・停止は以下で行います。

**起動:**

```bash
docker compose up -d
```

**停止:**

```bash
docker compose down
```

**ステータス確認:**

```bash
docker compose ps
```

**ログ確認:**

```bash
docker compose logs oracle-xe
```

### 5.2 再初期化

永続ボリュームを削除して、初期化を最初からやり直す場合:

```bash
docker compose down -v
docker compose up -d
```

### 5.3 既存DBへの差分適用

既存ボリュームを保持したまま `oracle/sql/csg/migrations` 配下の差分 SQL だけ反映する場合:

```bash
docker compose --profile manual rm -f oracle-csg-migrate
docker compose --profile manual up oracle-csg-migrate
```

ログ確認:

```bash
docker compose logs oracle-csg-migrate --no-color
```

- 差分適用 SQL は `SYSDBA` で `XEPDB1` に接続して実行されます。
- 新しい差分 SQL は `oracle/sql/csg/migrations` 配下へ追加してください。

## 6. DB接続情報

- Host: `localhost`
- Port: `1521`
- Service Name: `XEPDB1`
- SYS password: [docker-compose.yml](docker-compose.yml) の `ORACLE_PASSWORD`
- Schema users: `CB / CB`, `CAA / CAA`, `CSG / CSG`

## 7. 注意事項

- `oracle-csg-migrate` は手動実行専用です。
- `oracle/sql/csg/DBScript` と `oracle/sql/csg/data` の両方が未配置の場合、`CSG` スクリプト実行はスキップされます。
- `INDEX` や `TRIGGER` の既知エラーは `WHENEVER SQLERROR CONTINUE` で処理継続します。
- `oracle/dumps/**/*.dmp` は Git 管理対象外です。SharePoint から取得してローカル配置してください。
- シェルスクリプト改行コードは LF 必須です。CRLF だと `/usr/bin/env: 'bash\r': No such file or directory` が発生します。
- 本リポジトリは [.gitattributes](.gitattributes) で LF 固定です。既存チェックアウトが CRLF の場合は再チェックアウトまたは改行変換を実施してください。

## 8. よくあるトラブル

### 8.1 初回初期化が長時間かかる

予期された動作です。CB ダンプ import が最も時間を要します。

確認コマンド:

```bash
docker logs oracle-xe | tail -20
docker logs oracle-xe 2>&1 | grep 'CONTAINER: DONE\|DATABASE IS READY'
```

### 8.2 Apple Silicon で起動が遅い

- `linux/amd64` エミュレーションのため、初回初期化はさらに遅くなる場合があります。
- エミュレーション環境ではディスク I/O がボトルネックになりやすいです。

### 8.3 Windows で初期化スクリプトが失敗する

- 改行コードが CRLF になっていないか確認してください。
- 失敗状態が残っている場合は再初期化してください。

```bash
docker compose down -v
docker compose up -d
```

### 8.4 スキーマはあるがテーブルが無い

- `docker logs oracle-xe` に `ORA-01950` や `ORA-01045` が出ていないか確認してください。
- 本リポジトリでは [oracle/init/02_grant_privileges.sql](oracle/init/02_grant_privileges.sql) で対策済みです。
- 既存ボリュームに失敗状態が残っている場合は再初期化してください。

```bash
docker compose down -v
docker compose up -d
docker logs oracle-xe
```

### 8.5 既存DBへ差分だけ反映したい

```bash
docker compose --profile manual rm -f oracle-csg-migrate
docker compose --profile manual up oracle-csg-migrate
docker compose logs oracle-csg-migrate --no-color
```