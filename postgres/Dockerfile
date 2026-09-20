FROM postgres:18-alpine3.24
COPY schema.sql /docker-entrypoint-initdb.d/schema.sql.inc
COPY init.sql /docker-entrypoint-initdb.d/10-init.sql
