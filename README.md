# skill_matrix/db ローカルDB（Docker版）

このディレクトリは、Oracle XE コンテナ上に `CB` / `CAA` / `CSG` を構築するためのセットアップです。

`docker compose up -d` の初回起動時に、`oracle/init` 配下のスクリプトを順番に実行して DB を初期化します。

## 前提

- Docker Desktop または Rancher Desktop が起動していること
- `docker compose` が利用できること

## 対応OS

- macOS: 対応
- Windows 10/11: 対応（Docker Desktop + WSL2 backend 推奨）

### macOS（Apple Silicon / Intel）

- Intel Mac: そのまま利用可能
- Apple Silicon (M1/M2/M3): `docker-compose.yml` で `linux/amd64` を指定しているため、エミュレーションで動作
- Docker Desktop で Rosetta / x86_64 emulation を有効にしておくことを推奨

### Windows

- Docker Desktop の WSL2 backend を有効化
- リポジトリは WSL 側のファイルシステムで扱うことを推奨（I/O が安定しやすい）
- PowerShell / Git Bash / WSL いずれからでも `docker compose` 実行可

## ディレクトリ構成

```text
.
├── docker-compose.yml
├── README.md
└── oracle/
	├── dumps/
	│   ├── cb/
	│   │   └── cb.dmp
	│   └── caa/
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
			└── DBScript/
				├── TABLE/
				├── SEQUENCE/
				├── FUNCTION/
				├── VIEW/
				├── INDEX/
				├── TRIGGER/
				└── SYNONYM/
```

## 反映済みフロー

`tmp_doc/tmp.md` の「1. スキーマ作成」以降をベースに、以下を自動化済みです。

1. `CB` / `CAA` / `CSG` ユーザー作成
2. `CB` ダンプ import
3. `CB` への `DBMS_CRYPTO` 権限付与
4. `CAA -> CB` 権限付与
5. `CAA` ダンプ import
6. `CAA1/2/3` 実行（`CAA2` は2回）
7. `CSG` に必要な `CAA` 権限付与
8. `CSG` DBScript 実行（存在する SQL を順次実行）

## 初回起動

```bash
docker compose up -d
```

初回は数分かかります。状態確認:

```bash
docker ps
docker logs oracle-xe
```

Windows でコンテナログを確認する場合も同じです。

## DB接続情報

- Host: `localhost`
- Port: `1521`
- Service Name: `XEPDB1`
- SYS password: `docker-compose.yml` の `ORACLE_PASSWORD`

スキーマユーザー:

- `CB / CB`
- `CAA / CAA`
- `CSG / CSG`

## 再初期化

初期化スクリプトは永続ボリュームが空のときだけ実行されます。

DDL/初期化処理を再実行したい場合:

```bash
docker compose down -v
docker compose up -d
```

## 注意事項

- 手順書上の `CAA1_kawakami_modified.sql` は、内容を反映した正式ファイル名 `CAA1.sql` として配置してください。
- `oracle/sql/csg/DBScript` が未配置の場合、`CSG` スクリプト実行はスキップされます。
- `INDEX` や `TRIGGER` の既知エラーは `WHENEVER SQLERROR CONTINUE` で処理継続します。
- シェルスクリプト改行コードは LF 必須です。CRLF だと初期化で `/usr/bin/env: 'bash\r': No such file or directory` が発生します。
- 本リポジトリは [.gitattributes](.gitattributes) で LF 固定しています。既存チェックアウトが CRLF の場合は再チェックアウトまたは改行変換を実施してください。

## よくあるトラブル

### Apple Silicon で起動が遅い

- `linux/amd64` エミュレーションのため初回起動は時間がかかります。

### Windows で初期化スクリプトが失敗する

- 改行コードを確認（CRLF になっていないか）
- `docker compose down -v` 後に再起動

```bash
docker compose down -v
docker compose up -d
```