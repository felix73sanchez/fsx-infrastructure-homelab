# Backup y Restore

## Backup

### Qué Respaldar

#### Docker Volumes

```bash
# Pi-hole (config + listas de bloqueo)
/opt/docker-apps/pihole/etc-pihole/
/opt/docker-apps/pihole/etc-dnsmasq.d/

# MA Tours (PostgreSQL — requiere dump, no copiar raw)
docker exec ma-tours-db pg_dump -U ma_tours ma_tours > backup_ma_tours.sql

# Portfolio (base SQLite + uploads)
/opt/docker-apps/portfolio-fsx-nxt/data/
/opt/docker-apps/portfolio-fsx-nxt/public/uploads/

# nginx (config de virtual hosts)
/opt/docker-apps/nginx/conf.d/
/opt/docker-apps/nginx/nginx.conf

# qBittorrent (config)
/opt/docker-apps/qbittorrent/config/
```

#### Archivos del Sistema

```bash
/srv/samba/compartido/              # Archivos Samba
/etc/letsencrypt/live/fsxsys.org/   # SSL certificates
/mnt/storage/data/torrents/         # Torrents (o re-descargables)
```

#### Este Repositorio

El repo de Ansible **es el backup de config**. Si perdés todo,
con el repo + los datos respaldados recuperás todo.

### Script de Backup

```bash
#!/bin/bash
# /opt/scripts/backup.sh — ejecutar en mirtha

set -e
BACKUP_DIR="/mnt/storage/backups/$(date +%Y%m%d-%H%M)"
mkdir -p "$BACKUP_DIR"

echo "PostgreSQL..."
docker exec ma-tours-db pg_dump -U ma_tours ma_tours > "$BACKUP_DIR/ma_tours.sql"

echo "Pi-hole..."
cp -r /opt/docker-apps/pihole/etc-pihole "$BACKUP_DIR/pihole/"
cp -r /opt/docker-apps/pihole/etc-dnsmasq.d "$BACKUP_DIR/dnsmasq/"

echo "Portfolio..."
cp /opt/docker-apps/portfolio-fsx-nxt/data/portfolio.db "$BACKUP_DIR/"
cp -r /opt/docker-apps/portfolio-fsx-nxt/public/uploads "$BACKUP_DIR/uploads/"

echo "nginx..."
cp -r /opt/docker-apps/nginx/conf.d "$BACKUP_DIR/nginx-conf/"
cp /opt/docker-apps/nginx/nginx.conf "$BACKUP_DIR/nginx.conf"

echo "Samba..."
cp -r /srv/samba/compartido "$BACKUP_DIR/samba/"

echo "Comprimiendo..."
tar czf "$BACKUP_DIR.tar.gz" -C "$(dirname $BACKUP_DIR)" "$(basename $BACKUP_DIR)"
rm -rf "$BACKUP_DIR"

echo "Backup listo: $BACKUP_DIR.tar.gz"
```

### Automatizar con Cron

```bash
# Ejecutar backup todos los días a las 2 AM
sudo crontab -e
# Agregar:
0 2 * * * /opt/scripts/backup.sh

# Opcional: borrar backups viejos (>30 días)
0 3 * * * find /mnt/storage/backups/ -name "*.tar.gz" -mtime +30 -delete
```

---

## Restore

### Principio General

1. **Levantá los servicios con Ansible primero** (recrea los containers)
2. **Restaurá los datos** en los volúmenes correctos
3. **Reiniciá los containers** para que tomen los datos

Los containers son efímeros. Los datos son lo importante.

### Restaurar Servicio por Servicio

#### nginx + Cloudflare

```bash
cd /opt/docker-apps/nginx
docker compose down

tar xzf /mnt/storage/backups/20260705-1015.tar.gz -C /tmp/restore
cp /tmp/restore/*/nginx.conf ./
cp -r /tmp/restore/*/nginx-conf/* ./conf.d/

# Re-crear .env con token de Cloudflare si no está
docker compose up -d
```

#### Pi-hole

```bash
cd /opt/docker-apps/pihole
docker compose down

tar xzf /mnt/storage/backups/20260705-1015.tar.gz -C /tmp/restore
rm -rf etc-pihole etc-dnsmasq.d
cp -r /tmp/restore/*/pihole ./etc-pihole
cp -r /tmp/restore/*/dnsmasq ./etc-dnsmasq.d

docker compose up -d
```

#### MA Tours (PostgreSQL)

```bash
cd /opt/docker-apps/ma-tours
docker compose down -v           # -v borra el volume postgres_data

tar xzf /mnt/storage/backups/20260705-1015.tar.gz -C /tmp/restore

# Levantar solo la DB
docker compose up -d ma-tours-db
sleep 10

# Cargar dump
docker exec -i ma-tours-db psql -U ma_tours ma_tours < /tmp/restore/*/ma_tours.sql

# Levantar todo
docker compose up -d
```

#### Portfolio (SQLite)

```bash
cd /opt/docker-apps/portfolio-fsx-nxt
docker compose down

tar xzf /mnt/storage/backups/20260705-1015.tar.gz -C /tmp/restore
cp /tmp/restore/*/portfolio.db ./data/
cp -r /tmp/restore/*/uploads/* ./public/uploads/ 2>/dev/null || true

docker compose up -d
```

#### qBittorrent

