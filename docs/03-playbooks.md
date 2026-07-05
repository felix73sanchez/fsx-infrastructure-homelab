# Playbooks

## site.yml — Despliegue Completo de Infraestructura

Aplica todos los roles de sistema en orden:

```
base → security → samba → docker → monitoring → motd
```

```bash
# Despliegue completo a todos los hosts
ansible-playbook playbooks/site.yml

# Solo un host
ansible-playbook playbooks/site.yml --limit mirtha

# Solo roles específicos
ansible-playbook playbooks/site.yml --tags docker

# Saltar etiquetas específicas
ansible-playbook playbooks/site.yml --skip-tags upgrade
```

### Tags disponibles

| Tag | Roles |
|---|---|
| `base`, `system` | base |
| `security`, `hardening` | security |
| `samba`, `filesharing` | samba |
| `docker`, `containers` | docker |
| `monitoring`, `observability` | monitoring |
| `motd`, `branding` | motd |
| `users` | base, security |
| `firewall` | security |
| `ntp` | base |
| `packages` | base |
| `upgrade` | base |

## docker-services.yml — Servicios Docker

Despliega los servicios Docker basados en compose:

- nginx + cloudflared
- Pi-hole
- MA Tours (api + frontend + db)
- Portfolio FSX
- qBittorrent

```bash
# Desplegar todos los servicios
ansible-playbook playbooks/docker-services.yml

# Servicios específicos por tag
ansible-playbook playbooks/docker-services.yml --tags nginx,pihole

# Solo en mirtha
ansible-playbook playbooks/docker-services.yml --limit mirtha
```

### Tags disponibles

| Tag | Servicio |
|---|---|
| `nginx` | nginx + cloudflared |
| `pihole` | Pi-hole |
| `ma-tours` | MA Tours |
| `portfolio` | Portfolio |
| `qbittorrent` | qBittorrent |
| `start` | Arrancar todos los compose |

### Variables requeridas

```bash
# Pasar con --extra-vars (ver 06-secretos.md para alternativas)
ansible-playbook playbooks/docker-services.yml \
  --extra-vars 'cloudflare_tunnel_token=eyJ...' \
  --extra-vars 'pihole_webpassword=admin123' \
  --extra-vars 'ma_tours_db_password=pass-segura' \
  --extra-vars 'portfolio_jwt_secret=openssl-rand-64' \
  --extra-vars 'portfolio_invitation_code=uuid-v4'
```

## docker-apps.yml — Apps Docker Legacy

Despliega Portainer y Watchtower como contenedores individuales.

```bash
ansible-playbook playbooks/docker-apps.yml
```

Estos servicios están **deshabilitados por defecto** en `group_vars/all.yml`.
Para activarlos:

```yaml
deploy_portainer: true
deploy_watchtower: true
```

## update.yml — Actualizaciones del Sistema

Actualiza todos los paquetes en todos los hosts.

```bash
# Actualizar todo
ansible-playbook playbooks/update.yml

# Solo actualizar (sin check)
ansible-playbook playbooks/update.yml --tags upgrade

# Solo check (sin actualizar)
ansible-playbook playbooks/update.yml --tags check
```
