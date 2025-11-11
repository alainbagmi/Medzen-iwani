-- EHRbase Database Initialization Script
-- This script initializes the ehrbase database with required schemas, extensions, and users

\echo '==================================='
\echo 'EHRbase Database Initialization'
\echo '==================================='
\echo ''

-- Connect to postgres database first
\c postgres

-- Create ehrbase database
\echo 'Creating ehrbase database...'
CREATE DATABASE ehrbase ENCODING 'UTF-8' LOCALE 'C' TEMPLATE template0;

\echo 'Database created successfully'
\echo ''

-- Connect to ehrbase database
\c ehrbase

-- Create schemas
\echo 'Creating schemas...'
CREATE SCHEMA IF NOT EXISTS ehr AUTHORIZATION ehrbase_admin;
CREATE SCHEMA IF NOT EXISTS ext AUTHORIZATION ehrbase_admin;
\echo 'Schemas created: ehr, ext'
\echo ''

-- Create extensions
\echo 'Creating extensions...'
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" SCHEMA ext;
\echo 'Extension created: uuid-ossp'
\echo ''

-- Set database defaults
\echo 'Setting database defaults...'
ALTER DATABASE ehrbase SET search_path TO ext;
ALTER DATABASE ehrbase SET intervalstyle = 'iso_8601';
\echo 'Database defaults configured'
\echo ''

-- Create restricted user (password will be passed as variable)
\echo 'Creating restricted user...'
CREATE ROLE ehrbase_restricted WITH LOGIN PASSWORD :'db_user_password';
\echo 'User created: ehrbase_restricted'
\echo ''

-- Grant permissions to restricted user
\echo 'Configuring permissions...'
GRANT CONNECT ON DATABASE ehrbase TO ehrbase_restricted;
GRANT USAGE ON SCHEMA ehr TO ehrbase_restricted;
GRANT USAGE ON SCHEMA ext TO ehrbase_restricted;

-- Grant table permissions (for existing tables)
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ehr TO ehrbase_restricted;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ext TO ehrbase_restricted;

-- Grant sequence permissions
GRANT USAGE ON ALL SEQUENCES IN SCHEMA ehr TO ehrbase_restricted;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA ext TO ehrbase_restricted;

-- Set default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA ehr GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO ehrbase_restricted;
ALTER DEFAULT PRIVILEGES IN SCHEMA ext GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO ehrbase_restricted;

-- Set default privileges for future sequences
ALTER DEFAULT PRIVILEGES IN SCHEMA ehr GRANT USAGE ON SEQUENCES TO ehrbase_restricted;
ALTER DEFAULT PRIVILEGES IN SCHEMA ext GRANT USAGE ON SEQUENCES TO ehrbase_restricted;

\echo 'Permissions configured'
\echo ''

-- Verify setup
\echo 'Verifying setup...'
\echo 'Databases:'
\l ehrbase

\echo ''
\echo 'Schemas in ehrbase:'
\dn

\echo ''
\echo 'Extensions:'
\dx

\echo ''
\echo '==================================='
\echo 'Database initialization complete!'
\echo '==================================='
\echo ''
\echo 'Database: ehrbase'
\echo 'Schemas: ehr, ext'
\echo 'Users: ehrbase_admin (owner), ehrbase_restricted (limited)'
\echo 'Extensions: uuid-ossp'
\echo ''
