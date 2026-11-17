# ACEkanner — Local Database Reference

| | |
|---|---|
| Engine | SQLite via SQLCipher 4.20 (AES-256), accessed with Drift 2.35 |
| File | `<app private files>/acekanner.db` (+ `-wal`, `-shm`) |
| Key | 256-bit random, generated on first run, stored in the Android Keystore (`flutter_secure_storage`) |
| Journal | WAL, `synchronous = FULL`: committed data survives app kills and power loss |
| Schema version | 1 |
| Source of truth | [`app/lib/data/db/schema/acekanner.drift`](../app/lib/data/db/schema/acekanner.drift) |
| SQL schema | [`docs/sql/v5_schema.sql`](sql/v5_schema.sql) (generated; a test keeps it identical to the app). Upgrades: [`v2_from_v1.sql`](sql/v2_from_v1.sql), [`v3_from_v2.sql`](sql/v3_from_v2.sql), [`v4_from_v3.sql`](sql/v4_from_v3.sql), [`v5_from_v4.sql`](sql/v5_from_v4.sql) |
| Schema snapshot | `app/drift_schemas/app_database/drift_schema_v1.json` (for migration tests) |

## Conventions

- **IDs**: UUID v7 text. They're sortable by creation time and unique across devices, so a
  restored backup can never collide with existing rows.
- **Time**: `DATETIME` columns hold Unix epoch seconds (UTC).
- **Booleans**: `INTEGER` 0/1.
- **Answer bitmasks**: A = 1, B = 2, C = 4, D = 8, E = 16. "A and C" is 5. 0 means none.
- **Soft delete**: master data the instructor manages has `deleted_at`. Unique indexes
  apply only to active rows, so a deleted subject's code can be reused.
- **Foreign keys** are enforced on every connection. `ON DELETE CASCADE` follows ownership
  (an examination owns its versions, keys, sheets, answers and results). `NO ACTION`
  (the default) is used where two cascade paths meet, because SQLite checks it at the end
  of the statement, after the cascades finish.
- **Every multi-row operation runs in one transaction**: finalize a paper, regrade,
  import a roster, restore a backup.

## Entity overview

```
instructor_profiles ─┐
subjects ────────────┼─< examinations >─┬─< examination_sections >── sections >── courses
                     │        │         │                               │
                     │        │         └─< printed_sheets              └─< section_students >── students
                     │        ├─< examination_versions ─< answer_keys ─< answer_key_items
                     │        ├─< scan_sessions
                     │        └─< answer_sheets ─┬─< student_answers
                     │                           └─< examination_results >── answer_keys
scan_ledger ··· answer_sheets (link cleared on purge; the charge itself is permanent)
subscription_entitlements · audit_logs · application_settings · backup_records (standalone)
```

---

## Tables

### 1. `instructor_profiles`
The instructor using the app, plus school details printed on sheets and reports
(`school_name`, `school_address`, `department`, `logo_path`). Normally there is one active
row. Soft-deletable.

### 2. `subjects`
Subjects taught, e.g. `CS101 — Programming 1`. `code` is unique (case-insensitive) among
active subjects. `units` is optional.

### 3. `courses`
Degree programs, e.g. `BSIT — Bachelor of Science in Information Technology`. `code` is
unique among active courses.

### 4. `sections`
Class blocks, e.g. `BSIT 2-A`, with optional `course_id`, `year_level` (1–6),
`school_year` (`2026-2027`) and `term` (`1st Semester`). The name is unique per school year
and term.

### `section_students` (roster join)
Which students belong to which section. Composite primary key (`section_id`,
`student_id`), so a student can be in several sections without being duplicated.

### 9. `students`
| Column | Purpose |
|---|---|
| `student_no` | Official number exactly as written by the school (`2021-00123`) |
| `student_no_key` | Normalized for matching: letters and digits only, upper-case (`202100123`). The shaded grid is matched against this. Unique among active students. |
| `last_name`, `first_name`, `middle_name`, `suffix`, `email` | Identity for reports |

