# Military Portal Deployment

Deployment repository for the Military Portal devops project. It contains:
- Backend and Frontend as Git Submoludes
- Docker Compose setup
- Ansible Playbooks


## Repository layout
- `backend/` - Rust API services
- `frontend/` - Svelte-based SPA
- `apisix/` - gateway routes and authentication plugin
- `keycloak/` - Keycloak dockerfile and realm export
- `postgres/` - database dockerfile, schema and init script.
- `ansible/` - configurations for native remote and docker-compose deployments

## Local development
(requires docker/docker-compose)

```shell
git submodule update --init --recursive
cp .env.example .env
chmod 600 .env
```
Fill `.env` with the missing values, then simply launch the full stack by running:

```shell
./localrun-compose.sh
```

The default, local endpoints should be:

- App: http://localhost:9080
- Keycloak master realm admin: http://localhost:9080/admin/
- Direct Keycloak access for development: http://localhost:8080
- MailHog through the gateway: http://localhost:9080/mail/
- Direct MailHog access for development: http://localhost:8025/mail/

Stop the stack with:
```shell
docker compose --env-file .env \
  -f docker-compose.yml \
  -f docker-compose.override.yml \
  down
```

## Ansible configuration

The inventory is located in `ansible/inventory/azure/`:

- shared values: `group_vars/all/main.yml`
- encrypted secrets: `group_vars/all/vault.yml`
- host-specific values: `host_vars/`
- SSH targets: `hosts.yml` (in the current repo, `.ssh/config` aliases are used in hosts)

Ansible reads the vault password from the gitignored `ansible/.ansible_vault_pass` file.
You can create your own vault by copying `vault.yml.example` into `vault.yml` and filling the respective fields.

Install the required collections before either deployment:

```shell
cd ansible
ansible-galaxy collection install -r requirements.yml
```

## Remote Docker Compose

The Compose deployment uses one Ubuntu VM. It retrieves the VM's public IP with
ipify and publishes the portal on TCP port 9080.

Open TCP 9080 port on the Compose VM and run:
```shell
ansible-playbook playbooks/install-docker.yml
ansible-playbook playbooks/deploy-docker.yml
```

The playbook passes inventory values directly to Compose, the local `.env` file is only used for local development.

## Native VM deployment

The native deployment uses two VMs:
- Frontend: nginx, APISIX, Keycloak, MailHog
- Backend: Postgres + 3 backend instances

The frontend VM is expected to be running Debian 12, as APISIX's official deb package repository only supports Debian 12.

Set `BROWSER_BASE_URL` to the frontend VM's HTTPS DNS name in `group_vars/all/main.yml` and run:
```shell
ansible-playbook playbooks/deploy-vm.yml
```
### Required port configuration:

- SSH access (TCP 22) for ansible tasks
- Internet to frontend: TCP 80 and 443
- Frontend to backend (internal vnet ip): TCP 5432 and 8081-8083
- Backend to frontend (internal vnet ip): TCP 1025

The Keycloak administration console is available at `<BROWSER_BASE_URL>/admin/`. Sign in with the Keycloak administrator
as defined in `group_vars/all/vault.yml`.

The MailHog interface at `<BROWSER_BASE_URL>/mail/` does not require authentication and is there only for demonstrative
purposes.

Useful partial-deployment tags include `backend`, `postgres`, `services`, `frontend`, `keycloak`, `mail`, `application`,
`tls`, and `gateway`, in order to allow partial updates.
