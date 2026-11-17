-- ACEkanner local database: upgrade schema version 1 -> 2.
--
-- v2 makes the instructor's full name optional. SQLite cannot change a CHECK
-- constraint in place, so instructor_profiles is rebuilt and its rows copied
-- unchanged. The app does the same in AppDatabase.migration (from1To2);
-- test/data/db/schema_export_test.dart checks that v1 + this script equals v2.

PRAGMA foreign_keys = OFF;
BEGIN;
CREATE TABLE "instructor_profiles_v2" ("id" TEXT NOT NULL PRIMARY KEY, "full_name" TEXT CHECK (full_name IS NULL OR length(trim(full_name)) BETWEEN 1 AND 120), "honorific" TEXT CHECK (honorific IS NULL OR length(honorific) <= 20), "email" TEXT CHECK (email IS NULL OR length(email) <= 254), "employee_no" TEXT CHECK (employee_no IS NULL OR length(employee_no) <= 40), "school_name" TEXT CHECK (school_name IS NULL OR length(school_name) <= 160), "school_address" TEXT CHECK (school_address IS NULL OR length(school_address) <= 240), "department" TEXT CHECK (department IS NULL OR length(department) <= 160), "logo_path" TEXT, "created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER);
INSERT INTO "instructor_profiles_v2" SELECT * FROM "instructor_profiles";
DROP TABLE "instructor_profiles";
ALTER TABLE "instructor_profiles_v2" RENAME TO "instructor_profiles";
PRAGMA user_version = 2;
COMMIT;
PRAGMA foreign_keys = ON;
