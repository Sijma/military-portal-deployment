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
