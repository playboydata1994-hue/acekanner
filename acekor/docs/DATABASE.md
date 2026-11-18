# ACEkor Grading Sheet: database reference (schema v1)

The source of truth is `app/lib/data/db/schema/acekor.drift` (plain SQL, compiled by Drift).

The database file is `acekor.db` in the app's private storage, encrypted with
SQLCipher 4 (AES-256). It uses a random 256-bit key held in the Android Keystore.

**Conventions**

- UUID v7 text keys.
- `DATETIME` = Unix epoch seconds (UTC).
- Activity dates are `YYYY-MM-DD` text.
- Weights and percentages are integer basis points (3000 = 30.00 %).
- Scores are whole points.
- Foreign keys are on.

## Tables

| Table | Key columns | Rules |
|---|---|---|
| `instructor_profile` | `id = 1`, instructor, school, address, department | One row |
| `sections` | name, program, year level, AY, semester | Unique (name, AY, semester). Delete → students keep their scores, `section_id` set to NULL |
| `students` | student_no (+ `student_no_key` = upper-case letters/digits), first/middle/last name, suffix, program, year level, `section_id`, AY, semester, `deleted_at` | Student ID unique among active students when present. Soft delete |
| `grade_scales` / `grade_scale_rows` | name, passing_bp, round_before_lookup / `min_bp` → grade, remark | Built-in `scale-ph-1to5` (1.00–5.00, 75 % passing) |
| `subjects` | code, title, AY, semester, `combine_method` (`total_points` \| `average_percent`), `grade_scale_id`, `grading_active`, `deleted_at` | Unique code per term. `grading_active` only when weights total 10000 |
| `subject_students` | (subject, student) | Enrolment |
| `categories` | id, name, kind (`quiz` \| `recitation` \| `exam`), default_max_points, built_in | Built-ins seeded. Custom categories are kind `exam` (MAX) |
| `subject_weights` | (subject, category) → weight_bp | 0..10000 |
| `activities` | subject, category, number, title, max_points (1..1000), activity_date, period (`prelim`/`midterm`/`prefinal`/`final`/''), remarks, `deleted_at` | Number unique per subject and category. Trigger: `max_points` cannot drop below a recorded score |
| `scores` | (activity, student) unique, points ≥ 0, remarks | Triggers refuse points > the activity's maximum |
| `score_history` | score, activity, student, change (`create`/`update`/`delete`), old/new points, max, at | Written by triggers on `scores`. Kept after deletions |
| `calc_history` | expression, result, at | Last 100 mini-calculator results |
| `app_settings` | setting_key → value | Typed by `UserSettings` |
| `license_cache` | `id = 1`, token | Last server-signed entitlement. Re-verified on every read |

## Built-in categories

| id | Name | Kind | Default points |
|---|---|---|---|
| quiz | Quiz | quiz (PRO) | 50 |
| recitation | Recitation | recitation (PRO) | 50 |
| prelim | Preliminary Examination | exam (MAX) | 100 |
| midterm | Midterm Examination | exam (MAX) | 100 |
| final | Final Examination | exam (MAX) | 100 |
| written | Written Examination | exam (MAX) | 100 |
| practical | Practical Examination | exam (MAX) | 100 |
| laboratory | Laboratory Examination | exam (MAX) | 100 |
| skills | Skills Demonstration | exam (MAX) | 100 |
| performance | Performance Assessment | exam (MAX) | 100 |
| other | Other Assessment | exam (MAX) | 100 |

New subjects start with these weights: Quiz 30 %, Recitation 20 %, Midterm 20 %, Final 20 %, Practical 10 %.

## Server tables (Supabase, `supabase/migrations/20261119000000_acekor_licensing.sql`)

These hold no student data.

| Table | Purpose |
|---|---|
| `acekor_accounts` | Supabase Auth user, Play account reference, trial dates, cached paid tier and its date |
| `acekor_devices` | Random install IDs and app version |
| `acekor_subscriptions` | Play purchase tokens, product, state, expiry, auto-renew, replaced/refunded flag |
| `acekor_tombstones` | One-way identity hash and trial start of deleted accounts (no second trial) |
