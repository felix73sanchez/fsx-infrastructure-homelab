# FSXSYSTEM Infraestructura como Código

Gestión de infraestructura basada en Ansible para el laboratorio FSXSYSTEM.

## 🏗️ Arquitectura

- **Servidor Actual**: `mirtha` (10.0.0.73) — Ubuntu 24.04, 2 núcleos, 2GB RAM, 26GB LVM
- **Preparado para el Futuro**: Diseñado para escalar con múltiples clústeres y nodos (Swarm, Kubernetes, DBs, Storage)

## 📁 Estructura

```
fsx-infra/
├── ansible.cfg                    # Configuración de Ansible
├── deploy.sh                      # Script interactivo de despliegue
├── Makefile                       # Atajos de comandos frecuentes
├── requirements.yml               # Dependencias de colecciones Ansible
├── inventory/
│   ├── hosts.yml                  # Inventario principal (hosts, grupos)
│   └── host_vars/
│       └── mirtha.yml             # Variables específicas de mirtha
├── group_vars/
│   ├── all.yml                    # Variables globales (todas las configs)
│   └── homelab.yml                # Variables específicas del homelab
├── roles/
│   ├── base/                      # Configuración base del sistema
│   ├── security/                  # Hardening (SSH, UFW, fail2ban)
│   ├── samba/                     # Servidor Samba (compartir archivos)
│   ├── docker/                    # Docker Engine + Compose
│   ├── monitoring/                # Monitoreo (glances, node_exporter)
│   └── motd/                      # Banner personalizado FSXSYSTEM
├── playbooks/
│   ├── site.yml                   # Despliegue completo de infraestructura
│   ├── update.yml                 # Actualizaciones del sistema
│   ├── docker-apps.yml            # Apps Docker legacy (Portainer, Watchtower)
│   └── docker-services.yml        # Servicios Docker (nginx, pihole, apps)
├── templates/
│   └── docker-services/           # Plantillas Jinja2 para Docker Compose
│       ├── nginx/                 # nginx + Cloudflare Tunnel
│       ├── pihole/                # Pi-hole DNS
│       ├── ma-tours/              # MA Tours (api + frontend + postgres)
│       ├── portfolio-fsx-nxt/     # Portfolio personal (Next.js)
│       └── qbittorrent/           # Cliente torrent
└── .atl/                          # Archivos de seguimiento (Atl)
```

## 🚀 Inicio Rápido

### Prerrequisitos
```bash
ansible-galaxy install -r requirements.yml
```

### Despliegue Completo
```bash
# 1. Infraestructura base (roles: base → security → samba → docker → motd)
make deploy

# 2. Servicios Docker (nginx, pihole, apps)
make docker-services
```

### Usando deploy.sh
```bash
./deploy.sh
# Seleccionar: 1) Full deployment, 2) Host específico, 3) Updates, etc.
```

### Atajos vía Makefile
```bash
make ping              # Probar conectividad a todos los hosts
make deploy            # Desplegar infraestructura completa
make deploy-mirtha     # Desplegar solo en mirtha
make update            # Actualizar todos los sistemas
make docker-apps       # Portainer + Watchtower
make docker-services   # nginx + pihole + apps compose
make install-deps      # Instalar dependencias Ansible
make facts-mirtha      # Ver facts del host mirtha
```

## 🔄 Multi-Distro

El stack soporta **Debian/Ubuntu** y **RedHat/Rocky/Alma/Fedora/CentOS**.

Para agregar un nodo RedHat, editá `inventory/host_vars/<host>.yml`:
```yaml
ansible_os_family: RedHat
firewall_engine: firewalld
base_packages:
  - vim
  - curl
  - wget
  - git
  - htop
  # + epel-release, etc.
```

**Qué cambia por distro:**

| Componente | Debian | RedHat |
|---|---|---|
| Paquetes | `package` (apt) | `package` (dnf/yum) |
| Docker | get.docker.com script | get.docker.com script |
| Firewall | UFW | firewalld |
| NTP | systemd-timesyncd | chronyd |
| Auto-updates | unattended-upgrades | dnf-automatic |
| Samba | smbd/nmbd | smb/nmb |

## 🔑 Gestión de Secretos

