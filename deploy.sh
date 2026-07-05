#!/bin/bash

# FSXSYSTEM Infrastructure Deployment Script
# Quick deployment helper

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
cat << "EOF"
 ███████╗███████╗██╗  ██╗███████╗██╗   ██╗███████╗████████╗███████╗███╗   ███╗
 ██╔════╝██╔════╝╚██╗██╔╝██╔════╝╚██╗ ██╔╝██╔════╝╚══██╔══╝██╔════╝████╗ ████║
 █████╗  ███████╗ ╚███╔╝ ███████╗ ╚████╔╝ ███████╗   ██║   █████╗  ██╔████╔██║
 ██╔══╝  ╚════██║ ██╔██╗ ╚════██║  ╚██╔╝  ╚════██║   ██║   ██╔══╝  ██║╚██╔╝██║
 ██║     ███████║██╔╝ ██╗███████║   ██║   ███████║   ██║   ███████╗██║ ╚═╝ ██║
 ╚═╝     ╚══════╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚══════╝   ╚═╝   ╚══════╝╚═╝     ╚═╝
EOF
echo -e "${NC}"
echo -e "${GREEN}Infrastructure Deployment Script${NC}"
echo ""

# Check if ansible is installed
if ! command -v ansible &> /dev/null; then
    echo -e "${RED}Ansible is not installed. Installing...${NC}"
    sudo apt update && sudo apt install -y ansible
fi

# Install dependencies
echo -e "${YELLOW}Installing Ansible Galaxy dependencies...${NC}"
ansible-galaxy install -r requirements.yml

# Test connectivity
echo -e "${YELLOW}Testing connectivity to hosts...${NC}"
if ansible homelab -m ping; then
    echo -e "${GREEN}✓ All hosts are reachable${NC}"
else
    echo -e "${RED}✗ Some hosts are not reachable. Please check your inventory.${NC}"
    exit 1
fi

# Menu
echo ""
echo "What would you like to do?"
echo "1) Full deployment (all hosts)"
echo "2) Deploy to specific host"
echo "3) Update systems only"
echo "4) Deploy Docker applications (Portainer/Watchtower)"
echo "5) Deploy Docker services (nginx, pihole, ma-tours, portfolio, qbittorrent)"
echo "6) Run syntax check"
echo "7) Exit"
echo ""
read -p "Enter your choice [1-6]: " choice

case $choice in
    1)
        echo -e "${YELLOW}Deploying full infrastructure...${NC}"
        ansible-playbook playbooks/site.yml
        ;;
    2)
        read -p "Enter hostname: " hostname
        echo -e "${YELLOW}Deploying to $hostname...${NC}"
        ansible-playbook playbooks/site.yml --limit $hostname
        ;;
    3)
        echo -e "${YELLOW}Updating systems...${NC}"
        ansible-playbook playbooks/update.yml
        ;;
    4)
        echo -e "${YELLOW}Deploying Docker applications (Portainer/Watchtower)...${NC}"
        ansible-playbook playbooks/docker-apps.yml
        ;;
    5)
        echo -e "${YELLOW}Deploying Docker services (nginx, pihole, etc.)...${NC}"
        ansible-playbook playbooks/docker-services.yml
        ;;
    6)
        echo -e "${YELLOW}Running syntax check...${NC}"
        ansible-playbook playbooks/site.yml --syntax-check
        echo -e "${GREEN}✓ Syntax check passed${NC}"
        ;;
    7)
        echo -e "${GREEN}Exiting...${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}✓ Operation completed successfully!${NC}"
