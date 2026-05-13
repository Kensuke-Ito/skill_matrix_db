-- SYS または SYSTEM で実行される
-- スキーマ① CB
-- 他システムを含む社内システム全体のユーザーマスタ・ログイン・パスワード情報等を持つ 
CREATE USER CB IDENTIFIED by CB;

GRANT DBA TO CB;

-- スキーマ② CAA
-- システムへのアクセス許可等、権限のマスタを持つ 
-- ※CB/CAAの詳細については\開発環境提供\01_コラボ\02_運用\01_権限設定\ER図\を参照 
CREATE USER CAA IDENTIFIED by CAA;

GRANT DBA TO CAA;

-- スキーマ③CSG
-- スキルマトリックス用のデータテーブルを持つ 
CREATE USER CSG IDENTIFIED by CSG;

GRANT DBA TO CSG;