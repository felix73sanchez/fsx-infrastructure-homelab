# Soporte Multi-Distro

El stack Ansible está diseñado para funcionar en **Debian/Ubuntu** y
**RedHat/Rocky/Alma/Fedora/CentOS**. Un solo playbook, sin ramificar.

## Cómo Funciona

Los roles usan `ansible_os_family` para seleccionar el comportamiento
correcto en tiempo de ejecución:

```yaml
- name: Install package
  package:                          # ← auto-detecta apt/dnf/yum
    name: "{{ some_package }}"
    state: present

- name: Configure NTP (Debian)
  template: ...
  when: ansible_os_family == 'Debian'

- name: Configure NTP (RedHat)
  lineinfile: ...
  when: ansible_os_family == 'RedHat'
```

## Diferencias por Distro

| Componente | Debian | RedHat |
|---|---|---|
| Package manager | `apt` | `dnf` / `yum` |
| Módulo Ansible | `package` → apt | `package` → dnf |
| Firewall | UFW | firewalld |
| NTP | systemd-timesyncd | chronyd |
| Auto-updates | unattended-upgrades | dnf-automatic |
| Servicios Samba | smbd, nmbd | smb, nmb |
| Docker install | get.docker.com | get.docker.com |
| Paquetes extra | ntfs-3g | ntfs-3g (EPEL) |

## Agregar un Nodo RedHat

### 1. Inventory

```yaml
# inventory/hosts.yml
all:
  children:
    homelab:
      hosts:
        mirtha: ...
        rocky-node:
          ansible_host: 10.0.0.74
          ansible_os_family: RedHat
```

### 2. Host vars

```yaml
# inventory/host_vars/rocky-node.yml
firewall_engine: firewalld
base_packages:
  - vim
  - curl
  - wget
  - git
  - htop
  - epel-release           # ← necesario para algunos paquetes
```

### 3. Desplegar

```bash
ansible-playbook playbooks/site.yml --limit rocky-node
```

## Variables Clave para Multi-Distro

| Variable | Default | Para RedHat |
|---|---|---|
| `firewall_engine` | `ufw` | `firewalld` |
| `ansible_os_family` | `Debian` (auto) | `RedHat` |
| `base_packages` | (lista Debian) | Agregar `epel-release` |

## Limitaciones

- Los templates de auto-updates (`50unattended-upgrades.j2`) son
  Debian-specific. Para RedHat usa `dnf-automatic` sin template.
- Algunos paquetes (`ntfs-3g`, `mergerfs`) pueden requerir EPEL en RedHat.
- `apt` tasks con `upgrade: dist` no tienen equivalente exacto en dnf.
