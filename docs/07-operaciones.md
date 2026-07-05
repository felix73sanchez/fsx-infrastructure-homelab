# Operaciones del Día a Día

## Actualizar el Sistema

```bash
# Desde el controlador Ansible
make update

# O directo en mirtha
ssh fsxserver@10.0.0.73
sudo apt update && sudo apt upgrade -y
```

## Actualizar Contenedores

```bash
# Re-deployar todos los servicios con las últimas imágenes
make docker-services-mirtha

# O manualmente en mirtha para un servicio específico
ssh fsxserver@10.0.0.73
cd /opt/docker-apps/nginx && docker compose pull && docker compose up -d
```

## Ver Estado del Servidor

```bash
# Resumen rápido
ansible mirtha -m shell -a "df -h && free -h && uptime"

# Facts completos
make facts-mirtha

# Docker
ansible mirtha -m shell -a "docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'"
```

## Logs

```bash
# Todos los logs de un contenedor
ssh fsxserver@10.0.0.73
docker logs nginx-proxy --tail 100 -f

# Logs del sistema
journalctl -u docker -n 50 --no-pager
journalctl -u smbd -n 50 --no-pager

# Fail2ban
sudo fail2ban-client status sshd

# UFW
sudo ufw status verbose
```

## Diagnóstico de Red

```bash
# Puertos escuchando
ssh fsxserver@10.0.0.73
sudo ss -tlnp

# Conexiones activas
sudo ss -tup

# Resolución DNS
dig @10.0.0.73 google.com

# Tráfico por interfaz
sudo nethogs
```

## Espacio en Disco

```bash
ssh fsxserver@10.0.0.73
df -h
du -sh /var/lib/docker/
du -sh /opt/docker-apps/*/logs
```

Si el disco está lleno:

```bash
# Limpiar Docker
docker system prune -af --volumes

# Limpiar logs de contenedores vía logrotate
sudo logrotate -f /etc/logrotate.d/docker

# Revisar qué ocupa más
du -sh /* 2>/dev/null | sort -rh | head -10
```

## Monitoreo de Recursos

```bash
# Tiempo real
ssh fsxserver@10.0.0.73
htop                 # CPU + RAM
ctop                 # Contenedores
iotop                # I/O de disco
nethogs              # Red por proceso
glances              # Todo en uno

# Métricas Docker daemon
curl http://127.0.0.1:9323/metrics
```

## Reiniciar Servicios

```bash
# Docker (sin perder contenedores gracias a live-restore)
sudo systemctl restart docker

# Samba
sudo systemctl restart smbd

# nginx dentro del contenedor
docker exec nginx-proxy nginx -s reload

# Servidor completo
sudo reboot
```

## Reconstruir un Servicio Desde Cero

```bash
# Ejemplo: reconstruir Pi-hole
cd /opt/docker-apps/pihole
docker compose down -v              # CUIDADO: borra datos persistentes
docker compose up -d

# O desde Ansible
ansible-playbook playbooks/docker-services.yml --tags pihole --limit mirtha
```

## Hacer un Deploy Completo Desde Cero

```bash
# En un servidor nuevo
make install-deps          # Instalar collections Ansible
make deploy                # site.yml completo
make docker-services       # Todos los servicios Docker
```
