-- Behaviour tests for the ACEKOR Calculator licensing functions.
\set ON_ERROR_STOP on
reset role;
create temp table t_k as select
    '33333333-3333-3333-3333-333333333333'::uuid as a1,
    '44444444-4444-4444-4444-444444444444'::uuid as a2,
    '55555555-5555-5555-5555-555555555555'::uuid as a3;
insert into auth.users (id, email) select a1, 'prof@example.com' from t_k;
insert into auth.users (id, email) select a2, 'other@example.com' from t_k;
insert into auth.users (id, email) select a3, 'prof-again@example.com' from t_k;
grant select on t_k to service_role;
set role service_role;

create or replace function pg_temp.check(ok boolean, what text) returns void language plpgsql as $$
begin
    if not coalesce(ok, false) then raise exception 'FAILED: %', what; end if;
    raise notice 'ok: %', what;
end $$;

-- 1. First check-in: account with its Play reference, no trial, no plan.
do $$
declare s jsonb; a uuid := (select a1 from t_k);
begin
    s := acekor_state(a, 'install-acekor-0000-0001', repeat('c', 64), '1.0.0');
    perform pg_temp.check(s->>'play_account_ref' = encode(sha256(convert_to('acekor-account|v1|' || a::text, 'UTF8')), 'hex'), 'play ref = sha256(acekor-account|v1|id)');
    perform pg_temp.check(s->'trial_started' = 'null'::jsonb, 'no trial yet');
    perform pg_temp.check(s->'paid_tier' = 'null'::jsonb, 'no plan yet');
end $$;

-- 2. The trial starts once and lasts 7 days.
do $$
declare s1 jsonb; s2 jsonb; a uuid := (select a1 from t_k);
begin
    perform acekor_start_trial(a);
    s1 := acekor_state(a, 'install-acekor-0000-0001');
    perform pg_temp.check((s1->>'trial_until')::timestamptz - (s1->>'trial_started')::timestamptz = interval '7 days', 'trial lasts 7 days');
    perform acekor_start_trial(a);
    s2 := acekor_state(a, 'install-acekor-0000-0001');
    perform pg_temp.check(s1->'trial_started' = s2->'trial_started', 'second start does not restart it');
end $$;

-- 3. PRO, then upgrade to MAX (linked token): MAX wins, PRO is marked replaced.
do $$
declare s jsonb; a uuid := (select a1 from t_k);
begin
    perform acekor_apply_subscription(a, 'tok-pro-0000000001', 'acekor_pro_yearly', 'SUBSCRIPTION_STATE_ACTIVE',
        now() + interval '300 days', true, true, true, null, 'GPA.1');
    s := acekor_state(a, 'install-acekor-0000-0001');
    perform pg_temp.check(s->>'paid_tier' = 'pro', 'PRO active');
    perform pg_temp.check((s->>'auto_renew')::boolean, 'auto-renew on');
    perform acekor_apply_subscription(a, 'tok-max-0000000001', 'acekor_max_yearly', 'SUBSCRIPTION_STATE_ACTIVE',
        now() + interval '300 days', true, true, true, 'tok-pro-0000000001', 'GPA.2');
    s := acekor_state(a, 'install-acekor-0000-0001');
    perform pg_temp.check(s->>'paid_tier' = 'max', 'MAX after upgrade');
    perform pg_temp.check((select revoked_at is not null from acekor_subscriptions where purchase_token = 'tok-pro-0000000001'), 'PRO replaced');
end $$;

-- 4. Another account cannot take the purchase; product IDs are checked.
do $$
declare b uuid := (select a2 from t_k); failed boolean := false;
begin
    perform acekor_state(b, 'install-acekor-0000-0002');
    begin
        perform acekor_apply_subscription(b, 'tok-max-0000000001', 'acekor_max_yearly', 'SUBSCRIPTION_STATE_ACTIVE',
            now() + interval '1 day', true, true, true, null, null);
    exception when insufficient_privilege then failed := true;
    end;
    perform pg_temp.check(failed, 'purchase owned by another account is refused');
    failed := false;
    begin
        perform acekor_apply_subscription(b, 'tok-other-00000001', 'acekanner_premium_yearly', 'SUBSCRIPTION_STATE_ACTIVE',
            now() + interval '1 day', true, true, true, null, null);
    exception when check_violation then failed := true;
    end;
    perform pg_temp.check(failed, 'foreign product refused');
end $$;

-- 5. Refund (revoke) of MAX: nothing active; latest ended plan reported.
do $$
declare s jsonb; a uuid := (select a1 from t_k);
begin
    perform pg_temp.check(acekor_revoke_purchase('tok-max-0000000001') = a, 'revoke returns the account');
    s := acekor_state(a, 'install-acekor-0000-0001');
    perform pg_temp.check(s->'paid_tier' = 'null'::jsonb, 'no plan after refund (both revoked)');
end $$;

-- 6. An expired subscription is still reported (for "PRO ended …") without auto-renew granting.
do $$
declare s jsonb; b uuid := (select a2 from t_k);
begin
    perform acekor_apply_subscription(b, 'tok-pro-expired-01', 'acekor_pro_yearly', 'SUBSCRIPTION_STATE_EXPIRED',
        now() - interval '2 days', false, true, true, null, null);
    s := acekor_state(b, 'install-acekor-0000-0002');
    perform pg_temp.check(s->>'paid_tier' = 'pro' and (s->>'paid_until')::timestamptz < now(), 'ended PRO reported with its date');
end $$;

-- 7. Deleting the account keeps a tombstone: the same Google identity gets
--    the original trial dates back, not a new trial.
do $$
declare a uuid := (select a1 from t_k); c uuid := (select a3 from t_k); s jsonb; t1 timestamptz; shared boolean;
begin
    t1 := (acekor_state(a, 'install-acekor-0000-0001')->>'trial_started')::timestamptz;
    shared := acekor_delete_account(a, repeat('c', 64));
    perform pg_temp.check(not shared, 'not used by ACEkanner');
    perform pg_temp.check(not exists (select 1 from acekor_accounts where id = a), 'account removed');
    s := acekor_state(c, 'install-acekor-0000-0003', repeat('c', 64));
    perform pg_temp.check((s->>'trial_started')::timestamptz = t1, 'trial carried over by identity hash');
    perform acekor_start_trial(c);
    perform pg_temp.check((acekor_state(c, 'install-acekor-0000-0003')->>'trial_started')::timestamptz = t1, 'no second trial');
end $$;

-- 8. A sign-in also used by ACEkanner is reported as shared.
do $$
declare b uuid := (select a2 from t_k);
begin
    perform license_state(b, 'install-phone-shared-01', false);
    perform pg_temp.check(acekor_delete_account(b, null), 'shared with ACEkanner');
end $$;

-- 9. Clients cannot call the functions or read the tables.
reset role;
set role authenticated;
do $$
declare failed boolean := false;
begin
    begin
        perform acekor_start_trial('33333333-3333-3333-3333-333333333333');
    exception when insufficient_privilege then failed := true;
    end;
    perform pg_temp.check(failed, 'authenticated cannot call acekor functions');
    failed := false;
    begin
        perform count(*) from acekor_accounts;
    exception when insufficient_privilege then failed := true;
    end;
    perform pg_temp.check(failed, 'authenticated cannot read acekor tables');
end $$;
reset role;
