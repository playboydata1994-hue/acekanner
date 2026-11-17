-- ACEkanner local database: upgrade schema version 2 -> 3.
--
-- v3 allows a fifth exam set (E). SQLite cannot change a CHECK constraint in
-- place, so examination_versions is rebuilt and its rows copied unchanged;
-- tables that reference it keep working because the name stays the same.
-- The app does the same in AppDatabase.migration (from2To3);
-- test/data/db/schema_export_test.dart checks v1 + v2_from_v1 + this = v3.

PRAGMA foreign_keys = OFF;
BEGIN;
CREATE TABLE "examination_versions_v3" ("id" TEXT NOT NULL PRIMARY KEY, "examination_id" TEXT NOT NULL REFERENCES examinations(id)ON DELETE CASCADE, "label" TEXT NOT NULL CHECK (label IN ('A', 'B', 'C', 'D', 'E')), "created_at" INTEGER NOT NULL, UNIQUE(examination_id, label));
INSERT INTO "examination_versions_v3" SELECT * FROM "examination_versions";
DROP TABLE "examination_versions";
ALTER TABLE "examination_versions_v3" RENAME TO "examination_versions";
PRAGMA user_version = 3;
COMMIT;
PRAGMA foreign_keys = ON;
