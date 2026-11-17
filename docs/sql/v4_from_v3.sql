-- ACEkanner local database: upgrade schema version 3 -> 4.
--
-- v4 lets a student's final answer be 32, meaning "counted wrong by the
-- instructor" (an unclear or double-shaded answer the instructor rejected).
-- SQLite cannot change a CHECK constraint in place, so student_answers is
-- rebuilt and its rows copied unchanged. The app does the same in
-- AppDatabase.migration (from3To4); test/data/db/schema_export_test.dart checks
-- v1 + the upgrade scripts = v4.

PRAGMA foreign_keys = OFF;
BEGIN;
CREATE TABLE "student_answers_v4" ("answer_sheet_id" TEXT NOT NULL REFERENCES answer_sheets(id)ON DELETE CASCADE, "question_no" INTEGER NOT NULL CHECK (question_no BETWEEN 1 AND 100), "detected_state" TEXT NOT NULL CHECK (detected_state IN ('answered', 'blank', 'multiple', 'uncertain')), "detected_mask" INTEGER NOT NULL DEFAULT 0 CHECK (detected_mask BETWEEN 0 AND 31), "bubble_scores" TEXT NOT NULL, "confidence" REAL NOT NULL CHECK (confidence BETWEEN 0 AND 1), "final_mask" INTEGER CHECK (final_mask IS NULL OR final_mask BETWEEN 0 AND 31 OR final_mask = 32), "resolved_by" TEXT CHECK (resolved_by IS NULL OR resolved_by IN ('engine', 'instructor')), "review_note" TEXT CHECK (review_note IS NULL OR length(review_note) <= 300), PRIMARY KEY(answer_sheet_id, question_no));
INSERT INTO "student_answers_v4" SELECT * FROM "student_answers";
DROP TABLE "student_answers";
ALTER TABLE "student_answers_v4" RENAME TO "student_answers";
PRAGMA user_version = 4;
COMMIT;
PRAGMA foreign_keys = ON;
