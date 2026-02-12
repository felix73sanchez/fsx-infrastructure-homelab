# FSXSYSTEM Infrastructure as Code

Ansible-based infrastructure management for FSXSYSTEM homelab.

## 🏗️ Architecture

- **Current Setup**: 1 Ubuntu Server (mirtha) - 30GB disk, 2GB RAM
- **Future Ready**: Designed to scale with multiple clusters and nodes

## 📁 Structure

```
fsx-infra/
├── ansible.cfg              # Ansible configuration
├── inventory/               # Inventory files
│   ├── hosts.yml           # Main inventory
│   └── host_vars/          # Per-host variables
├── group_vars/             # Group variables
│   ├── all.yml            # Global variables
│   └── homelab.yml        # Homelab-specific vars
├── roles/                  # Ansible roles
├── playbooks/             # Playbooks separated by function
├── templates/             # Jinja2 templates
└── requirements.yml       # External role dependencies
```

## 🚀 Quick Start

### Initial Setup
```bash
# Install Ansible
sudo apt update && sudo apt install -y ansible

# Clone repository
git clone <your-repo> fsx-infra
cd fsx-infra

# Install dependencies (if any)
ansible-galaxy install -r requirements.yml

# Test connectivity
ansible homelab -m ping
```

### Deploy Full Stack
```bash
# Deploy everything
ansible-playbook playbooks/site.yml

# Deploy specific role
ansible-playbook playbooks/site.yml --tags docker

# Deploy to specific host
ansible-playbook playbooks/site.yml --limit mirtha
```

## 📋 Available Playbooks

- `site.yml` - Complete infrastructure deployment
- `provision.yml` - Initial server provisioning
- `update.yml` - System updates only
- `docker-apps.yml` - Deploy Docker applications
- `backup.yml` - Backup configuration

## 🔧 Configuration

Edit variables in:
- `group_vars/all.yml` - Global settings
- `group_vars/homelab.yml` - Homelab-specific
- `inventory/host_vars/mirtha.yml` - Host-specific

## 📦 Installed Components

- Base system packages (vim, curl, git, htop, etc.)
- Docker & Docker Compose
- Security hardening (UFW, SSH config, fail2ban)
- Monitoring tools (optional)
- Custom MOTD

## 🔐 Security Features

- SSH hardening (no root login, key-based auth)
- UFW firewall configured
- Fail2ban for brute-force protection
- Automatic security updates
- Audit logging

## 📊 Monitoring

- System monitoring with htop/glances
- Docker container monitoring
- Log aggregation (optional)

## 🛠️ Maintenance

```bash
# Update all systems
ansible-playbook playbooks/update.yml

# Check system status
ansible homelab -m shell -a "df -h && free -h"

# Restart services
ansible-playbook playbooks/site.yml --tags docker --skip-tags install
```

## 🔄 Adding New Nodes

1. Add host to `inventory/hosts.yml`
2. Create host-specific vars in `inventory/host_vars/<hostname>.yml`
3. Run: `ansible-playbook playbooks/provision.yml --limit <hostname>`

## 📝 Notes

- All passwords stored in Ansible Vault (encrypted)
- Idempotent playbooks - safe to run multiple times
- Tagged tasks for selective deployment
- Handlers for service restarts only when needed

## 🤝 Contributing

Document all changes and test before deploying to production nodes.
