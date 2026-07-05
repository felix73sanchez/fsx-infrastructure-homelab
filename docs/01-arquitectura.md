# Arquitectura del Homelab

## Visión General

Servidor doméstico que funciona como centro de servicios personales y
experimentos de infraestructura. Gestionado 100% con Ansible como único
punto de control.

```
┌────────────────────────────────────────────────────────┐
│                   Internet                              │
│                         │                               │
│               Cloudflare Tunnel                         │
│                         │                               │
│              ┌──────────┴──────────┐                    │
│              │   nginx-proxy       │                    │
│              │   (127.0.0.1:80)    │                    │
│              └──────────┬──────────┘                    │
│                         │                               │
│         ┌───────────────┼───────────────┐               │
│         │               │               │               │
│    portfolio:7373  pihole:8053  ma-tours:8081/3000      │
│                                                         │
│              ┌────────────────────┐                     │
│              │   qbittorrent      │                     │
│              │   :8073 / :6881    │                     │
│              └────────────────────┘                     │
│                                                         │
│              ┌────────────────────┐                     │
│              │   Samba :139/445   │                     │
│              │   /srv/samba/      │                     │
│              └────────────────────┘                     │
└────────────────────────────────────────────────────────┘
```

## Hardware

| Recurso | Valor |
|---|---|
| Placa | Raspberry Pi / SBC equivalente |
| CPU | 2 núcleos |
| RAM | 2 GB |
| Disco interno | 26 GB LVM (mmcblk0, 29 GB total) |
| Disco externo | NTFS vía USB (UUID=8C681669681651F6) |
| SO | Ubuntu 24.04 LTS (Noble) |

## Stack de Software

```
┌─────────────────────────────────────────────┐
│               Cloudflare Tunnel              │
├─────────────────────────────────────────────┤
│              nginx (reverse proxy)           │
├─────────────────────────────────────────────┤
│  Portfolio  │  Pi-hole  │  MA Tours  │  qBT  │
├─────────────────────────────────────────────┤
│                 Docker / Compose             │
├──────────────────┬──────────────────────────┤
│     Samba        │    Docker Bridge Network  │
├──────────────────┴──────────────────────────┤
│               Ubuntu 24.04 LTS               │
│           UFW · fail2ban · SSH pubkey        │
└─────────────────────────────────────────────┘
```

## Decisiones Técnicas

### Por qué Ansible
- Un solo punto de control para todo el homelab
- Idempotente — se puede ejecutar mil veces sin romper nada
- Sin agente — solo SSH, no instala nada en los nodos

### Por qué Cloudflare Tunnel
- No requiere abrir puertos WAN
- SSL automático en el edge de Cloudflare
- Protección DDoS incluida
- Funciona con IP dinámica

### Por qué nginx en vez de Nginx Proxy Manager
- Control total sobre la configuración
- Sin interfaz gráfica innecesaria (todo es código)
- Más ligero en recursos

### Por qué Docker Compose en vez de Kubernetes
- 2 GB de RAM no alcanzan para K8s
- Los servicios son pocos y no escalan horizontalmente
- Compose es declarativo, fácil de entender y mantener

## Flujo de una Request

```
Usuario → portfolio.fsxsys.org
  ↓
Cloudflare (SSL, caché, DDoS)
  ↓
Cloudflare Tunnel (tunel persistente outbound)
  ↓
cloudflared container → nginx-proxy container
  ↓
nginx conf.d/portfolio.conf → proxy_pass :7373
  ↓
portfolio-fsx container
```