### 5. `examinations`
| Column | Purpose |
|---|---|
| `short_code` | 8-character code printed on sheets and in the QR code |
| `item_count` | 50, 75 or 100 (CHECK) |
| `choice_count` | 5 (A–E). The column allows 2–5 for future templates. |
| `passing_percentage` | Default 75 |
| `multiple_mark_policy` | `incorrect` (negative marking applies) or `zero` |
| `allow_negative_total` | Whether negative marking may push a total below 0 |
| `omr_preset`, `omr_thresholds` | Recognition sensitivity (`lenient`/`standard`/`strict`/`custom` + JSON) |
| `student_id_digits` | Digit columns in the shaded student-number grid (4–12) |
| `questions_used` | v5. Questions actually used (1..`item_count`), e.g. 90 on a 100-item sheet: only questions 1..N are in the key's completeness, graded and analysed; later answers are ignored. NULL = all |
| `status` | `draft` → `ready` (key complete) → `closed` |

### `examination_sections` (join)
The sections that take an examination.

### 6. `examination_versions`
Exam sets for shuffled versions: `A`–`D`, unique per examination. Single-version exams
have only `A`.

### 7. `answer_keys`
One row per **revision** of a version's key. `UNIQUE(examination_version_id, revision)`.
A partial unique index allows exactly one `is_current = 1` per version. Correcting a key
after scanning creates revision N+1 and triggers a regrade. `change_note` records why.

### 8. `answer_key_items`
Per question: `correct_mask` (accepted answers; 0 = not set yet), `points`,
`negative_points`, and `mode` (`normal`, `bonus` = everyone earns it, `dropped` = excluded).
Primary key (`answer_key_id`, `question_no`).

### `printed_sheets`
Each generated sheet document. A generic sheet (`student_id` NULL) can be photocopied. A
personalized sheet carries a student and a unique `sheet_code` (inside its QR) that
identifies that physical paper. `paper_size` is `a4`, `letter` or `long` (8.5×13 in).

### 11. `scan_sessions`
One camera session (`single` or `batch`) with counters for attempted, rejected and
finalized captures. Used for batch progress and performance analysis.

### 10. `answer_sheets`
One scanned student paper.

| Column | Purpose |
|---|---|
| `status` | `needs_review` → `finalized`, or `rejected` / `superseded` (replaced by a re-scan) |
| `student_id`, `detected_student_no` | Matched roster student, and the raw number read from the sheet |
| `submission_key` | SHA-256 of (exam, version, student identity, paper identity). Required when finalized (CHECK). |
| `image_path`, `rectified_image_path` | Original and perspective-corrected images (app-private) |
| `omr_payload`, `omr_engine_version` | Raw engine output, kept for audit and re-analysis |
| `quality_score`, `flagged_count` | Image quality and number of answers needing review |

A partial unique index allows **only one finalized sheet per `submission_key`**. A
re-scan of the same paper must supersede the old one instead of duplicating it.

### 12. `student_answers`
Per question of a sheet: `detected_state` (`answered`, `blank`, `multiple`, `uncertain`),
`detected_mask`, `bubble_scores` (JSON array of five 0–1 darkness scores), `confidence`,
and `final_mask` (the answer used for grading). `final_mask` stays NULL while an uncertain
answer is unresolved; **32** means the instructor counted the answer wrong (for example an
unclear or double-shaded answer) — graded as a wrong answer, never part of a key, while
`detected_state`/`detected_mask` keep what was actually read. `resolved_by` (`engine`/`instructor`) shows who decided it.

### 13. `examination_results`
Score of one sheet under one answer-key revision: counts (correct, incorrect, blank,
multiple), `earned_points`, `possible_points`, `percentage`, `passed`.
`UNIQUE(answer_sheet_id, answer_key_id)`, and one `is_current` row per sheet. Regrading
adds rows; earlier results remain for audit.

### 14. `subscription_entitlements`
Server-signed entitlement tokens (Ed25519 compact JWS). **The token is the only source of
truth.** The other columns (`tier`, `free_used`, `lease`, `premium_until`,
`offline_until`, …) are caches that are re-derived from a verified token on load. Editing
them grants nothing. One current row.

### 15. `scan_ledger`
The record of consumed scans. Designed so it can't be "reset" or double-charged:

- `submission_key` is **UNIQUE**, so the same paper can never be charged twice.
- `seq` is AUTOINCREMENT, so sequence numbers are never reused.
- Each row stores `prev_hash` and `entry_hash`:
  `entry_hash = SHA-256(prev_hash | id | account_id | submission_key | tier | entitlement_token_id | consumed_at)`.
  Removing or altering a row breaks the chain.
