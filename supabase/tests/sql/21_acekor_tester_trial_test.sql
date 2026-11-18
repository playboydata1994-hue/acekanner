-- Tests for the closed-test trial floor (migration 20261120000000_acekor_tester_trial.sql).
\set ON_ERROR_STOP on
reset role;
create temp table t_f as select
    '66666666-6666-6666-6666-666666666666'::uuid as early,
    '77777777-7777-7777-7777-777777777777'::uuid as tester,
    '88888888-8888-8888-8888-888888888888'::uuid as public_user;
insert into auth.users (id, email) select early, 'early@example.com' from t_f;
insert into auth.users (id, email) select tester, 'tester@example.com' from t_f;
insert into auth.users (id, email) select public_user, 'public@example.com' from t_f;
grant select on t_f to service_role;

create or replace function pg_temp.check(ok boolean, what text) returns void language plpgsql as $$
begin
    if not coalesce(ok, false) then raise exception 'FAILED: %', what; end if;
    raise notice 'ok: %', what;
end $$;

-- An account whose 7-day trial started before the floor existed (like the owner's).
set role service_role;
do $$
declare a uuid := (select early from t_f);
begin
    perform acekor_state(a, 'install-floor-0000-0001');
    perform acekor_start_trial(a);
end $$;
reset role;
update acekor_accounts set trial_started_at = now() - interval '1 day', trial_ends_at = now() + interval '6 days'
where id = (select early from t_f);

-- The floor: trials since yesterday last until 60 days from now.
delete from acekor_trial_floor;
insert into acekor_trial_floor (applies_from, until) values (now() - interval '2 days', now() + interval '60 days');
create temp table t_until as select until from acekor_trial_floor;
grant select on t_until to service_role;
set role service_role;

-- 1. A new trial during the test lasts until the floor's date.
do $$
declare s jsonb; a uuid := (select tester from t_f);
begin
    perform acekor_state(a, 'install-floor-0000-0002');
    perform acekor_start_trial(a);
    s := acekor_state(a, 'install-floor-0000-0002');
    perform pg_temp.check((s->>'trial_until')::timestamptz = (select until from t_until), 'new trial lasts until the floor date');
end $$;

-- 2. A running trial that started before the floor is lengthened at check-in.
do $$
declare s jsonb; a uuid := (select early from t_f);
begin
    s := acekor_state(a, 'install-floor-0000-0001');
    perform pg_temp.check((s->>'trial_until')::timestamptz = (select until from t_until), 'running trial lengthened to the floor date');
end $$;

-- 3. Never shorter than 7 days, even when the floor date is sooner.
reset role;
update acekor_trial_floor set until = now() + interval '2 days';
set role service_role;
do $$
declare a uuid := (select tester from t_f);
begin
    perform pg_temp.check(acekor_trial_end(now()) = now() + interval '7 days', 'floor sooner than 7 days: 7 days');
    perform pg_temp.check(
        (acekor_state(a, 'install-floor-0000-0002')->>'trial_until')::timestamptz = (select until from t_until),
        'an end date already given is never shortened'
    );
end $$;

-- 4. After the floor is removed (public launch), new trials are 7 days again.
reset role;
delete from acekor_trial_floor;
set role service_role;
do $$
declare s jsonb; a uuid := (select public_user from t_f);
begin
    perform acekor_state(a, 'install-floor-0000-0003');
    perform acekor_start_trial(a);
    s := acekor_state(a, 'install-floor-0000-0003');
    perform pg_temp.check((s->>'trial_until')::timestamptz - (s->>'trial_started')::timestamptz = interval '7 days', 'after the floor: 7 days');
    s := acekor_state((select tester from t_f), 'install-floor-0000-0002');
    perform pg_temp.check((s->>'trial_until')::timestamptz = (select until from t_until), 'testers keep their date');
end $$;

-- 5. Clients cannot read or change the floor, or call the helper.
reset role;
set role authenticated;
do $$
begin
    begin
        perform 1 from acekor_trial_floor;
        raise exception 'FAILED: authenticated can read the floor';
    exception when insufficient_privilege then raise notice 'ok: authenticated cannot read the floor';
    end;
    begin
        perform acekor_trial_end(now());
        raise exception 'FAILED: authenticated can call acekor_trial_end';
    exception when insufficient_privilege then raise notice 'ok: authenticated cannot call acekor_trial_end';
    end;
end $$;
reset role;
