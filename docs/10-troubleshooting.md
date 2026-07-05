# Troubleshooting

## No puedo hacer SSH a mirtha

```bash
# 1. ¿Responde el host?
ping 10.0.0.73

# 2. ¿El puerto SSH está abierto?
nc -zv 10.0.0.73 22

# 3. ¿La clave SSH es la correcta?
ssh -i ~/.ssh/id_ed25519 -o StrictHostKeyChecking=no fsxserver@10.0.0.73
```

Si no responde: conectate por consola física o IPMI, y verificá:

```bash
systemctl status sshd
ip a show eth0
```

## Ansible no conecta: "Permission denied (publickey)"

```bash
# Verificar que la clave pública está en mirtha
ssh-copy-id fsxserver@10.0.0.73

# O verificá manualmente
ssh fsxserver@10.0.0.73 "cat ~/.ssh/authorized_keys"
```

## Container no arranca

```bash
# Ver logs
docker logs <container-name> --tail 50

# Ver estado
docker ps -a | grep <container-name>

# Inspeccionar
docker inspect <container-name> | jq '.[0].State'

# Forzar reinicio
docker rm -f <container-name> && docker compose up -d
```

## Puerto ya en uso

```bash
# Qué proceso lo tiene?
sudo ss -tlnp | grep <port>

# Ejemplo: puerto 80 ocupado
sudo ss -tlnp | grep ':80 '
```

Si es nginx del host compitiendo con nginx del contenedor:

```bash
sudo systemctl stop nginx     # Si existe nginx en el host
docker compose up -d          # Re-crear el contenedor
```

## Pi-hole no resuelve DNS

```bash
# Verificar que Pi-hole está corriendo
docker ps | grep pihole

# Hacer una consulta directa
dig @127.0.0.1 google.com

# Logs
docker logs pihole --tail 30

# Verificar puerto 53
sudo ss -tlnp | grep ':53 '
```

Si el puerto 53 está ocupado por `systemd-resolved`:

```bash
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved
```

## Cloudflare Tunnel caído

```bash
docker logs cloudflared --tail 20

# Verificar token
cat /opt/docker-apps/nginx/.env

# Token inválido? regenerar en:
# https://one.dash.cloudflare.com → Networks → Tunnels
```

## Samba: no puedo conectar desde Windows/Mac

```bash
# Verificar servicio
sudo systemctl status smbd

# Verificar firewall
sudo ufw status | grep 445

# Probar conexión local
smbclient -L //127.0.0.1 -U fsx_smb

# Logs
sudo tail -50 /var/log/samba/log.smbd
```

## Disco lleno

```bash
# Diagnóstico
df -h
du -sh /var/lib/docker/
du -sh /opt/

# Limpieza rápida
docker system prune -af --volumes
sudo journalctl --vacuum-time=3d
sudo apt autoremove --purge -y
```

## No encuentro un archivo de configuración

```bash
# Buscar en el servidor
find /opt/docker-apps -name "*.conf" -type f

# Buscar en el repositorio Ansible (local)
grep -r "palabra_clave" templates/ roles/
```

## El playbook falla con "timeout"

```bash
# Aumentar timeout (default es 10s para SSH)
ansible-playbook playbooks/site.yml --timeout 30
```

## Quiero hacer un cambio rápido sin Ansible

A veces es más rápido editar directo en el servidor.
Ansible detectará el cambio y lo sobrescribirá la próxima vez que
ejecutes el playbook (a menos que lo actualices también en el repo).

```bash
# Ejemplo: cambiar config de nginx
ssh fsxserver@10.0.0.73
nano /opt/docker-apps/nginx/conf.d/portfolio.conf
docker exec nginx-proxy nginx -s reload

# Recordá actualizar el template en Ansible después
# templates/docker-services/nginx/conf.d/portfolio.conf.j2
```
