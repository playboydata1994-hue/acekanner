-- Behaviour tests for the licensing functions. Every check raises on failure.
\set ON_ERROR_STOP on
set role service_role;

create temp table t_ids as select
    '11111111-1111-1111-1111-111111111111'::uuid as a1,
    '22222222-2222-2222-2222-222222222222'::uuid as a2;
reset role;
insert into auth.users (id, email) select a1, 'maria@example.com' from t_ids;
insert into auth.users (id, email) select a2, 'juan@example.com' from t_ids;
grant select on t_ids to service_role;
set role service_role;

create or replace function pg_temp.check(ok boolean, what text) returns void language plpgsql as $$
begin
    if not coalesce(ok, false) then raise exception 'FAILED: %', what; end if;
    raise notice 'ok: %', what;
end $$;

-- 1. First check-in creates the account; the first phone gets the lease.
do $$
declare s jsonb; a uuid := (select a1 from t_ids);
begin
    s := license_state(a, 'install-phone-aaaa-0001', false, repeat('a', 64), '0.6.0');
    perform pg_temp.check((s->>'free_limit')::int = 100, 'free limit is 100');
    perform pg_temp.check((s->>'free_used')::int = 0, 'nothing used yet');
    perform pg_temp.check((s->>'lease')::int = 100, 'first phone holds the whole lease');
    perform pg_temp.check(s->>'play_account_ref' = encode(sha256(convert_to('acekanner-account|v1|' || a::text, 'UTF8')), 'hex'), 'play account ref = sha256 of the account id');
    perform pg_temp.check(s->'premium_until' = 'null'::jsonb, 'no premium');
end $$;

-- 2. Charges are idempotent per key hash.
do $$
declare n int; s jsonb; a uuid := (select a1 from t_ids);
begin
    n := license_record_charges(a, 'install-phone-aaaa-0001',
        jsonb_build_array(
            jsonb_build_object('k', repeat('1', 64), 't', 'free', 'at', now()),
            jsonb_build_object('k', repeat('2', 64), 't', 'free', 'at', now()),
            jsonb_build_object('k', repeat('1', 64), 't', 'free', 'at', now())));
    perform pg_temp.check(n = 2, 'duplicate key in one upload counted once');
    n := license_record_charges(a, 'install-phone-aaaa-0001', jsonb_build_array(jsonb_build_object('k', repeat('2', 64), 't', 'free', 'at', now())));
    perform pg_temp.check(n = 0, 're-uploading a charged paper is free');
    s := license_state(a, 'install-phone-aaaa-0001', false);
    perform pg_temp.check((s->>'free_used')::int = 2 and (s->>'lease')::int = 98, 'used 2, lease 98');
end $$;

-- 3. A premium claim without a subscription counts as free.
do $$
declare s jsonb; a uuid := (select a1 from t_ids);
begin
    perform license_record_charges(a, 'install-phone-aaaa-0001', jsonb_build_array(jsonb_build_object('k', repeat('3', 64), 't', 'premium', 'at', now())));
    s := license_state(a, 'install-phone-aaaa-0001', false);
    perform pg_temp.check((s->>'free_used')::int = 3, 'forged premium charge is counted as free');
end $$;

-- 4. Lease moves to a new phone only when it signs in (claim).
do $$
declare s jsonb; a uuid := (select a1 from t_ids);
begin
    s := license_state(a, 'install-phone-bbbb-0002', false);
    perform pg_temp.check((s->>'lease')::int = 0 and not (s->>'lease_holder')::boolean, 'second phone has no lease until it claims');
    s := license_state(a, 'install-phone-bbbb-0002', true);
    perform pg_temp.check((s->>'lease')::int = 97, 'claim moves the lease');
    s := license_state(a, 'install-phone-aaaa-0001', false);
    perform pg_temp.check((s->>'lease')::int = 0, 'old phone lost the lease');
    -- The old phone can still upload scans it made offline; they are counted.
    perform license_record_charges(a, 'install-phone-aaaa-0001', jsonb_build_array(jsonb_build_object('k', repeat('4', 64), 't', 'free', 'at', now())));
    s := license_state(a, 'install-phone-bbbb-0002', false);
    perform pg_temp.check((s->>'free_used')::int = 4 and (s->>'lease')::int = 96, 'offline scans of the old phone count');
end $$;

-- 5. Bad input is refused.
do $$
declare a uuid := (select a1 from t_ids); failed boolean;
begin
    failed := false;
    begin perform license_state(a, 'bad id!', false); exception when others then failed := true; end;
    perform pg_temp.check(failed, 'invalid install id refused');
    failed := false;
    begin perform license_record_charges(a, 'install-phone-aaaa-0001', jsonb_build_array(jsonb_build_object('k', 'xyz'))); exception when others then failed := true; end;
    perform pg_temp.check(failed, 'invalid charge key refused');
    failed := false;
    begin perform license_record_charges(a, 'install-phone-aaaa-0001', (select jsonb_agg(jsonb_build_object('k', repeat('5', 64))) from generate_series(1, 1001))); exception when others then failed := true; end;
    perform pg_temp.check(failed, 'more than 1000 charges per upload refused');
