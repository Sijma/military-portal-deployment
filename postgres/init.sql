\getenv app_database POSTGRES_DB
\getenv portal_user PORTAL_DB_USER
\getenv portal_password PORTAL_DB_PASSWORD
\getenv keycloak_database KEYCLOAK_DB_NAME
\getenv keycloak_user KEYCLOAK_DB_USER
\getenv keycloak_password KEYCLOAK_DB_PASSWORD

CREATE TABLE IF NOT EXISTS applications (
    applicant_amka TEXT PRIMARY KEY,
    applicant_id TEXT NOT NULL,
    applicant_email TEXT NOT NULL,
    application_type TEXT NOT NULL CHECK (application_type IN ('deferment', 'service')),
    deferment_reason TEXT,
    service_division TEXT CHECK (service_division IS NULL OR service_division IN ('land', 'navy', 'airforce')),
    status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'approved', 'rejected')),
    reviewed_by TEXT,
    review_note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT application_type_shape CHECK (
        (application_type = 'deferment' AND deferment_reason IS NOT NULL AND service_division IS NULL)
        OR
        (application_type = 'service' AND service_division IS NOT NULL AND deferment_reason IS NULL)
    )
);

SELECT format('CREATE ROLE %I LOGIN PASSWORD %L', :'portal_user', :'portal_password')
WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = :'portal_user')
\gexec

GRANT CONNECT ON DATABASE :"app_database" TO :"portal_user";
GRANT USAGE ON SCHEMA public TO :"portal_user";
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO :"portal_user";
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO :"portal_user";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO :"portal_user";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO :"portal_user";

SELECT format('CREATE ROLE %I LOGIN PASSWORD %L', :'keycloak_user', :'keycloak_password')
WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = :'keycloak_user')
\gexec

SELECT format('CREATE DATABASE %I OWNER %I', :'keycloak_database', :'keycloak_user')
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = :'keycloak_database')
\gexec
