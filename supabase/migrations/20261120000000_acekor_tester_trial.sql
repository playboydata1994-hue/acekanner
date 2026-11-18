-- ACEkor Grading Sheet: longer trials for the Google Play closed test.
--
-- Google Play's closed test needs testers to keep the app for 14 days in a
-- row, longer than the 7-day trial. While the single row of
-- acekor_trial_floor exists, every trial that started on or after
-- `applies_from` lasts at least until `until` (and never less than 7 days).
--
-- Remove the row before the public launch (acekor/docs/PLAY_RELEASE.md,
-- Phase D):
--     delete from public.acekor_trial_floor;
-- New trials are then 7 days again; testers keep the end date they have.

create table public.acekor_trial_floor (
    id smallint primary key default 1 check (id = 1),
    applies_from timestamptz not null,
    until timestamptz not null check (until > applies_from),
    note text not null default ''
);
alter table public.acekor_trial_floor enable row level security;
revoke all on public.acekor_trial_floor from public, anon, authenticated;
grant select on public.acekor_trial_floor to service_role;

insert into public.acekor_trial_floor (applies_from, until, note)
values (
    '2026-11-18 00:00:00+08',
    '2027-01-31 23:59:59+08',
    'Closed test: testers keep full access until January 31, 2027 (owner, 2026-11-18).'
);

-- When a trial that started at p_started ends: 7 days, or the floor's date
-- when the floor applies and is later.
create function public.acekor_trial_end(p_started timestamptz)
returns timestamptz
language sql
stable
set search_path = public, pg_temp
as $$
    select greatest(
        p_started + interval '7 days',
        (select f.until from acekor_trial_floor f where p_started >= f.applies_from)
    );
$$;

-- Starts the trial once per account (idempotent: a second call returns the
-- existing dates, even long after the trial ended).
create or replace function public.acekor_start_trial(p_account uuid)
returns void
language plpgsql
set search_path = public, pg_temp
as $$
begin
    update acekor_accounts
    set trial_started_at = now(), trial_ends_at = acekor_trial_end(now()), updated_at = now()
    where id = p_account and trial_started_at is null;
end;
$$;

-- Check-in state. Same as before, plus: a trial covered by the floor is
-- lengthened to it (for trials that started before the floor was added).
create or replace function public.acekor_state(
    p_account uuid,
    p_install text,
    p_identity_hash text default null,
    p_app_version text default null
)
returns jsonb
language plpgsql
set search_path = public, pg_temp
as $$
declare
    a acekor_accounts%rowtype;
begin
    if p_install !~ '^[A-Za-z0-9-]{16,64}$' then
        raise exception 'invalid_install_id' using errcode = '22023';
    end if;
    perform acekor_ensure_account(p_account, p_identity_hash);
    update acekor_accounts
    set trial_ends_at = acekor_trial_end(trial_started_at), updated_at = now()
    where id = p_account
        and trial_started_at is not null
        and trial_ends_at < acekor_trial_end(trial_started_at);
    insert into acekor_devices (account_id, install_id, app_version)
    values (p_account, p_install, left(p_app_version, 40))
    on conflict (account_id, install_id)
    do update set last_seen = now(), app_version = coalesce(excluded.app_version, acekor_devices.app_version);
    select * into a from acekor_accounts where id = p_account;
    return jsonb_build_object(
        'play_account_ref', a.play_account_ref,
        'trial_started', a.trial_started_at,
        'trial_until', a.trial_ends_at,
        'paid_tier', a.paid_tier,
        'paid_until', a.paid_until,
        'auto_renew', a.auto_renew
    );
end;
$$;

revoke execute on function public.acekor_trial_end(timestamptz) from public, anon, authenticated;
grant execute on function public.acekor_trial_end(timestamptz) to service_role;
