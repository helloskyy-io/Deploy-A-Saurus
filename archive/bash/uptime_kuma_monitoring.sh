#!/bin/bash

# display logo
echo ""
echo ""
echo " #####                        #     #"              
echo "#     # #    # #   # #   #    ##    # ###### ##### " 
echo "#       #   #   # #   # #     # #   # #        #   "
echo " #####  ####     #     #      #  #  # #####    #   "
echo "      # #  #     #     #      #   # # #        #   "
echo "#     # #   #    #     #      #    ## #        #   "
echo " #####  #    #   #     #      #     # ######   #   "
echo ""
echo "System activated..."
sleep 3

# Output description of the script's purpose
echo ""
echo ""
echo "This script will install and configure Ansible on your Ubuntu server container."
echo "It will also perform system updates using apt update/upgrade."
echo "Once complete it will prompt you to configure the container packages and dependancies via Ansible."
sleep 3

# Prompt user for confirmation to proceed
echo ""
read -p "Do you want to continue? (y/n): " choice
if [[ ! $choice =~ ^[Yy]$ ]]; then
    echo "Exiting script."
    exit 1
fi

# Update package repositories
echo ""
echo ""
echo "Updating package repositories..."
sleep 2
apt update

# Upgrade installed packages
echo ""
echo ""
echo "Upgrading installed packages..."
sleep 2
apt upgrade -y

# Install Ansible
echo ""
echo ""
echo "Installing Ansible..."
sleep 2
apt install -y ansible python3-apt

# Install Git
echo ""
echo ""
echo "Installing Git..."
sleep 2
apt install -y git

# Clone Ansible repository
echo ""
echo ""
echo "Cloning FluxEdge-AI-Toolbox..."
sleep 2
git clone https://github.com/helloskyy-io/FluxEdge-AI-Toolbox.git /FluxEdge_AI_Toolbox

# Display completion message
echo ""
echo ""
echo "Ansible installation and configuration completed successfully."
sleep 2
echo "You can run it manually by copying the following command: "
echo "ansible-playbook -i localhost, -c local /FluxEdge_AI_Toolbox/ansible/playbooks/AI_Toolbox.yml"

# Prompt user for confirmation to proceed
echo ""
read -p "Ready to launch Ansible? (y/n): " choice
if [[ ! $choice =~ ^[Yy]$ ]]; then
    echo "Exiting script."
    exit 1
fi

# Launch Ansible playbook
echo ""
echo ""
echo "Launching Ansible playbook..."
sleep 2
ANSIBLE_CONFIG=/FluxEdge_AI_Toolbox/ansible/ansible.cfg ansible-playbook -i localhost, -c local /FluxEdge_AI_Toolbox/ansible/playbooks/AI_Toolbox.yml
