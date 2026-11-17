-- ACEkanner local database: upgrade schema version 4 -> 5.
--
-- v5 adds examinations.questions_used: only questions 1..questions_used are in
-- the answer key and graded (e.g. 90 on a 100-item sheet); NULL = all. The
-- table is rebuilt with the new column (rows copied, questions_used NULL) and
-- its indexes are created again; tables that reference it keep working. The
-- app does the same in AppDatabase.migration (from4To5);
-- test/data/db/schema_export_test.dart checks v1 + the upgrade scripts = v5.

PRAGMA foreign_keys = OFF;
BEGIN;
CREATE TABLE "examinations_v5" ("id" TEXT NOT NULL PRIMARY KEY, "short_code" TEXT NOT NULL UNIQUE CHECK (length(short_code) = 8), "title" TEXT NOT NULL CHECK (length(trim(title)) BETWEEN 1 AND 160), "subject_id" TEXT REFERENCES subjects(id), "instructor_id" TEXT REFERENCES instructor_profiles(id)ON DELETE SET NULL, "exam_date" INTEGER, "item_count" INTEGER NOT NULL CHECK (item_count IN (50, 75, 100)), "choice_count" INTEGER NOT NULL DEFAULT 5 CHECK (choice_count BETWEEN 2 AND 5), "passing_percentage" REAL NOT NULL DEFAULT 75 CHECK (passing_percentage BETWEEN 0 AND 100), "multiple_mark_policy" TEXT NOT NULL DEFAULT 'incorrect' CHECK (multiple_mark_policy IN ('incorrect', 'zero')), "allow_negative_total" INTEGER NOT NULL DEFAULT FALSE, "omr_preset" TEXT NOT NULL DEFAULT 'standard' CHECK (omr_preset IN ('lenient', 'standard', 'strict', 'custom')), "omr_thresholds" TEXT, "student_id_digits" INTEGER NOT NULL DEFAULT 10 CHECK (student_id_digits BETWEEN 4 AND 12), "status" TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'ready', 'closed')), "created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER, "questions_used" INTEGER CHECK (questions_used IS NULL OR questions_used BETWEEN 1 AND item_count));
INSERT INTO "examinations_v5" SELECT *, NULL FROM "examinations";
DROP TABLE "examinations";
ALTER TABLE "examinations_v5" RENAME TO "examinations";
CREATE INDEX examinations_subject ON examinations (subject_id);
CREATE INDEX examinations_recent ON examinations (deleted_at, updated_at);
PRAGMA user_version = 5;
COMMIT;
PRAGMA foreign_keys = ON;