Varios servicios requieren secretos que **no están en el repositorio**. Pásalos con `--extra-vars`:

```bash
ansible-playbook playbooks/docker-services.yml \
  --extra-vars 'cloudflare_tunnel_token=eyJ...' \
  --extra-vars 'pihole_webpassword=tu-clave' \
  --extra-vars 'ma_tours_db_password=pass-segura' \
  --extra-vars 'portfolio_jwt_secret=openssl-rand-64' \
  --extra-vars 'portfolio_invitation_code=uuid-v4'
```

> **Recomendación**: Usá `ansible-vault` para guardarlos de forma persistente:
> ```bash
> ansible-vault create group_vars/vault.yml
> # Agregar: cloudflare_tunnel_token: "eyJ..."
> # Luego: ansible-playbook ... --ask-vault-pass
> ```

## 📋 Roles del Sistema

### `base` — Sistema base
- Hostname, timezone (`America/Santo_Domingo`), locale
- Paquetes base (vim, curl, git, htop, etc.)
- Upgrades automáticos (`unattended-upgrades`)
- Usuario `fsxserver` en grupos `sudo` + `docker`
- Usuarios extra: `fsx_smb` (Samba), `devmon` (auto-mount)
- Montura de disco externo (`/mnt/storage`, NTFS)
- Límites del sistema (`nofile=65536`, `nproc=65536`)
- sysctl tuning (`swappiness=10`, `somaxconn=65535`)

### `security` — Hardening
- SSH: solo pubkey, sin root, sin password, alive interval 300s
- **UFW**: puertos TCP 22, 53, 80, 139, 445 + puertos UDP 53, 67, 123
- **fail2ban**: 5 intentos, 1h de baneo
- Servicios deshabilitados: bluetooth, cups

### `samba` — Compartición de archivos
- Instala `samba` y crea grupo/user `fsx_smb`
- Share `Compartido` en `/srv/samba/compartido`
- Protocolo mínimo SMB2
- Configurable vía `samba_shares` en `group_vars/all.yml`

### `docker` — Contenedores
- Docker CE + `docker-buildx-plugin` + `docker-compose-plugin`
- Red `fsxnet` (`172.20.0.0/16`)
- Log rotation, prune automático 3 AM
- `ctop` como monitor de contenedores
- Daemon config: overlay2, live-restore, metrics en `127.0.0.1:9323`

### `monitoring` — Monitoreo (opcional)
- glances, iotop, nethogs
- node_exporter para Prometheus (deshabilitado por defecto en mirtha)

### `motd` — Banner
- Banner FSXSYSTEM con hostname, uptime, RAM, disco, IP
- Info de Docker si está instalado

## 🐳 Servicios Docker

### nginx + Cloudflare Tunnel
| Contenedor | Imagen | Puertos |
|---|---|---|
| `nginx-proxy` | `nginx:alpine` | 80, 443 |
| `cloudflared` | `cloudflare/cloudflared` | — (tunnel outbound) |

- Reverse proxy para todas las apps del dominio
- Cloudflare Tunnel como ingress (sin necesidad de abrir puertos WAN)
- Dominios soportados: `portfolio.fsxsys.org`, `pihole.fsxsys.org`, `tours-api.fsxsys.org`, `reset-password.fsxsys.org`
- SSL vía Let's Encrypt (certbot manual, certs montados desde `/etc/letsencrypt`)

### Pi-hole
| Contenedor | Imagen | Puertos |
|---|---|---|
| `pihole` | `pihole/pihole:2026.02.0` | 53 (DNS), 8053 (admin) |

- DNS sinkhole para toda la red local
- Admin UI en `pihole.fsxsys.org` con SSL vía nginx
- DNS upstream: Cloudflare (1.1.1.1, 1.0.0.1)

### MA Tours
| Contenedor | Imagen | Puertos |
|---|---|---|
| `ma-tours-api-blue` | `ghcr.io/felix73sanchez/ma-tours-api` | 8081 |
| `ma-tours-frontend` | `ghcr.io/felix73sanchez/ma-tours-frontend` | 3000 |
| `ma-tours-db` | `postgres:16-alpine` | — (interno) |

- API REST en `tours-api.fsxsys.org/api/`
- Frontend en `reset-password.fsxsys.org`
- Base de datos PostgreSQL con healthcheck

