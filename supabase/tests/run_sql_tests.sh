#!/usr/bin/env bash
# Runs the migration and the SQL tests on a throwaway PostgreSQL database.
# Usage: PGHOST=localhost PGPORT=54329 PGUSER=postgres supabase/tests/run_sql_tests.sh
set -euo pipefail
cd "$(dirname "$0")/.."
DB=acek_licensing_test
dropdb --if-exists "$DB" && createdb "$DB"
psql -q -v ON_ERROR_STOP=1 -d "$DB" -f tests/sql/00_supabase_stub.sql
for m in migrations/*.sql; do psql -q -v ON_ERROR_STOP=1 -d "$DB" -f "$m"; done
psql -q -v ON_ERROR_STOP=1 -d "$DB" -f tests/sql/10_licensing_test.sql
dropdb "$DB"