```bash
cd /opt/docker-apps/qbittorrent
docker compose down

tar xzf /mnt/storage/backups/20260705-1015.tar.gz -C /tmp/restore
rm -rf config/*
cp -r /tmp/restore/*/qbittorrent-config/* ./config/

docker compose up -d
```

#### Samba

```bash
# Datos compartidos
cp -r /mnt/storage/backups/samba/* /srv/samba/compartido/

# Config (recuperar con Ansible)
ansible-playbook playbooks/site.yml --tags samba --limit mirtha
```

---

### Restore Completo (Servidor Desde Cero)

Si perdiste el servidor completo y tenés que reinstalar:

```bash
# 1. Instalar SO (Ubuntu 24.04)
# 2. IP estática 10.0.0.73
# 3. Crear usuario fsxserver con sudo
# 4. Agregar clave SSH

# 5. En el controlador Ansible:
ansible-playbook playbooks/site.yml --limit mirtha

# 6. Montar disco NTFS (verificar UUID)
sudo mount -a

# 7. Restaurar datos de Docker
tar xzf /mnt/storage/backups/20260705-1015.tar.gz -C /opt/docker-apps/

# 8. Desplegar servicios Docker con secrets
ansible-playbook playbooks/docker-services.yml --limit mirtha \
  --extra-vars 'cloudflare_tunnel_token=...' \
  --extra-vars 'pihole_webpassword=...' \
  --extra-vars 'ma_tours_db_password=...' \
  --extra-vars 'portfolio_jwt_secret=...' \
  --extra-vars 'portfolio_invitation_code=...'

# 9. Restaurar datos dentro de containers
cd /opt/docker-apps/ma-tours
docker compose down -v
docker compose up -d ma-tours-db && sleep 10
docker exec -i ma-tours-db psql -U ma_tours ma_tours < /opt/docker-apps/ma_tours.sql

# 10. Verificar
ssh fsxserver@10.0.0.73
docker ps
```

### Script de Restore

```bash
#!/bin/bash
# /opt/scripts/restore.sh <archivo-backup.tar.gz>
# Ejemplo: /opt/scripts/restore.sh /mnt/storage/backups/20260705-1015.tar.gz

set -e
BACKUP_FILE="$1"
RESTORE_DIR="/tmp/restore-$(date +%s)"

if [ -z "$BACKUP_FILE" ]; then
    echo "Uso: $0 <archivo-backup.tar.gz>"
    exit 1
fi

echo "Restaurando desde $BACKUP_FILE ..."
mkdir -p "$RESTORE_DIR"
tar xzf "$BACKUP_FILE" -C "$RESTORE_DIR"

# El backup crea un subdirectorio con la fecha
BD=$(ls "$RESTORE_DIR")

# nginx
echo "nginx..."
cd /opt/docker-apps/nginx
[ -f "$RESTORE_DIR/$BD/nginx.conf" ] && cp "$RESTORE_DIR/$BD/nginx.conf" ./
[ -d "$RESTORE_DIR/$BD/nginx-conf" ] && cp -r "$RESTORE_DIR/$BD/nginx-conf"/* ./conf.d/

# Pi-hole
echo "Pi-hole..."
cd /opt/docker-apps/pihole
if [ -d "$RESTORE_DIR/$BD/pihole" ]; then
  rm -rf etc-pihole etc-dnsmasq.d
  cp -r "$RESTORE_DIR/$BD/pihole" ./etc-pihole
  [ -d "$RESTORE_DIR/$BD/dnsmasq" ] && cp -r "$RESTORE_DIR/$BD/dnsmasq"/* ./etc-dnsmasq.d/
fi

# MA Tours PostgreSQL
echo "MA Tours..."
cd /opt/docker-apps/ma-tours
if [ -f "$RESTORE_DIR/$BD/ma_tours.sql" ]; then
  docker compose up -d ma-tours-db 2>/dev/null || true
  sleep 10
  docker exec -i ma-tours-db psql -U ma_tours ma_tours < "$RESTORE_DIR/$BD/ma_tours.sql"
fi

# Portfolio
echo "Portfolio..."
cd /opt/docker-apps/portfolio-fsx-nxt
[ -f "$RESTORE_DIR/$BD/portfolio.db" ] && cp "$RESTORE_DIR/$BD/portfolio.db" ./data/
[ -d "$RESTORE_DIR/$BD/uploads" ] && cp -r "$RESTORE_DIR/$BD/uploads"/* ./public/uploads/ 2>/dev/null || true

# Samba
echo "Samba..."
[ -d "$RESTORE_DIR/$BD/samba" ] && cp -r "$RESTORE_DIR/$BD/samba"/* /srv/samba/compartido/ 2>/dev/null || true

rm -rf "$RESTORE_DIR"

echo ""
echo "Restore completado."
echo "Reiniciá los containers: cd /opt/docker-apps/*/ && docker compose up -d"
```

### Sin Backup — Qué Hacer

| Servicio | Qué perdés | Cómo recuperar |
|---|---|---|
| nginx | Config de dominios | Re-crear con `make docker-services` |
| Pi-hole | Listas de bloqueo, stats | `docker compose up -d` y configurar desde admin |
| MA Tours | Datos de la app | Sin dump de Postgres no hay recuperación |
| Portfolio | Posts, usuarios, uploads | Sin backup de SQLite no hay recuperación |
| qBittorrent | Torrents activos | Re-agregar manualmente |
| Samba | Archivos compartidos | Sin copia de archivos, perdidos |

**Regla de oro**: si los datos importan, hacé backup antes de tocar nada.