### Portfolio FSX
| Contenedor | Imagen | Puertos |
|---|---|---|
| `portfolio-fsx` | Build local (Next.js) | 7373 |

- Aplicación personal construida desde Dockerfile
- Admin con JWT + invitation code
- Admin UI en `portfolio.fsxsys.org`

### qBittorrent
| Contenedor | Imagen | Puertos |
|---|---|---|
| `qbittorrent` | `lscr.io/linuxserver/qbittorrent` | 8073 (web), 6881 (torrent) |

- WebUI en puerto 8073
- Descargas en `/mnt/storage/data/torrents`
- Timezone: `America/Santo_Domingo`

## 🔐 Firewall (UFW)

Puertos abiertos actualmente:

| Puerto | Protocolo | Servicio |
|---|---|---|
| 22 | TCP | SSH |
| 53 | TCP+UDP | DNS (Pi-hole) |
| 67 | UDP | DHCP (Pi-hole) |
| 80 | TCP | HTTP (nginx) |
| 123 | UDP | NTP (Pi-hole) |
| 139 | TCP | Samba NetBIOS |
| 445 | TCP | Samba SMB |

> Configurables en `group_vars/all.yml` → `firewall_allowed_tcp_ports` y `firewall_allowed_udp_ports`

## 📊 Monitoreo

```bash
# Estado del sistema
ssh fsxserver@10.0.0.73 htop

# Contenedores
ssh fsxserver@10.0.0.73 ctop

# Logs de servicios
ssh fsxserver@10.0.0.73 "docker logs nginx-proxy --tail 50"
```

## 🛠️ Mantenimiento

```bash
# Actualizar todo
make update

# Actualizar solo paquetes (sin reboot)
ansible-playbook playbooks/update.yml --tags upgrade

# Reiniciar servicios Docker
ansible-playbook playbooks/site.yml --tags docker --skip-tags install

# Ver facts del sistema
ansible mirtha -m setup | less
```

## 🔄 Agregar Nuevos Nodos

1. Añadir host a `inventory/hosts.yml` en el grupo correspondiente
2. Crear `inventory/host_vars/<hostname>.yml` con sus variables
3. Ejecutar: `ansible-playbook playbooks/site.yml --limit <hostname>`
4. Si aplica: `ansible-playbook playbooks/docker-services.yml --limit <hostname>`

## 📝 Notas

- Playbooks **idempotentes** — seguros para ejecutar múltiples veces
- Tareas etiquetadas para despliegue selectivo (`--tags`)
- Manejadores para reinicio de servicios solo cuando es necesario
- Secretos manejados vía `--extra-vars` o `ansible-vault`

## 📜 Licencia

GNU General Public License v3.0 — Ver [LICENSE](LICENSE) para más detalles.

Autor: Felix Sanchez — FSX
Software libre construido para aportar valor a la comunidad.

## 📚 Documentación

Toda la documentación detallada está en [`docs/`](docs/):

| Documento | Qué cubre |
|---|---|
| [Arquitectura](docs/01-arquitectura.md) | Topología, stack, decisiones técnicas |
| [Servicios Docker](docs/02-servicios-docker.md) | nginx, pihole, ma-tours, portfolio, qbittorrent |
| [Playbooks](docs/03-playbooks.md) | site, docker-services, update, docker-apps |
| [Roles](docs/04-roles.md) | base, security, samba, docker, monitoring, motd |
| [Multi-Distro](docs/05-multidistro.md) | Debian + RedHat en un solo playbook |
| [Secretos](docs/06-secretos.md) | --extra-vars, ansible-vault, mejores prácticas |
| [Operaciones](docs/07-operaciones.md) | Día a día: updates, logs, monitoreo |
| [Red y Firewall](docs/08-red-firewall.md) | Puertos, topología, reglas UFW |
| [Backup](docs/09-backup.md) | Qué respaldar y cómo |
| [Troubleshooting](docs/10-troubleshooting.md) | Problemas comunes y soluciones |
| [Agregar Nodos](docs/11-agregar-nodos.md) | Checklist para añadir un nuevo servidor |

Para empezar: [docs/README.md](docs/README.md)
