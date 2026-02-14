# FSXSYSTEM Infraestructura como Código

Gestión de infraestructura basada en Ansible para el laboratorio FSXSYSTEM.

## 🏗️ Arquitectura

- **Configuración Actual**: 1 Servidor Ubuntu (mirtha) - 30GB disco, 2GB RAM
- **Preparado para el Futuro**: Diseñado para escalar con múltiples clústeres y nodos

## 📁 Estructura

```
fsx-infra/
├── ansible.cfg              # Configuración de Ansible
├── inventory/               # Archivos de inventario
│   ├── hosts.yml           # Inventario principal
│   └── host_vars/          # Variables por host
├── group_vars/             # Variables de grupo
│   ├── all.yml            # Variables globales
│   └── homelab.yml        # Variables específicas del homelab
├── roles/                  # Roles de Ansible
├── playbooks/             # Playbooks separados por función
├── templates/             # Plantillas Jinja2
└── requirements.yml       # Dependencias de roles externos
```

## 🚀 Inicio Rápido

### Configuración Inicial
```bash
# Instalar Ansible
sudo apt update && sudo apt install -y ansible

# Clonar repositorio
git clone <tu-repo> fsx-infra
cd fsx-infra

# Instalar dependencias (si las hay)
ansible-galaxy install -r requirements.yml

# Probar conectividad
ansible homelab -m ping
```

### Desplegar Stack Completo
```bash
# Desplegar todo
ansible-playbook playbooks/site.yml

# Desplegar rol específico
ansible-playbook playbooks/site.yml --tags docker

# Desplegar en host específico
ansible-playbook playbooks/site.yml --limit mirtha
```

## 📋 Playbooks Disponibles

- `site.yml` - Despliegue completo de infraestructura
- `update.yml` - Solo actualizaciones del sistema
- `docker-apps.yml` - Desplegar aplicaciones Docker

## 🔧 Configuración

Editar variables en:
- `group_vars/all.yml` - Configuración global
- `group_vars/homelab.yml` - Específico del homelab
- `inventory/host_vars/mirtha.yml` - Específico del host

## 📦 Componentes Instalados

- Paquetes base del sistema (vim, curl, git, htop, etc.)
- Docker y Docker Compose
- Endurecimiento de seguridad (UFW, configuración SSH, fail2ban)
- Herramientas de monitoreo (opcional)
- MOTD personalizado

## 🔐 Características de Seguridad

- Endurecimiento SSH (sin acceso root, autenticación por clave)
- Cortafuegos UFW configurado
- Fail2ban para protección contra ataques de fuerza bruta
- Actualizaciones de seguridad automáticas
- Registro de auditoría

## 📊 Monitoreo

- Monitoreo del sistema con htop/glances
- Monitoreo de contenedores Docker
- Agregación de registros (opcional)

## 🛠️ Mantenimiento

```bash
# Actualizar todos los sistemas
ansible-playbook playbooks/update.yml

# Verificar estado del sistema
ansible homelab -m shell -a "df -h && free -h"

# Reiniciar servicios
ansible-playbook playbooks/site.yml --tags docker --skip-tags install
```

## 🔄 Agregar Nuevos Nodos

1. Añadir host a `inventory/hosts.yml`
2. Crear variables específicas del host en `inventory/host_vars/<hostname>.yml`
3. Ejecutar: `ansible-playbook playbooks/site.yml --limit <hostname>`

## 📝 Notas

- Todas las contraseñas almacenadas en Ansible Vault (encriptadas)
- Playbooks idempotentes - seguros para ejecutar múltiples veces
- Tareas etiquetadas para despliegue selectivo
- Manejadores para reinicio de servicios solo cuando sea necesario

## 🤝 Contribuir

Documenta todos los cambios y prueba antes de desplegar en nodos de producción.
