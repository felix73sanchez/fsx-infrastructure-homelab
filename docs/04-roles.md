# Roles de Ansible

## base — Sistema Base

**Ubicación**: `roles/base/`

Responsable de la configuración fundamental del servidor.

### Qué hace

| Tarea | Tags |
|---|---|
| Setear hostname | `hostname` |
| Configurar `/etc/hosts` | `hostname` |
| Timezone (`America/Santo_Domingo`) | `timezone` |
| Actualizar caché de paquetes | `packages` |
| Upgrade del sistema completo | `packages`, `upgrade` |
| Instalar `base_packages` | `packages` |
| Instalar `additional_packages` (por host) | `packages` |
| Auto-updates (unattended-upgrades o dnf-automatic) | `auto-update` |
| NTP (timesyncd o chronyd) | `ntp` |
| Crear grupos admin (`sudo`, `docker`) | `users` |
| Agregar `admin_user` a grupos | `users` |
| Bash aliases para `admin_user` | `shell` |
| Crear `extra_users` (fsx_smb, devmon) | `users` |
| Montar `storage_mounts` | `storage` |
| Límites del sistema (nofile, nproc) | `tuning` |
| sysctl (swappiness, somaxconn, tcp_backlog) | `tuning` |

### Ejecutar solo este rol

```bash
ansible-playbook playbooks/site.yml --tags base
```

### Dependencias

| Colección | Uso |
|---|---|
| `community.general` | `timezone` module |
| `ansible.posix` | `mount` module |

---

## security — Hardening

**Ubicación**: `roles/security/`

Endurece el servidor contra accesos no autorizados.

### Qué hace

| Tarea | Tags |
|---|---|
| SSH: deshabilitar root login | `ssh` |
| SSH: deshabilitar password auth | `ssh` |
| SSH: habilitar pubkey auth | `ssh` |
| SSH: deshabilitar empty passwords | `ssh` |
| SSH: client alive interval 300s | `ssh` |
| Firewall engine (UFW o firewalld) | `firewall` |
| fail2ban: instalar, configurar, iniciar | `fail2ban` |
| Deshabilitar servicios innecesarios (bluetooth, cups) | `services` |
| Permisos seguros en `/etc/ssh/sshd_config`, `/etc/shadow` | `permissions` |

### Firewall Engine

Controlado por `firewall_engine` en `group_vars/all.yml`:

| Valor | Engine | Distro típica |
|---|---|---|
| `ufw` (default) | UFW | Debian, Ubuntu |
| `firewalld` | firewalld | RHEL, Rocky, Fedora |
| `none` | — | Sin firewall gestionado |

Puertos abiertos por defecto:

| Puerto | Protocolo | Servicio |
|---|---|---|
| 22 | TCP | SSH |
| 53 | TCP+UDP | Pi-hole DNS |
| 67 | UDP | Pi-hole DHCP |
| 80 | TCP | nginx HTTP |
| 123 | UDP | Pi-hole NTP |
| 139 | TCP | Samba NetBIOS |
| 445 | TCP | Samba SMB |

Configurables via `firewall_allowed_tcp_ports` y `firewall_allowed_udp_ports`.

### Ejecutar solo este rol

```bash
ansible-playbook playbooks/site.yml --tags security
```

---

## samba — Compartición de Archivos

**Ubicación**: `roles/samba/`

### Qué hace

| Tarea | Tags |
|---|---|
| Instalar Samba | `install` |
| Crear grupo `fsx_smb` | `config` |
| Crear usuario `fsx_smb` (uid 1003) | `users` |
| Crear directorios de los shares | `directories` |
| Configurar `smb.conf` | `config` |
| Iniciar servicios (smbd/nmbd o smb/nmb) | `service` |

### Shares configurados

| Nombre | Ruta | Propósito |
|---|---|---|
| `Compartido` | `/srv/samba/compartido` | Carpeta para iPhone / red local |

### Agregar un share

Editá `samba_shares` en `group_vars/all.yml`:

```yaml
samba_shares:
  - name: Compartido
    comment: "Carpeta para iPhone"
    path: /srv/samba/compartido
    browsable: yes
    writable: yes
    guest_ok: no
    read_only: no
    create_mask: "0755"
    directory_mask: "0755"
  - name: NuevoShare     # <-- agregar acá
    comment: "Nueva carpeta"
    path: /srv/samba/nuevo
    ...
```

