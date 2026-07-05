# Servicios Docker

Todos los servicios corren como contenedores Docker gestionados vía
`playbooks/docker-services.yml`. Los templates están en `templates/docker-services/`.

## nginx + Cloudflare Tunnel

Proxy inverso principal e ingress de internet.

| Contenedor | Imagen | Puerto Local |
|---|---|---|
| `nginx-proxy` | `nginx:alpine` | 80, 443 |
| `cloudflared` | `cloudflare/cloudflared` | — (tunel outbound) |

### Dominios

| Dominio | Servicio destino |
|---|---|
| `portfolio.fsxsys.org` | portfolio :7373 |
| `pihole.fsxsys.org` | pihole :8053 (con SSL) |
| `tours-api.fsxsys.org` | ma-tours-api :8081 → /api/ |
| `reset-password.fsxsys.org` | ma-tours-frontend :3000 |

### Archivos de configuración

```
/opt/docker-apps/nginx/
├── docker-compose.yml
├── nginx.conf
├── .env                      ← Cloudflare token
├── conf.d/
│   ├── default.conf          ← catch-all 444
│   ├── ma-tours-api.conf
│   ├── pihole.conf           ← solo este usa SSL local
│   └── portfolio.conf
└── logs/
```

### Cloudflare Tunnel

El túnel se autentica con un token. Para generarlo:

1. Ir a [Cloudflare Zero Trust](https://one.dash.cloudflare.com) → Networks → Tunnels
2. Crear un tunnel → elegir Docker
3. Copiar el token (empieza con `eyJ...`)

**Nunca committees el token al repositorio.** Usá `--extra-vars` o `ansible-vault`.

### Agregar un nuevo dominio

1. Agregar DNS en Cloudflare (CNAME apuntando al tunnel)
2. Crear `conf.d/mi-dominio.conf.j2` en `templates/docker-services/nginx/`
3. Agregar dominio a `app_domains` en `host_vars/mirtha.yml`
4. Ejecutar `make docker-services-mirtha`

---

## Pi-hole

DNS sinkhole para bloquear publicidad y rastreadores a nivel de red.

| Contenedor | Imagen | Puerto Local |
|---|---|---|
| `pihole` | `pihole/pihole:2026.02.0` | 53 (DNS), 8053 (admin) |

### Configuración

- DNS upstream: Cloudflare (1.1.1.1, 1.0.0.1)
- Admin UI: `pihole.fsxsys.org` con SSL vía nginx
- Password seteado vía `pihole_webpassword` en `--extra-vars`

### Volúmenes

```
/opt/docker-apps/pihole/
├── docker-compose.yml
├── etc-pihole/          ← datos persistentes
└── etc-dnsmasq.d/       ← config adicional DNS
```

### Usar Pi-hole como DNS de red

Configurá tu router para que entregue `10.0.0.53` como DNS primario
(o el IP de mirtha si el router no permite puertos específicos).

---

## MA Tours

Aplicación de gestión de tours — API Spring Boot + Frontend React + PostgreSQL.

| Contenedor | Imagen | Puerto Local |
|---|---|---|
| `ma-tours-api-blue` | `ghcr.io/felix73sanchez/ma-tours-api` | 8081 |
| `ma-tours-frontend` | `ghcr.io/felix73sanchez/ma-tours-frontend` | 3000 |
| `ma-tours-db` | `postgres:16-alpine` | — (interno) |

### Endpoints

- API: `tours-api.fsxsys.org/api/`
- Health: `tours-api.fsxsys.org/health`
- Frontend: `reset-password.fsxsys.org`

### Variables de entorno

| Variable | Descripción |
|---|---|
| `MA_TOURS_DB_PASSWORD` | Password de PostgreSQL (generar con `openssl rand -base64 32`) |
| `SPRING_DATASOURCE_URL` | Auto-generado vía template |
| `ALLOWED_ORIGINS` | Auto-generado desde `app_domains.tours_frontend` |
| `VITE_API_URL` | Auto-generado desde `app_domains.tours_api` |

La DB PostgreSQL tiene un volumen nombrado (`postgres_data`) para persistencia.

---

## Portfolio FSX

Portfolio personal construido con Next.js.

| Contenedor | Imagen | Puerto Local |
|---|---|---|
| `portfolio-fsx` | Build local desde Dockerfile | 7373 |

### Variables de entorno

| Variable | Descripción |
|---|---|
| `JWT_SECRET` | Secreto JWT (generar con `openssl rand -base64 32`) |
| `INVITATION_CODE` | Código para registro de admin (generar con `uuidgen`) |
| `NEXT_PUBLIC_SITE_URL` | `https://portfolio.fsxsys.org` |

### Build

El contenedor se construye localmente desde el código fuente en
`/opt/docker-apps/portfolio-fsx-nxt/`. Si hay cambios en el código:

```bash
ssh fsxserver@10.0.0.73
cd /opt/docker-apps/portfolio-fsx-nxt
git pull
docker compose up -d --build
```

---

## qBittorrent

Cliente torrent con interfaz web.

| Contenedor | Imagen | Puerto Local |
|---|---|---|
| `qbittorrent` | `lscr.io/linuxserver/qbittorrent:latest` | 8073 (web), 6881 (torrent) |

### Puertos

| Puerto | Protocolo | Uso |
|---|---|---|
| 8073 | TCP | WebUI |
| 6881 | TCP | Torrent |
| 6881 | UDP | DHT |

### Volúmenes

| Host | Contenedor |
|---|---|
| `./config` | `/config` |
| `/mnt/storage/data/torrents` | `/downloads` |
