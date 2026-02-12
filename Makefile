.PHONY: help ping deploy update check install-deps backup

# Default target
help:
	@echo "FSXSYSTEM Infrastructure Management"
	@echo ""
	@echo "Available commands:"
	@echo "  make ping          - Test connectivity to all hosts"
	@echo "  make deploy        - Deploy full infrastructure"
	@echo "  make update        - Update all systems"
	@echo "  make check         - Run Ansible syntax check"
	@echo "  make install-deps  - Install Ansible dependencies"
	@echo "  make docker-apps   - Deploy Docker applications"
	@echo "  make backup        - Run backup playbook"
	@echo ""

# Test connectivity
ping:
	ansible homelab -m ping

# Full deployment
deploy:
	ansible-playbook playbooks/site.yml

# Deploy to specific host
deploy-mirtha:
	ansible-playbook playbooks/site.yml --limit mirtha

# System updates
update:
	ansible-playbook playbooks/update.yml

# Deploy Docker apps
docker-apps:
	ansible-playbook playbooks/docker-apps.yml

# Syntax check
check:
	ansible-playbook playbooks/site.yml --syntax-check

# Install Ansible Galaxy dependencies
install-deps:
	ansible-galaxy install -r requirements.yml

# Show inventory
inventory:
	ansible-inventory --graph

# Show facts for a host
facts-mirtha:
	ansible mirtha -m setup

# Backup
backup:
	@echo "Backup playbook not yet implemented"
