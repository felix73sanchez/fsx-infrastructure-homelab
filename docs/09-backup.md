# Backup

No hay un playbook de backup automatizado todavía. Mientras tanto,
estas son las carpetas que deberías respaldar.

## Qué Respadalar

### 1. Datos de Docker

```bash
# Pi-hole (config + listas)
/opt/docker-apps/pihole/etc-pihole/
/opt/docker-apps/pihole/etc-dnsmasq.d/

# MA Tours (base de datos PostgreSQL — requiere dump)
docker exec ma-tours-db pg_dump -U ma_tours ma_tours > backup_ma_tours.sql

# Portfolio (base de datos SQLite)
/opt/docker-apps/portfolio-fsx-nxt/data/

# nginx (logs y config)
/opt/docker-apps/nginx/conf.d/
/opt/docker-apps/nginx/nginx.conf

# qBittorrent (config)
/opt/docker-apps/qbittorrent/config/
```

### 2. Archivos Compartidos

```bash
/srv/samba/compartido/
```

### 3. SSL Certificate

```bash
/etc/letsencrypt/live/fsxsys.org/
```

### 4. Disco Externo

```bash
/mnt/storage/data/torrents/     # Solo metadata, torrents se pueden re-descargar
```

### 5. Este Repositorio

El repositorio de Ansible **es tu backup de config** — mantenelo actualizado.

## Comandos de Backup Manual

```bash
#!/bin/bash
# backup.sh — ejecutar en mirtha

BACKUP_DIR="/mnt/storage/backups/$(date +%Y%m%d-%H%M)"
mkdir -p "$BACKUP_DIR"

# PostgreSQL dump
docker exec ma-tours-db pg_dump -U ma_tours ma_tours > "$BACKUP_DIR/ma_tours.sql"

# Copiar datos persistentes
cp -r /opt/docker-apps/pihole/etc-pihole "$BACKUP_DIR/pihole/"
cp /opt/docker-apps/portfolio-fsx-nxt/data/portfolio.db "$BACKUP_DIR/"

# Configs
cp -r /opt/docker-apps/nginx/conf.d "$BACKUP_DIR/nginx/"
cp /opt/docker-apps/nginx/nginx.conf "$BACKUP_DIR/nginx/"

# Comprimir
tar czf "$BACKUP_DIR.tar.gz" -C "$(dirname $BACKUP_DIR)" "$(basename $BACKUP_DIR)"
rm -rf "$BACKUP_DIR"

echo "Backup creado: $BACKUP_DIR.tar.gz"
```

## Próximos Pasos

Cuando quieras, se puede crear:

1. Un playbook `playbooks/backup.yml` que automatice todo esto
2. Un cron job que ejecute el backup diariamente
3. Un script que suba los backups a un bucket S3/Backblaze
