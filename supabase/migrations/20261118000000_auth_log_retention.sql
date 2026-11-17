-- ACEkanner — sign-in log retention (privacy policy: "sign-in logs are kept for 90 days").
--
-- Supabase Auth writes sign-in events (time, email, IP address) to
-- auth.audit_log_entries. A daily pg_cron job deletes entries older than 90 days.
-- cron.schedule() with an existing job name updates that job, so this file can be
-- applied again safely. Where pg_cron is not installed (local tests), it is skipped.

do $$
begin
    if not exists (select 1 from pg_available_extensions where name = 'pg_cron') then
        raise notice 'pg_cron not available: sign-in log retention job not scheduled';
        return;
    end if;
    create extension if not exists pg_cron with schema pg_catalog;
    perform cron.schedule(
        'acekanner-auth-log-retention',
        '17 3 * * *',   -- every day at 03:17 UTC (11:17 Philippine time)
        $job$delete from auth.audit_log_entries where created_at < now() - interval '90 days'$job$
    );
end
$$;
