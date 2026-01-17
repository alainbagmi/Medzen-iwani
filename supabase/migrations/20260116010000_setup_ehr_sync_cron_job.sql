-- Enable pg_cron extension for scheduled jobs (runs within Supabase, no external tool needed)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Enable pgsql_http extension to make HTTP requests from the database
CREATE EXTENSION IF NOT EXISTS http;

-- Create a cron job to process EHR sync queue every 5 minutes
-- This runs entirely within Supabase without external schedulers
SELECT cron.schedule(
  'process-ehr-sync-queue-every-5-minutes',
  '*/5 * * * *',  -- Every 5 minutes (cron syntax)
  $$
  SELECT
    http_post(
      'https://noaeltglphdlkbflipit.supabase.co/functions/v1/process-ehr-sync-queue',
      '{}',
      'application/json'
    );
  $$
);

-- Verify the cron job was created
-- Run this query after migration to verify:
-- SELECT * FROM cron.job WHERE jobname = 'process-ehr-sync-queue-every-5-minutes';