end $$;

-- 6. Subscriptions: grant, ownership, cancel-until-expiry, expiry, revoke.
do $$
declare r jsonb; s jsonb; a uuid := (select a1 from t_ids); b uuid := (select a2 from t_ids); failed boolean;
begin
    r := license_apply_subscription(a, 'token-aaaaaaaaaaaa', 'acekanner_premium_yearly', 'SUBSCRIPTION_STATE_ACTIVE',
        now() + interval '365 days', true, true, true, null, 'GPA.1');
    perform pg_temp.check((r->>'premium_until')::timestamptz > now() + interval '364 days', 'active subscription grants premium');
    s := license_state(a, 'install-phone-bbbb-0002', false);
    perform pg_temp.check(s->>'premium_until' is not null, 'state reports premium');

    -- Premium-tier charges are now accepted and do not use the free allowance.
    perform license_record_charges(a, 'install-phone-bbbb-0002', jsonb_build_array(jsonb_build_object('k', repeat('6', 64), 't', 'premium', 'at', now())));
    s := license_state(a, 'install-phone-bbbb-0002', false);
    perform pg_temp.check((s->>'free_used')::int = 4, 'premium scan does not use the free allowance');

    perform license_state(b, 'install-phone-cccc-0003', true, repeat('b', 64));
    failed := false;
    begin
        perform license_apply_subscription(b, 'token-aaaaaaaaaaaa', 'acekanner_premium_yearly', 'SUBSCRIPTION_STATE_ACTIVE',
            now() + interval '365 days', true, true, true, null, null);
    exception when sqlstate '42501' then failed := true; end;
    perform pg_temp.check(failed, 'another account cannot claim the same purchase token');

    r := license_apply_subscription(a, 'token-aaaaaaaaaaaa', 'acekanner_premium_yearly', 'SUBSCRIPTION_STATE_CANCELED',
        now() + interval '100 days', false, true, true, null, null);
    perform pg_temp.check((r->>'premium_until')::timestamptz > now() + interval '99 days', 'cancelled keeps premium until expiry');

    r := license_apply_subscription(a, 'token-aaaaaaaaaaaa', 'acekanner_premium_yearly', 'SUBSCRIPTION_STATE_ON_HOLD',
        now() + interval '100 days', false, true, true, null, null);
    perform pg_temp.check(r->'premium_until' = 'null'::jsonb, 'account hold removes premium');

    r := license_apply_subscription(a, 'token-aaaaaaaaaaaa', 'acekanner_premium_yearly', 'SUBSCRIPTION_STATE_ACTIVE',
        now() + interval '365 days', true, true, true, null, null);
    perform pg_temp.check(license_revoke_purchase('token-aaaaaaaaaaaa') = a, 'revoke finds the account');
    s := license_state(a, 'install-phone-bbbb-0002', false);
    perform pg_temp.check(s->'premium_until' = 'null'::jsonb, 'refund/revocation removes premium');
    perform pg_temp.check(license_revoke_purchase('token-unknown-xxxx') is null, 'unknown token is ignored');

    perform pg_temp.check(license_find_purchase_account('token-aaaaaaaaaaaa', null) = a, 'find by token');
    perform pg_temp.check(license_find_purchase_account('token-new-zzzzzzz',
        encode(sha256(convert_to('acekanner-account|v1|' || b::text, 'UTF8')), 'hex')) = b, 'find by play account ref');
end $$;

-- 7. Deleting the account keeps used scans for the same Google identity.
do $$
declare s jsonb; a uuid := (select a1 from t_ids);
begin
    perform license_delete_account(a, repeat('a', 64));
    perform pg_temp.check(not exists (select 1 from accounts where id = a), 'account deleted');
    perform pg_temp.check(not exists (select 1 from scan_charges where account_id = a), 'charges deleted');
    perform pg_temp.check(not exists (select 1 from play_subscriptions where account_id = a), 'subscriptions deleted');
    s := license_state(a, 'install-phone-dddd-0004', true, repeat('a', 64));
    perform pg_temp.check((s->>'free_used')::int = 4 and (s->>'lease')::int = 96, 're-created account keeps the 4 used free scans');
end $$;

reset role;

-- 8. Clients (anon / authenticated) can neither read tables nor call functions.
set role authenticated;
do $$
declare failed boolean;
begin
    failed := false;
    begin perform 1 from public.accounts limit 1; exception when insufficient_privilege then failed := true; end;
    perform pg_temp.check(failed, 'authenticated cannot read accounts');
    failed := false;
    begin perform public.license_state('11111111-1111-1111-1111-111111111111', 'install-phone-aaaa-0001', true); exception when insufficient_privilege then failed := true; end;
    perform pg_temp.check(failed, 'authenticated cannot call license_state');
end $$;
reset role;
set role anon;
do $$
declare failed boolean := false;
begin
    begin perform 1 from public.scan_charges limit 1; exception when insufficient_privilege then failed := true; end;
    perform pg_temp.check(failed, 'anon cannot read scan_charges');
end $$;
reset role;
\echo 'ALL LICENSING SQL TESTS PASSED'
