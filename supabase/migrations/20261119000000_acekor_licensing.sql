-- ACEKOR Calculator licensing (second app on the same Supabase project).
--
-- Holds only what the 7-day trial and the PRO/MAX subscriptions need: the
-- instructor's account (Supabase Auth user from Google sign-in), random
-- install IDs, the trial dates and Google Play purchases. NO student names,
-- numbers or scores: those never leave the phone.
--
-- Separate tables from ACEkanner's (accounts, play_subscriptions, …): the two
-- apps share sign-in but nothing else. Clients never touch these tables: RLS
-- on with no policies, privileges revoked; only the acekor-license Edge
-- Function (service role) calls the functions below.

-- ---------------------------------------------------------------- tables

create table public.acekor_accounts (
    id uuid primary key references auth.users (id) on delete cascade,
    -- SHA-256("acekor-account|v1|" || id): Play's obfuscatedAccountId.
    play_account_ref text not null unique,
    -- Set once by start-trial; never reset (also survives account deletion
    -- through acekor_tombstones).
    trial_started_at timestamptz,
    trial_ends_at timestamptz,
    -- Cache of the best current (or latest) subscription.
    paid_tier text check (paid_tier is null or paid_tier in ('pro', 'max')),
    paid_until timestamptz,
    auto_renew boolean,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table public.acekor_devices (
    account_id uuid not null references public.acekor_accounts (id) on delete cascade,
    install_id text not null check (install_id ~ '^[A-Za-z0-9-]{16,64}$'),
    app_version text check (app_version is null or length(app_version) <= 40),
    first_seen timestamptz not null default now(),
    last_seen timestamptz not null default now(),
    primary key (account_id, install_id)
);

create table public.acekor_subscriptions (
    purchase_token text primary key check (length(purchase_token) between 10 and 1000),
    account_id uuid not null references public.acekor_accounts (id) on delete cascade,
    product_id text not null check (product_id in ('acekor_pro_yearly', 'acekor_max_yearly')),
    state text not null,
    expiry_time timestamptz,
    auto_renewing boolean,
    acknowledged boolean not null default false,
    test_purchase boolean not null default false,
    linked_purchase_token text,
    latest_order_id text,
    -- Refunded, revoked, or replaced by an upgrade (PRO → MAX).
    revoked_at timestamptz,
    checked_at timestamptz not null default now(),
    created_at timestamptz not null default now()
);

create index acekor_subscriptions_account on public.acekor_subscriptions (account_id);

-- Kept after an account is deleted: a one-way hash of the Google identity
-- and when its trial started, so deleting and re-creating the account never
-- gives a second free trial. Disclosed in the privacy policy.
create table public.acekor_tombstones (
    identity_hash text primary key check (identity_hash ~ '^[0-9a-f]{64}$'),
    trial_started_at timestamptz,
    deleted_at timestamptz not null default now()
);

-- ---------------------------------------------------------------- security

alter table public.acekor_accounts enable row level security;
alter table public.acekor_devices enable row level security;
alter table public.acekor_subscriptions enable row level security;
alter table public.acekor_tombstones enable row level security;

revoke all on public.acekor_accounts, public.acekor_devices, public.acekor_subscriptions,
    public.acekor_tombstones from anon, authenticated;

-- ---------------------------------------------------------------- functions

create function public.acekor_ensure_account(p_account uuid, p_identity_hash text)
returns void
language plpgsql
set search_path = public, pg_temp
as $$
declare
    v_trial timestamptz;
begin
    if exists (select 1 from acekor_accounts where id = p_account) then
        return;
    end if;
    if p_identity_hash is not null then
        select trial_started_at into v_trial from acekor_tombstones where identity_hash = p_identity_hash;
    end if;
    insert into acekor_accounts (id, play_account_ref, trial_started_at, trial_ends_at)
    values (
        p_account,
        encode(sha256(convert_to('acekor-account|v1|' || p_account::text, 'UTF8')), 'hex'),
        v_trial,
        v_trial + interval '7 days'
    )
    on conflict (id) do nothing;
end;
$$;

-- Recomputes the subscription cache: the highest tier that is active now
-- (MAX over PRO), else the most recently ended one (for "PRO ended …").
create function public.acekor_recompute(p_account uuid)
returns void
language plpgsql
set search_path = public, pg_temp
as $$
declare
    s record;
begin
    select
        case when product_id = 'acekor_max_yearly' then 'max' else 'pro' end as tier,
        expiry_time,
        auto_renewing
    into s
    from acekor_subscriptions
    where account_id = p_account
      and revoked_at is null
      and expiry_time is not null
      and state in ('SUBSCRIPTION_STATE_ACTIVE', 'SUBSCRIPTION_STATE_IN_GRACE_PERIOD',
                    'SUBSCRIPTION_STATE_CANCELED', 'SUBSCRIPTION_STATE_EXPIRED',
                    'SUBSCRIPTION_STATE_ON_HOLD', 'SUBSCRIPTION_STATE_PAUSED')
    order by
        (expiry_time > now() and state in ('SUBSCRIPTION_STATE_ACTIVE', 'SUBSCRIPTION_STATE_IN_GRACE_PERIOD',
                                           'SUBSCRIPTION_STATE_CANCELED')) desc,
        (product_id = 'acekor_max_yearly') desc,
        expiry_time desc
    limit 1;

    update acekor_accounts
    set paid_tier = s.tier,
        paid_until = s.expiry_time,
        -- Only states that still grant access count as "renews".
        auto_renew = coalesce(s.auto_renewing, false),
        updated_at = now()
    where id = p_account;
end;
$$;

create function public.acekor_state(
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

-- Starts the 7-day trial once per account (idempotent: a second call
-- returns the existing dates, even long after the trial ended).
create function public.acekor_start_trial(p_account uuid)
returns void
language plpgsql
set search_path = public, pg_temp
as $$
begin
    update acekor_accounts
    set trial_started_at = now(), trial_ends_at = now() + interval '7 days', updated_at = now()
    where id = p_account and trial_started_at is null;
end;
$$;

create function public.acekor_apply_subscription(
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
returns void
language plpgsql
set search_path = public, pg_temp
as $$
declare
    v_owner uuid;
begin
    select account_id into v_owner from acekor_subscriptions where purchase_token = p_token;
    if v_owner is not null and v_owner <> p_account then
        raise exception 'purchase_owned_by_other_account' using errcode = '42501';
    end if;
    insert into acekor_subscriptions (
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
        acknowledged = acekor_subscriptions.acknowledged or excluded.acknowledged,
        test_purchase = excluded.test_purchase,
        linked_purchase_token = excluded.linked_purchase_token,
        latest_order_id = coalesce(excluded.latest_order_id, acekor_subscriptions.latest_order_id),
        checked_at = now();
    -- An upgrade (PRO → MAX) or a re-subscription replaces the linked purchase.
    if p_linked_token is not null then
        update acekor_subscriptions
        set revoked_at = coalesce(revoked_at, now()), checked_at = now()
        where purchase_token = p_linked_token and account_id = p_account;
    end if;
    perform acekor_recompute(p_account);
end;
$$;

create function public.acekor_revoke_purchase(p_token text)
returns uuid
language plpgsql
set search_path = public, pg_temp
as $$
declare
    v_account uuid;
begin
    update acekor_subscriptions
    set revoked_at = coalesce(revoked_at, now()), checked_at = now()
    where purchase_token = p_token
    returning account_id into v_account;
    if v_account is not null then
        perform acekor_recompute(v_account);
    end if;
    return v_account;
end;
$$;

create function public.acekor_find_purchase_account(p_token text)
returns uuid
language sql stable
set search_path = public, pg_temp
as $$
    select account_id from acekor_subscriptions where purchase_token = p_token
$$;

create function public.acekor_subscriptions_to_refresh(p_account uuid)
returns table (purchase_token text, product_id text)
language sql stable
set search_path = public, pg_temp
as $$
    select s.purchase_token, s.product_id
    from acekor_subscriptions s
    where s.account_id = p_account
      and s.revoked_at is null
      and s.expiry_time > now() - interval '35 days'
      and (s.checked_at < now() - interval '6 hours' or s.expiry_time < now() + interval '1 day')
    order by s.expiry_time desc nulls last
    limit 3
$$;

-- Deletes the ACEKOR account. Returns true when the same sign-in is still
-- used by ACEkanner (then the auth user must be kept).
create function public.acekor_delete_account(p_account uuid, p_identity_hash text)
returns boolean
language plpgsql
set search_path = public, pg_temp
as $$
declare
    v_trial timestamptz;
begin
    select trial_started_at into v_trial from acekor_accounts where id = p_account;
    if p_identity_hash is not null then
        insert into acekor_tombstones (identity_hash, trial_started_at)
        values (p_identity_hash, v_trial)
        on conflict (identity_hash) do update
            set trial_started_at = coalesce(acekor_tombstones.trial_started_at, excluded.trial_started_at),
                deleted_at = now();
    end if;
    delete from acekor_accounts where id = p_account;
    return to_regclass('public.accounts') is not null
        and exists (select 1 from public.accounts where id = p_account);
end;
$$;

revoke execute on function
    public.acekor_ensure_account(uuid, text),
    public.acekor_recompute(uuid),
    public.acekor_state(uuid, text, text, text),
    public.acekor_start_trial(uuid),
    public.acekor_apply_subscription(uuid, text, text, text, timestamptz, boolean, boolean, boolean, text, text),
    public.acekor_revoke_purchase(text),
    public.acekor_find_purchase_account(text),
    public.acekor_subscriptions_to_refresh(uuid),
    public.acekor_delete_account(uuid, text)
from public, anon, authenticated;

grant execute on function
    public.acekor_ensure_account(uuid, text),
    public.acekor_recompute(uuid),
    public.acekor_state(uuid, text, text, text),
    public.acekor_start_trial(uuid),
    public.acekor_apply_subscription(uuid, text, text, text, timestamptz, boolean, boolean, boolean, text, text),
    public.acekor_revoke_purchase(text),
    public.acekor_find_purchase_account(text),
    public.acekor_subscriptions_to_refresh(uuid),
    public.acekor_delete_account(uuid, text)
to service_role;