### Ejecutar solo este rol

```bash
ansible-playbook playbooks/site.yml --tags samba
```

---

## docker — Contenedores

**Ubicación**: `roles/docker/`

### Qué hace

| Tarea | Tags |
|---|---|
| Eliminar versiones viejas de Docker | `install` |
| Instalar Docker vía script oficial `get.docker.com` | `install` |
| Asegurar servicio docker activo | `service` |
| Agregar usuarios al grupo docker | `users` |
| Configurar daemon.json (overlay2, live-restore) | `config` |
| Crear directorios `/opt/docker`, `/opt/docker-apps` | `directories` |
| Instalar Docker Compose standalone (opcional) | `compose` |
| Log rotation para contenedores | `logging` |
| Instalar ctop (monitor de contenedores) | `tools` |
| Crear red `fsxnet` (172.20.0.0/16) | `network` |
| Cron job: docker system prune a las 3 AM | `maintenance` |

### Docker Compose standalone

Si `docker_compose_version` está definido, instala `docker-compose`
(binario standalone) en `/usr/local/bin/docker-compose`.

Actualmente configurado en `group_vars/all.yml`:

```yaml
docker_compose_version: "2.27.0"
```

### El script get.docker.com

La instalación usa el script oficial de Docker:

```bash
curl -fsSL https://get.docker.com | sh
```

Esto funciona en las siguientes distribuciones:

- Ubuntu (20.04+)
- Debian (11+)
- RHEL / Rocky / Alma (8+)
- Fedora (36+)
- CentOS (7+)

### Configuración del Daemon

Templated desde `roles/docker/templates/daemon.json.j2`:

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "live-restore": true,
  "userland-proxy": false,
  "metrics-addr": "127.0.0.1:9323"
}
```

### Ejecutar solo este rol

```bash
ansible-playbook playbooks/site.yml --tags docker
```

---

## monitoring — Monitoreo

**Ubicación**: `roles/monitoring/`

### Qué hace

| Tarea | Tags |
|---|---|
| Instalar glances, iotop, nethogs | `install` |
| Descargar node_exporter | `prometheus` |
| Crear systemd service para node_exporter | `prometheus` |

**Deshabilitado por defecto** en mirtha (`monitoring_enabled: false`).

Para activar:

```yaml
# group_vars/all.yml o host_vars/<host>.yml
monitoring_enabled: true
```

---

## motd — Message of the Day

**Ubicación**: `roles/motd/`

### Qué hace

| Tarea | Tags |
|---|---|
| Deshabilitar MOTD scripts por defecto de Ubuntu | `cleanup` |
| Banner FSXSYSTEM (00-fsxsystem-banner) | `banner` |
| Info del sistema (10-system-info) | `info` |
| Info de Docker (20-docker-info) | `docker` |
| Limpiar `/etc/motd` | `cleanup` |

### Ejemplo de salida al hacer SSH

```
███████╗███████╗██╗  ██╗███████╗██╗   ██╗███████╗████████╗███████╗███╗   ███╗
██╔════╝██╔════╝╚██╗██╔╝██╔════╝╚██╗ ██╔╝██╔════╝╚══██╔══╝██╔════╝████╗ ████║
█████╗  ███████╗ ╚███╔╝ ███████╗ ╚████╔╝ ███████╗   ██║   █████╗  ██╔████╔██║
██╔══╝  ╚════██║ ██╔██╗ ╚════██║  ╚██╔╝  ╚════██║   ██║   ██╔══╝  ██║╚██╔╝██║
██║     ███████║██╔╝ ██╗███████║   ██║   ███████║   ██║   ███████╗██║ ╚═╝ ██║
╚═╝     ╚══════╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚══════╝   ╚═╝   ╚══════╝╚═╝     ╚═╝

🖥  Hostname : MIRTHA
⏳ Uptime   : up 3 days
📊 Load     : 0.45 0.30 0.25
💾 RAM      : 1.2G/1.9G
📦 Disco    : 12G/26G (46%)
🌐 IP Local : 10.0.0.73

  Docker: 7 containers running
```

### Ejecutar solo este rol

```bash
ansible-playbook playbooks/site.yml --tags motd
```
