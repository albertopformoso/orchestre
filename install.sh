#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Define text colors for better readability
RECOLOR='\033[0;32m' # Green
NOCOLOR='\033[0m'

echo -e "${RECOLOR}=== Orchestre OS: Starting Installation ===${NOCOLOR}"

# 1. Check if Ansible is installed
if ! command -v ansible-playbook &> /dev/null; then
    echo -e "${RECOLOR}[*] Ansible not found. Installing via pacman...${NOCOLOR}"

    # Update package database and install ansible
    sudo pacman -Sy --noconfirm ansible
else
    echo -e "${RECOLOR}[+] Ansible is already installed.${NOCOLOR}"
fi

# 2. Install Ansible Galaxy dependencies
if [ -f "requirements.yml" ]; then
    echo -e "${RECOLOR}[*] Checking and installing missing Ansible Galaxy dependencies...${NOCOLOR}"
    # This natively skips packages that are already present
    ansible-galaxy collection install -r requirements.yml
else
    echo -e "${RECOLOR}[+] No requirements.yml found. Skipping Galaxy install.${NOCOLOR}"
fi

# 3. Verify the Ansible configuration structure exists locally

# 4. Run the Ansible Playbook(s)
echo -e "${RECOLOR}[*] Tuning the instruments... Running Ansible Playbook... ${NOCOLOR}"

# --ask-become-pass prompts you for your sudo password so Ansible can install system packages
ansible-playbook -i inventory.ini site.yml --ask-become-pass

echo -e "${RECOLOR}=== Orchestre-OS: Configuration Complete! ===${NOCOLOR}"
