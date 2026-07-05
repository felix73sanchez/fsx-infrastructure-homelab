# Red y Firewall

## Topología de Red

```
                  Internet
                     │
              Cloudflare Tunnel
                     │
               ┌─────┴──────┐
               │   mirtha    │
               │  10.0.0.73  │
               └─────┬──────┘
                     │ (LAN)
               ┌─────┴──────┐
               │   Router    │
               │  10.0.0.1   │
               └────────────┘
```

## Interfaces

| Interfaz | IP | Propósito |
|---|---|---|
| `eth0` | `10.0.0.73/24` | Red local |
| `docker0` | `172.17.0.1/16` | Bridge por defecto de Docker |
| `br-*` | `172.20.x.x/24` | Redes de Docker Compose |

## Redes Docker

| Nombre | Subnet | Uso |
|---|---|---|
| `fsxnet` | `172.20.0.0/16` | Red general de contenedores |
| `nginx_proxy_net` | — | nginx + cloudflared |
| `pihole_pihole_network` | — | Pi-hole |
| `ma-tours-api_default` | — | MA Tours API + frontend + DB |
| `portfolio-fsx-nxt_default` | — | Portfolio |

## Puertos Abiertos (UFW)

### TCP

| Puerto | Servicio | Fuente |
|---|---|---|
| 22 | SSH | Any |
| 53 | Pi-hole DNS | Any (red local) |
| 80 | nginx HTTP | Any (vía Cloudflare) |
| 139 | Samba NetBIOS | Red local |
| 445 | Samba SMB | Red local |

### UDP

| Puerto | Servicio | Fuente |
|---|---|---|
| 53 | Pi-hole DNS | Any (red local) |
| 67 | Pi-hole DHCP | Red local |
| 123 | Pi-hole NTP | Any |

### Puertos Docker Expuestos

| Puerto | Servicio | Contenedor |
|---|---|---|
| 8053 | Pi-hole admin | pihole |
| 8073 | qBittorrent WebUI | qbittorrent |
| 8081 | MA Tours API | ma-tours-api-blue |
| 3000 | MA Tours frontend | ma-tours-frontend |
| 7373 | Portfolio | portfolio-fsx |
| 6881 | Torrent | qbittorrent |

### Puertos que NO están abiertos en UFW

Aunque Docker expone estos puertos en `0.0.0.0`, UFW **no los tiene
permitidos explícitamente**. Docker bypasea UFW porque escribe directo
en iptables (iptables rules de Docker están antes que las de UFW).

Para bloquearlos realmente, necesitás:

```bash
# Opción 1: Configurar DOCKER-USER
iptables -I DOCKER-USER -i eth0 ! -s 10.0.0.0/24 -p tcp --dport 8073 -j DROP

# Opción 2: Solo escuchar en localhost (mejor)
# Editar docker-compose.yml y cambiar "8073:8073" por "127.0.0.1:8073:8073"
```

## Configuración Docker Daemon

```json
{
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "3" },
  "storage-driver": "overlay2",
  "live-restore": true,
  "userland-proxy": false,
  "metrics-addr": "127.0.0.1:9323"
}
```

- `live-restore`: los contenedores siguen corriendo si dockerd se reinicia
- `userland-proxy: false`: usa iptables en vez del proxy userland (menos latencia)
- `metrics-addr`: métricas de Docker Daemon en localhost

## Cambiar Reglas de Firewall

```yaml
# group_vars/all.yml
firewall_allowed_tcp_ports:
  - 22
  - 53
  - 80
  # - 443    # <-- descomentar si usás SSL local
```

```bash
ansible-playbook playbooks/site.yml --tags firewall --limit mirtha
```
