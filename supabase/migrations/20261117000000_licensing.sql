-- ACEkanner licensing schema (Phase 6).
--
-- Holds only what licensing needs: the instructor's account (Supabase Auth user),
-- install IDs of their phones, one hashed row per charged scan, and Google Play
-- subscription purchases. NO student names, numbers, answers or scores.
--
-- Clients never read or write these tables directly: Row Level Security is on
-- with no policies, and table privileges are revoked from anon/authenticated.
-- Only the Edge Functions (service role) call the functions below.

-- ---------------------------------------------------------------- tables

create table public.accounts (
    id uuid primary key references auth.users (id) on delete cascade,
    -- Lifetime free allowance (100). Never reset by reinstalling or deleting.
    free_limit integer not null default 100 check (free_limit >= 0),
    -- Free scans carried over from a deleted account with the same Google
    -- identity (see account_tombstones), so deleting and re-creating an
    -- account never restores used scans.
    free_used_carried integer not null default 0 check (free_used_carried >= 0),
    -- The install that currently holds the free-scan lease (one phone at a time).
    lease_install_id text,
    -- SHA-256("acekanner-account|v1|" || id): sent to Play as obfuscatedAccountId.
    play_account_ref text not null unique,
    -- Latest expiry of a subscription that currently grants Premium (cache).
    premium_until timestamptz,
    -- First moment this account ever had Premium (for validating premium charges).
    premium_since timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table public.devices (
    account_id uuid not null references public.accounts (id) on delete cascade,
    install_id text not null check (install_id ~ '^[A-Za-z0-9-]{16,64}$'),
    app_version text check (app_version is null or length(app_version) <= 40),
    first_seen timestamptz not null default now(),
    last_seen timestamptz not null default now(),
    primary key (account_id, install_id)
);

-- One row per charged scan. key_hash = SHA-256 of the app's submission key
-- (exam + student UUIDs, themselves hashed): it identifies a paper only within
-- this account and reveals nothing about the student.
create table public.scan_charges (
    account_id uuid not null references public.accounts (id) on delete cascade,
    key_hash text not null check (key_hash ~ '^[0-9a-f]{64}$'),
    tier text not null check (tier in ('free', 'premium')),
    install_id text not null,
    consumed_at timestamptz not null,
    received_at timestamptz not null default now(),
    primary key (account_id, key_hash)
);

create table public.play_subscriptions (
    purchase_token text primary key check (length(purchase_token) between 10 and 1000),
    account_id uuid not null references public.accounts (id) on delete cascade,
    product_id text not null,
    -- subscriptionsv2 state, e.g. SUBSCRIPTION_STATE_ACTIVE
    state text not null,
    expiry_time timestamptz,
    auto_renewing boolean,
    acknowledged boolean not null default false,
    test_purchase boolean not null default false,
    linked_purchase_token text,
    latest_order_id text,
    revoked_at timestamptz,
    checked_at timestamptz not null default now(),
    created_at timestamptz not null default now()
);

create index play_subscriptions_account on public.play_subscriptions (account_id);

-- Kept after an account is deleted: a one-way hash of the Google identity and
-- the number of free scans it had used. Prevents "delete account, get 100 new
-- free scans". Disclosed in the privacy policy.
create table public.account_tombstones (
    identity_hash text primary key check (identity_hash ~ '^[0-9a-f]{64}$'),
    free_used integer not null check (free_used >= 0),
    deleted_at timestamptz not null default now()
);

-- ---------------------------------------------------------------- security

alter table public.accounts enable row level security;
alter table public.devices enable row level security;
alter table public.scan_charges enable row level security;
alter table public.play_subscriptions enable row level security;
alter table public.account_tombstones enable row level security;

revoke all on public.accounts, public.devices, public.scan_charges,
    public.play_subscriptions, public.account_tombstones from anon, authenticated;

-- ---------------------------------------------------------------- helpers

-- States in which a subscription still grants Premium until its expiry time.
-- CANCELED = auto-renew turned off; access continues until expiry.
create function public.license_state_grants(p_state text)
returns boolean
language sql immutable
as $$
    select p_state in (
        'SUBSCRIPTION_STATE_ACTIVE',
        'SUBSCRIPTION_STATE_IN_GRACE_PERIOD',
        'SUBSCRIPTION_STATE_CANCELED'
    )
$$;

-- Creates the account row on first use; carries over a tombstone's usage.
create function public.license_ensure_account(p_account uuid, p_identity_hash text)
returns void
language plpgsql
set search_path = public, pg_temp
as $$
declare
    v_carried integer := 0;
begin
    if exists (select 1 from accounts where id = p_account) then
        return;
    end if;
    if p_identity_hash is not null then
        select free_used into v_carried from account_tombstones where identity_hash = p_identity_hash;
    end if;
    insert into accounts (id, free_used_carried, play_account_ref)
    values (
        p_account,
        coalesce(v_carried, 0),
        encode(sha256(convert_to('acekanner-account|v1|' || p_account::text, 'UTF8')), 'hex')
    )
    on conflict (id) do nothing;
end;
$$;

-- Recomputes the Premium cache from the account's subscriptions.
create function public.license_recompute_premium(p_account uuid)
returns timestamptz
language plpgsql
set search_path = public, pg_temp
as $$
declare
    v_until timestamptz;
begin
    select max(expiry_time) into v_until
    from play_subscriptions
    where account_id = p_account
      and revoked_at is null
      and license_state_grants(state)
      and expiry_time is not null;

    update accounts
    set premium_until = v_until,
        premium_since = case
            when v_until is not null then coalesce(premium_since, now())
            else premium_since
        end,
        updated_at = now()
    where id = p_account;
    return v_until;
end;
$$;

-- ---------------------------------------------------------------- API (service role only)

-- Check-in: registers the phone, optionally moves the free-scan lease to it,
-- and returns the numbers the entitlement token is built from.
create function public.license_state(
    p_account uuid,
    p_install text,
    p_claim boolean,
    p_identity_hash text default null,
    p_app_version text default null
)
returns jsonb
language plpgsql
set search_path = public, pg_temp
as $$
declare
    a accounts%rowtype;
    v_free_used integer;
begin
    if p_install !~ '^[A-Za-z0-9-]{16,64}$' then
        raise exception 'invalid_install_id' using errcode = '22023';
    end if;
    perform license_ensure_account(p_account, p_identity_hash);

    insert into devices (account_id, install_id, app_version)
    values (p_account, p_install, left(p_app_version, 40))
    on conflict (account_id, install_id)
    do update set last_seen = now(), app_version = coalesce(excluded.app_version, devices.app_version);

    update accounts
    set lease_install_id = p_install, updated_at = now()
    where id = p_account and (p_claim or lease_install_id is null);

    select * into a from accounts where id = p_account;
    select count(*) into v_free_used from scan_charges where account_id = p_account and tier = 'free';
    v_free_used := v_free_used + a.free_used_carried;

    return jsonb_build_object(
        'free_limit', a.free_limit,
        'free_used', v_free_used,
        'lease', case when a.lease_install_id = p_install
                      then greatest(a.free_limit - v_free_used, 0) else 0 end,
        'lease_holder', a.lease_install_id = p_install,
        'premium_until', a.premium_until,
        'play_account_ref', a.play_account_ref
    );
end;
$$;

-- Records charged scans uploaded by a phone. Idempotent per key_hash.
-- A 'premium' charge is accepted only when the account actually had Premium
-- around that time; otherwise it counts against the free allowance.
-- p_charges: [{"k": "<64 hex>", "t": "free"|"premium", "at": "<ISO time>"}, ...]
create function public.license_record_charges(p_account uuid, p_install text, p_charges jsonb)
returns integer
language plpgsql
set search_path = public, pg_temp
as $$
declare
    a accounts%rowtype;
    c jsonb;
    v_at timestamptz;
    v_tier text;
    v_inserted integer := 0;
    v_count integer;
begin
    if jsonb_typeof(p_charges) <> 'array' or jsonb_array_length(p_charges) > 1000 then
        raise exception 'invalid_charges' using errcode = '22023';
    end if;
    select * into a from accounts where id = p_account;
    if not found then
        raise exception 'unknown_account' using errcode = '22023';
    end if;

    for c in select * from jsonb_array_elements(p_charges) loop
        if c->>'k' is null or (c->>'k') !~ '^[0-9a-f]{64}$' then
            raise exception 'invalid_charge_key' using errcode = '22023';
        end if;
        begin
            v_at := (c->>'at')::timestamptz;
        exception when others then
            v_at := now();
        end;
        -- A phone cannot report scans from the future.
        v_at := least(coalesce(v_at, now()), now());
        v_tier := case
            when c->>'t' = 'premium'
                 and a.premium_since is not null
                 and exists (
                     select 1 from play_subscriptions s
                     where s.account_id = p_account
                       and s.expiry_time is not null
                       and v_at between s.created_at - interval '1 day'
                                    and coalesce(s.revoked_at, s.expiry_time) + interval '1 day'
                 )
            then 'premium'
            else 'free'
        end;
        insert into scan_charges (account_id, key_hash, tier, install_id, consumed_at)
        values (p_account, c->>'k', v_tier, p_install, v_at)
        on conflict (account_id, key_hash) do nothing;
        get diagnostics v_count = row_count;
        v_inserted := v_inserted + v_count;
    end loop;
    return v_inserted;
end;
$$;

-- Stores a Play subscription verified with Google and refreshes Premium.
-- Raises 'purchase_owned_by_other_account' if the token is already bound to a
-- different ACEkanner account (stops replaying someone else's purchase).
create function public.license_apply_subscription(
    p_account uuid,
    p_token text,
    p_product text,
    p_state text,
    p_expiry timestamptz,
    p_auto_renewing boolean,
    p_acknowledged boolean,
    p_test boolean,
    p_linked_token text,
    p_order_id text
)
returns jsonb
language plpgsql
set search_path = public, pg_temp
as $$
declare
    v_owner uuid;
    v_until timestamptz;
begin
    select account_id into v_owner from play_subscriptions where purchase_token = p_token;
    if v_owner is not null and v_owner <> p_account then
        raise exception 'purchase_owned_by_other_account' using errcode = '42501';
    end if;
    insert into play_subscriptions (
        purchase_token, account_id, product_id, state, expiry_time, auto_renewing,
        acknowledged, test_purchase, linked_purchase_token, latest_order_id, checked_at
    ) values (
        p_token, p_account, p_product, p_state, p_expiry, p_auto_renewing,
        coalesce(p_acknowledged, false), coalesce(p_test, false), p_linked_token, p_order_id, now()
    )
    on conflict (purchase_token) do update set
        state = excluded.state,
        expiry_time = excluded.expiry_time,
        auto_renewing = excluded.auto_renewing,
        acknowledged = play_subscriptions.acknowledged or excluded.acknowledged,
        test_purchase = excluded.test_purchase,
        linked_purchase_token = excluded.linked_purchase_token,
        latest_order_id = coalesce(excluded.latest_order_id, play_subscriptions.latest_order_id),
        checked_at = now();
    v_until := license_recompute_premium(p_account);
    return jsonb_build_object('premium_until', v_until);
end;
$$;

-- Refund or revocation (voided purchase): the token stops granting Premium.
-- Returns the affected account, or null if the token is unknown.
create function public.license_revoke_purchase(p_token text)
returns uuid
language plpgsql
set search_path = public, pg_temp
as $$
declare
    v_account uuid;
begin
    update play_subscriptions
    set revoked_at = coalesce(revoked_at, now()), checked_at = now()
    where purchase_token = p_token
    returning account_id into v_account;
    if v_account is not null then
        perform license_recompute_premium(v_account);
    end if;
    return v_account;
end;
$$;

-- Account that a purchase belongs to: by stored token, else by the
-- obfuscatedAccountId Play reports.
create function public.license_find_purchase_account(p_token text, p_play_account_ref text)
returns uuid
language sql stable
set search_path = public, pg_temp
as $$
    select coalesce(
        (select account_id from play_subscriptions where purchase_token = p_token),
        (select id from accounts where p_play_account_ref is not null and play_account_ref = p_play_account_ref)
    )
$$;

-- Subscriptions worth re-checking with Google at check-in: those that grant or
-- recently granted Premium and were not checked in the last 6 hours, or that
-- expire within a day.
create function public.license_subscriptions_to_refresh(p_account uuid)
returns table (purchase_token text, product_id text)
language sql stable
set search_path = public, pg_temp
as $$
    select s.purchase_token, s.product_id
    from play_subscriptions s
    where s.account_id = p_account
      and s.revoked_at is null
      and s.expiry_time > now() - interval '35 days'
      and (s.checked_at < now() - interval '6 hours' or s.expiry_time < now() + interval '1 day')
    order by s.expiry_time desc nulls last
    limit 3
$$;

-- Deletes the account's server records (Play requires in-app account deletion).
-- Leaves a tombstone with the hashed identity and the free scans used.
create function public.license_delete_account(p_account uuid, p_identity_hash text)
returns void
language plpgsql
set search_path = public, pg_temp
as $$
declare
    v_used integer;
begin
    select coalesce((select count(*) from scan_charges where account_id = p_account and tier = 'free'), 0)
           + coalesce((select free_used_carried from accounts where id = p_account), 0)
    into v_used;
    if p_identity_hash is not null then
        insert into account_tombstones (identity_hash, free_used)
        values (p_identity_hash, v_used)
        on conflict (identity_hash) do update
            set free_used = greatest(account_tombstones.free_used, excluded.free_used),
                deleted_at = now();
    end if;
    delete from accounts where id = p_account;
end;
$$;

-- Only the service role (Edge Functions) may call the API.
revoke execute on function
    public.license_state_grants(text),
    public.license_ensure_account(uuid, text),
    public.license_recompute_premium(uuid),
    public.license_state(uuid, text, boolean, text, text),
    public.license_record_charges(uuid, text, jsonb),
    public.license_apply_subscription(uuid, text, text, text, timestamptz, boolean, boolean, boolean, text, text),
    public.license_revoke_purchase(text),
    public.license_find_purchase_account(text, text),
    public.license_subscriptions_to_refresh(uuid),
    public.license_delete_account(uuid, text)
from public, anon, authenticated;

grant execute on function
    public.license_state_grants(text),
    public.license_ensure_account(uuid, text),
    public.license_recompute_premium(uuid),
    public.license_state(uuid, text, boolean, text, text),
    public.license_record_charges(uuid, text, jsonb),
    public.license_apply_subscription(uuid, text, text, text, timestamptz, boolean, boolean, boolean, text, text),
    public.license_revoke_purchase(text),
    public.license_find_purchase_account(text, text),
    public.license_subscriptions_to_refresh(uuid),
    public.license_delete_account(uuid, text)
to service_role;
