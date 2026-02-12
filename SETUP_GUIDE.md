# FSXSYSTEM Infrastructure - Setup Guide

## Prerequisites

- Ansible 2.9+ installed on control machine
- SSH access to all target hosts
- SSH key-based authentication configured
- Sudo access on target hosts

## Initial Setup

### 1. Install Ansible (on control machine)

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y ansible

# macOS
brew install ansible

# Verify installation
ansible --version
```

### 2. Configure SSH Keys

```bash
# Generate SSH key if you don't have one
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# Copy key to target host
ssh-copy-id fsxserver@10.0.0.73

# Test connection
ssh fsxserver@10.0.0.73
```

### 3. Clone and Setup Repository

```bash
# Clone repository
git clone <your-repo-url> fsx-infra
cd fsx-infra

# Install Ansible dependencies
ansible-galaxy install -r requirements.yml
```

### 4. Configure Inventory

Edit `inventory/hosts.yml` to match your environment:

```yaml
all:
  children:
    homelab:
      hosts:
        mirtha:
          ansible_host: 10.0.0.73
```

### 5. Test Connectivity

```bash
# Test ping
ansible homelab -m ping

# Or use Makefile
make ping
```

## Deployment

### Quick Deployment

Use the interactive deployment script:

```bash
./deploy.sh
```

### Manual Deployment

```bash
# Full deployment
ansible-playbook playbooks/site.yml

# Deploy to specific host
ansible-playbook playbooks/site.yml --limit mirtha

# Deploy specific role
ansible-playbook playbooks/site.yml --tags docker

# Skip specific role
ansible-playbook playbooks/site.yml --skip-tags monitoring

# Dry run (check mode)
ansible-playbook playbooks/site.yml --check
```

### Using Makefile

```bash
make deploy          # Full deployment
make update          # System updates only
make docker-apps     # Deploy Docker applications
make check           # Syntax check
```

## Configuration

### Group Variables

Edit `group_vars/all.yml` for global settings:
- Timezone
- Base packages
- SSH configuration
- Security settings

Edit `group_vars/homelab.yml` for environment-specific settings:
- Network configuration
- Docker settings
- Backup configuration

### Host Variables

Edit `inventory/host_vars/mirtha.yml` for host-specific settings:
- Hardware specs
- Custom packages
- Service deployment flags

## Common Tasks

### Update Systems

```bash
# Update all hosts
ansible-playbook playbooks/update.yml

# Update specific host
ansible-playbook playbooks/update.yml --limit mirtha

# With automatic reboot (if needed)
ansible-playbook playbooks/update.yml -e "auto_reboot=true"
```

### Deploy Docker Applications

```bash
ansible-playbook playbooks/docker-apps.yml
```

### Run Ad-hoc Commands

```bash
# Check disk space
ansible homelab -m shell -a "df -h"

# Check Docker status
ansible homelab -m shell -a "docker ps"

# Restart Docker service
ansible homelab -m service -a "name=docker state=restarted" --become

# Gather facts
ansible mirtha -m setup
```

## Adding New Hosts

1. Add host to `inventory/hosts.yml`:

```yaml
homelab:
  hosts:
    newhost:
      ansible_host: 10.0.0.74
```

2. Create host vars in `inventory/host_vars/newhost.yml`:

```yaml
cpu_cores: 4
memory_gb: 8
disk_size_gb: 100
```

3. Deploy:

```bash
ansible-playbook playbooks/site.yml --limit newhost
```

## Scaling to Multiple Clusters

The structure supports multiple clusters:

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

Create environment-specific group vars:
- `group_vars/production.yml`
- `group_vars/staging.yml`

## Troubleshooting

### Connection Issues

```bash
# Verbose output
ansible homelab -m ping -vvv

# Test SSH manually
ssh -i ~/.ssh/id_rsa fsxserver@10.0.0.73

# Check SSH config
cat ~/.ssh/config
```

### Playbook Errors

```bash
# Syntax check
ansible-playbook playbooks/site.yml --syntax-check

# Dry run
ansible-playbook playbooks/site.yml --check

# Step by step
ansible-playbook playbooks/site.yml --step

# Start at specific task
ansible-playbook playbooks/site.yml --start-at-task="Install Docker"
```

### View Facts

```bash
# All facts
ansible mirtha -m setup

# Specific fact
ansible mirtha -m setup -a "filter=ansible_distribution*"
```

## Security Best Practices

### Use Ansible Vault

```bash
# Create vault
ansible-vault create group_vars/vault.yml

# Edit vault
ansible-vault edit group_vars/vault.yml

# Encrypt existing file
ansible-vault encrypt group_vars/sensitive.yml

# Run playbook with vault
ansible-playbook playbooks/site.yml --ask-vault-pass
```

### Store Vault Password

```bash
# Create password file
echo "your-vault-password" > ~/.ansible_vault_pass
chmod 600 ~/.ansible_vault_pass

# Update ansible.cfg
# vault_password_file = ~/.ansible_vault_pass
```

## Maintenance

### Regular Updates

Schedule regular system updates:

```bash
# Weekly updates (add to crontab)
0 3 * * 0 cd /path/to/fsx-infra && ansible-playbook playbooks/update.yml
```

### Docker Cleanup

Docker cleanup is automated via cron (3 AM daily). Manual cleanup:

```bash
ansible homelab -m shell -a "docker system prune -af" --become
```

### Monitoring

Access Portainer (if deployed):
- http://mirtha-ip:9000

Check container status:
```bash
ansible homelab -m shell -a "docker ps"
```

## Backup Strategy

1. Infrastructure code: Version control (Git)
2. Host configs: Managed by Ansible (reproducible)
3. Application data: Docker volumes (manual backup)

## Resources

- [Ansible Documentation](https://docs.ansible.com/)
- [Docker Documentation](https://docs.docker.com/)
- [Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
