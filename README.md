# 途中で諦め

## Oracle XE関連ディレクトリ構成
```
project-root/
├ docker-compose.yml
├ oracle/
│  ├ init/
│  │  ├ 01_create_users.sql
│  │  ├ 02_import_cb.sh
│  │  ├ 03_grant_cb.sql
│  │  ├ 04_exec_caa_to_cb.sql
│  │  ├ 05_import_caa.sh
│  │  ├ 06_exec_caa_sqls.sh
│  │  ├ 07_grant_csg.sql
│  │  └ 08_exec_csg_scripts.sh
│  │
│  ├ dumps/
│  │  ├ cb/cb.dmp
│  │  └ caa/caa.dmp
│  │
│  ├ sql/
│  │  ├ caa/
│  │  │  ├ CAA1.sql
│  │  │  ├ CAA2.sql
│  │  │  └ CAA3.sql
│  │  └ csg/
│  │     └ DBScript/
│  │        ├ TABLE/
│  │        ├ SEQUENCE/
│  │        ├ FUNCTION/
│  │        ├ VIEW/
│  │        ├ INDEX/
│  │        ├ TRIGGER/
│  │        └ SYNONYM/
```

## Oracle XE 起動方法

事前に Rancher Desktop を起動してください。

- 起動 
```bash
docker compose up -d
```

- 起動確認
- 初回起動は数分かかります。以下のログが出れば起動完了です。
```bash
docker logs oracle-xe

DATABASE IS READY TO USE
```

- 停止する場合
```bash
docker compose down
```


## DB 初期化手順

DDLを修正した場合や、DBを作り直したい場合は
以下を必ず実行する。

```bash
docker compose down -v
docker compose up -d
```
※ -v を付けてボリューム込みで削除しないと初期DDLは再実行されない