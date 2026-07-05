# Cómo Agregar un Nuevo Nodo al Homelab

Este documento cubre el proceso completo para agregar un servidor
adicional a la infraestructura.

## Prerrequisitos

- El servidor debe tener SO instalado y SSH habilitado
- Debés tener acceso root o un usuario con sudo
- El usuario `fsxserver` debe existir o se creará via el playbook

## Paso 1: Preparar el Nodo

```bash
# Desde el nuevo servidor
sudo apt update && sudo apt upgrade -y   # Debian
sudo dnf update                          # RedHat

# Crear usuario (si no existe)
sudo useradd -m -s /bin/bash fsxserver
sudo usermod -aG sudo fsxserver

# Agregar tu clave pública
sudo mkdir -p ~fsxserver/.ssh
echo "tu-clave-publica" | sudo tee ~fsxserver/.ssh/authorized_keys
sudo chown -R fsxserver:fsxserver ~fsxserver/.ssh
sudo chmod 700 ~fsxserver/.ssh
sudo chmod 600 ~fsxserver/.ssh/authorized_keys

# Probar conexión desde el controlador
ssh fsxserver@<nueva-ip>
```

## Paso 2: Agregar al Inventory

```yaml
# inventory/hosts.yml — dentro del grupo correspondiente
all:
  children:
    homelab:
      children:
        servers:
          hosts:
            mirtha:
              ansible_host: 10.0.0.73
            nuevo-nodo:              # <-- agregar acá
              ansible_host: 10.0.0.74
```

## Paso 3: Crear Host Vars

```yaml
# inventory/host_vars/nuevo-nodo.yml

# Hardware
cpu_cores: 4
memory_gb: 8
disk_size_gb: 100

# Red
primary_interface: eth0
static_ip: 10.0.0.74

# Docker users
docker_users:
  - fsxserver

# Paquetes adicionales
additional_packages:
  - ncdu
  - tree
  - tmux

# Firewall (elegir engine según distro)
# firewall_engine: firewalld          # para RedHat
```

## Paso 4: Verificar Conectividad

```bash
make ping
ansible nuevo-nodo -m ping
ansible nuevo-nodo -m setup | head -20
```

## Paso 5: Desplegar Infraestructura Base

```bash
# Despliegue completo
ansible-playbook playbooks/site.yml --limit nuevo-nodo

# O por partes
ansible-playbook playbooks/site.yml --limit nuevo-nodo --tags base
ansible-playbook playbooks/site.yml --limit nuevo-nodo --tags security
ansible-playbook playbooks/site.yml --limit nuevo-nodo --tags docker
```

## Paso 6: Desplegar Servicios Docker

Si el nodo va a correr servicios:

```bash
# Con secretos (ajustar según corresponda)
ansible-playbook playbooks/docker-services.yml --limit nuevo-nodo \
  --extra-vars 'cloudflare_tunnel_token=...'
```

## Verificación Final

```bash
# Resumen del nodo
ansible nuevo-nodo -m shell -a "hostname && uptime && df -h && free -h"

# Docker
ansible nuevo-nodo -m shell -a "docker ps"

# Firewall
ansible nuevo-nodo -m shell -a "ufw status verbose"
```

## Qué NO Hace el Playbook Automáticamente

- **No agrega tu clave SSH** al authorized_keys del nuevo usuario
- **No configura IP estática** (asumimos DHCP o config manual)
- **No registra DNS** en Pi-hole ni Cloudflare
- **No configura monitoreo** si `monitoring_enabled: false`
- **No instala EPEL** en RedHat (debés agregarlo a `base_packages`)

## Checklist Rápido

```
[ ] 1. SO instalado y SSH funcionando
[ ] 2. Usuario fsxserver creado con sudo
[ ] 3. Clave SSH copiada al nodo
[ ] 4. Host agregado a inventory/hosts.yml
[ ] 5. Host vars creadas en inventory/host_vars/
[ ] 6. ansible-galaxy install -r requirements.yml
[ ] 7. ansible-playbook playbooks/site.yml --limit nuevo-nodo
[ ] 8. ansible-playbook playbooks/docker-services.yml --limit nuevo-nodo
```
