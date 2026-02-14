# FSXSYSTEM Infraestructura - Guía de Configuración

## Requisitos Previos

- Ansible 2.9+ instalado en la máquina de control
- Acceso SSH a todos los hosts objetivo
- Autenticación basada en clave SSH configurada
- Acceso sudo en los hosts objetivo

## Configuración Inicial

### 1. Instalar Ansible (en la máquina de control)

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y ansible

# macOS
brew install ansible

# Verificar instalación
ansible --version
```

### 2. Configurar Claves SSH

```bash
# Generar clave SSH si no tienes una
ssh-keygen -t rsa -b 4096 -C "tu_email@ejemplo.com"

# Copiar clave al host objetivo
ssh-copy-id fsxserver@10.0.0.73

# Probar conexión
ssh fsxserver@10.0.0.73
```

### 3. Clonar y Configurar Repositorio

```bash
# Clonar repositorio
git clone <url-de-repositorio> fsx-infra
cd fsx-infra

# Instalar dependencias de Ansible
ansible-galaxy install -r requirements.yml
```

### 4. Configurar Inventario

Editar `inventory/hosts.yml` para que coincida con tu ambiente:

```yaml
all:
  children:
    homelab:
      hosts:
        mirtha:
          ansible_host: 10.0.0.73
```

### 5. Probar Conectividad

```bash
# Probar ping
ansible homelab -m ping

# O usar Makefile
make ping
```

## Despliegue

### Despliegue Rápido

Usa el script de despliegue interactivo:

```bash
./deploy.sh
```

### Despliegue Manual

```bash
# Despliegue completo
ansible-playbook playbooks/site.yml

# Desplegar en host específico
ansible-playbook playbooks/site.yml --limit mirtha

# Desplegar rol específico
ansible-playbook playbooks/site.yml --tags docker

# Saltar rol específico
ansible-playbook playbooks/site.yml --skip-tags monitoring

# Verificación (modo check)
ansible-playbook playbooks/site.yml --check
```

### Usar Makefile

```bash
make deploy          # Despliegue completo
make update          # Solo actualizaciones del sistema
make docker-apps     # Desplegar aplicaciones Docker
make check           # Verificación de sintaxis
```

## Configuración

### Variables de Grupo

Editar `group_vars/all.yml` para configuración global:
- Zona horaria
- Paquetes base
- Configuración SSH
- Configuración de seguridad

Editar `group_vars/homelab.yml` para configuración específica del ambiente:
- Configuración de red
- Configuración de Docker
- Configuración de backup

### Variables de Host

Editar `inventory/host_vars/mirtha.yml` para configuración específica del host:
- Especificaciones de hardware
- Paquetes personalizados
- Banderas de despliegue de servicios

## Tareas Comunes

### Actualizar Sistemas

```bash
# Actualizar todos los hosts
ansible-playbook playbooks/update.yml

# Actualizar host específico
ansible-playbook playbooks/update.yml --limit mirtha

# Con reinicio automático (si es necesario)
ansible-playbook playbooks/update.yml -e "auto_reboot=true"
```

### Desplegar Aplicaciones Docker

```bash
ansible-playbook playbooks/docker-apps.yml
```

### Ejecutar Comandos Ad-hoc

```bash
# Verificar espacio en disco
ansible homelab -m shell -a "df -h"

# Verificar estado de Docker
ansible homelab -m shell -a "docker ps"

# Reiniciar servicio Docker
ansible homelab -m service -a "name=docker state=restarted" --become

# Recopilar facts
ansible mirtha -m setup
```

## Agregar Nuevos Hosts

1. Agregar host a `inventory/hosts.yml`:

```yaml
homelab:
  hosts:
    nuevohost:
      ansible_host: 10.0.0.74
```

2. Crear variables del host en `inventory/host_vars/nuevohost.yml`:

```yaml
cpu_cores: 4
memory_gb: 8
disk_size_gb: 100
```

3. Desplegar:

```bash
ansible-playbook playbooks/site.yml --limit nuevohost
```

## Escalado a Múltiples Clústeres

La estructura soporta múltiples clústeres:

```yaml
all:
  children:
    homelab:
      hosts:
        mirtha:
          ansible_host: 10.0.0.73
    
    production:
      hosts:
        prod-01:
          ansible_host: 10.0.1.10
        prod-02:
          ansible_host: 10.0.1.11
    
    staging:
      hosts:
        staging-01:
          ansible_host: 10.0.2.10
```

Crear variables de grupo específicas del ambiente:
- `group_vars/production.yml`
- `group_vars/staging.yml`

## Solución de Problemas

### Problemas de Conexión

```bash
# Salida detallada
ansible homelab -m ping -vvv

# Prueba SSH manual
ssh -i ~/.ssh/id_rsa fsxserver@10.0.0.73

# Verificar configuración SSH
cat ~/.ssh/config
```

### Errores de Playbook

```bash
# Verificación de sintaxis
ansible-playbook playbooks/site.yml --syntax-check

# Verificación (modo check)
ansible-playbook playbooks/site.yml --check

# Paso a paso
ansible-playbook playbooks/site.yml --step

# Empezar en tarea específica
ansible-playbook playbooks/site.yml --start-at-task="Install Docker"
```

### Ver Facts

```bash
# Todos los facts
ansible mirtha -m setup

# Facts específicos
ansible mirtha -m setup -a "filter=ansible_distribution*"
```

## Mejores Prácticas de Seguridad

### Usar Ansible Vault

```bash
# Crear vault
ansible-vault create group_vars/vault.yml

# Editar vault
ansible-vault edit group_vars/vault.yml

# Encriptar archivo existente
ansible-vault encrypt group_vars/sensitive.yml

# Ejecutar playbook con vault
ansible-playbook playbooks/site.yml --ask-vault-pass
```

### Almacenar Contraseña de Vault

```bash
# Crear archivo de contraseña
echo "tu-contraseña-vault" > ~/.ansible_vault_pass
chmod 600 ~/.ansible_vault_pass

# Actualizar ansible.cfg
# vault_password_file = ~/.ansible_vault_pass
```

## Mantenimiento

### Actualizaciones Regulares

Programar actualizaciones regulares del sistema:

```bash
# Actualizaciones semanales (agregar a crontab)
0 3 * * 0 cd /ruta/a/fsx-infra && ansible-playbook playbooks/update.yml
```

### Limpieza de Docker

La limpieza de Docker se automatiza vía cron (3 AM diariamente). Limpieza manual:

```bash
ansible homelab -m shell -a "docker system prune -af" --become
```

### Monitoreo

Acceder a Portainer (si está desplegado):
- http://ip-mirtha:9000

Verificar estado de contenedores:
```bash
ansible homelab -m shell -a "docker ps"
```

## Estrategia de Backup

1. Código de infraestructura: Control de versiones (Git)
2. Configuraciones de host: Gestionadas por Ansible (reproducibles)
3. Datos de aplicación: Volúmenes Docker (backup manual)

## Recursos

- [Documentación de Ansible](https://docs.ansible.com/)
- [Documentación de Docker](https://docs.docker.com/)
- [Mejores Prácticas](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