- `mac` = HMAC-SHA256(`entry_hash`) with a per-install secret in the Android Keystore, so
  rows can't be forged without that key.
- **Triggers** abort every `DELETE`, and any `UPDATE` except recording `synced_at` /
  `server_receipt` once, or clearing `answer_sheet_id` when an examination is purged.
- The server keeps the authoritative lifetime count. Wiping the database, or reinstalling,
  does not restore free scans.

### 16. `audit_logs`
Append-only, hash-chained history (triggers block `UPDATE` and `DELETE`). Records events
such as `answer_key.revised`, `answer.overridden`, `results.regraded`,
`examination.purged`, `backup.restored`, `entitlement.changed`. It holds IDs only, never
student names, so it can outlive purged data without keeping personal information.
`examination_id` is deliberately not a foreign key, so history survives a purge.

### 17. `application_settings`
Key/value settings (e.g. `onboarding.completed.v1`), read and written through
`SettingsRepository`.

### 18. `backup_records`
History of local exports, cloud uploads (opt-in) and restores: `status`, `size_bytes`,
`sha256`, `schema_version`, `encrypted`, `error_message`.

---

## Indexes (non-primary)

| Index | Why |
|---|---|
| `subjects_code_active`, `courses_code_active` | Unique codes among active rows (case-insensitive) |
| `sections_name_term_active` | Unique section name per school year and term |
| `students_no_key_active` | One active student per normalized number; fast grid matching |
| `students_name` | Alphabetical rosters |
| `section_students_student`, `examination_sections_section` | Reverse lookups |
| `examinations_subject`, `examinations_recent` | Dashboard and per-subject lists |
| `answer_keys_one_current` | Exactly one current key revision per version |
| `printed_sheets_exam`, `printed_sheets_student` | Sheet lookups |
| `scan_sessions_exam` | Session history per exam |
| `answer_sheets_one_final` | No duplicate finalized submissions |
| `answer_sheets_exam_status`, `answer_sheets_student` | Results lists, review queues |
| `examination_results_one_current`, `examination_results_key` | Current scores; regrade by key |
| `subscription_entitlements_one_current` | One active entitlement |
| `scan_ledger_unsynced` | Find rows to upload |
| `audit_logs_exam`, `audit_logs_entity` | Per-exam and per-entity history |
| `backup_records_started` | Backup history |

## Migrations

1. Change `acekanner.drift`, bump `AppDatabase.currentSchemaVersion`.
2. `dart run drift_dev make-migrations`. This snapshots the new schema into
   `drift_schemas/` and generates step-by-step migration helpers and tests under
   `test/drift/`.
3. Implement the step in `AppDatabase.migration.onUpgrade` (using `stepByStep`).
4. Export the new SQL to `docs/sql/vN_schema.sql` and add a `docs/sql/vN_from_vN-1.sql`
   upgrade script.
5. Run the generated migration tests. They open a database at every older version and
   verify the upgrade preserves data.

History: **v1** initial schema; **v2** (app 0.6.1) `instructor_profiles.full_name` optional; **v3** (app 0.6.3) exam set E allowed in `examination_versions.label`; **v4** (app 0.6.5) `student_answers.final_mask` may be 32 (counted wrong by the instructor); **v5** (app 0.7.0) `examinations.questions_used`.

The app refuses to open a database from an unknown older version rather than guess.
There's no silent data loss.

## Verified by tests (`app/test/data/db/`)

- All 21 tables exist; foreign keys are on.
- Item count limited to 50/75/100; answer masks limited to A–E.
- Sheets must reference an existing examination; finalized sheets need a submission key.
- Only one finalized sheet per submission; drafts may repeat.
- Only one current answer key per version.
- Subject codes are unique among active rows, case-insensitively, and reusable after soft delete.
- Scan ledger: no double charge, no delete, no edit of charged fields, sync recorded once,
  and purging an exam keeps the charge.
- Audit log can't be updated or deleted.
- Deleting an examination removes all of its scan data in one statement.
- Dashboard queries count correctly.
- `docs/sql/v5_schema.sql` produces exactly the app's schema, and `v1_schema.sql` + the upgrade scripts reach it without losing rows.
- The app migrations keep every row (`test/drift/app_database/migration_test.dart`: v1→v2 profiles, v2→v3 sets, keys and references).
