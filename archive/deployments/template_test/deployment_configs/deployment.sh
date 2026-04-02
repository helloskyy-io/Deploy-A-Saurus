#!/bin/bash

# display logo
echo ""
echo ""
echo ".#####                        #     #"              
echo "#     # #    # #   # #   #    ##    # ###### ##### " 
echo "#       #   #   # #   # #     # #   # #        #   "
echo ".#####  ####     #     #      #  #  # #####    #   "
echo ".     # #  #     #     #      #   # # #        #   "
echo "#     # #   #    #     #      #    ## #        #   "
echo ".#####  #    #   #     #      #     # ######   #   "
echo ""
echo "System activated..."

# Install Ansible
echo ""
echo "Installing Ansible..."
apt-get install -y ansible python3-apt

# Check if the mount path exists
echo ""
echo "Checking for external mount path..."
if [ ! -d "/mnt/data" ]; then
    echo "Error: Mount path /mnt/data does not exist. Deployment cannot continue." | tee /tmp/setup-failed
    exit 1
fi

# Clone Ansible repository
if [ ! -d "/mnt/data/FluxEdge-Deployment-Toolbox" ]; then
    echo ""
    echo "Cloning FluxEdge-Deployment-Toolbox..."
    git clone https://github.com/helloskyy-io/FluxEdge-Deployment-Toolbox /mnt/data
else
    echo "Repository already exists in /mnt/data. Pulling latest changes..."
    cd /mnt/data/FluxEdge-Deployment-Toolbox && git pull
fi

# Display completion message
echo ""
echo "Initial configuration completed successfully"

# # Launch Ansible playbook
# echo ""
# echo "Launching Ansible playbook..."
# sleep 2
# ANSIBLE_CONFIG=/FluxEdge_AI_Toolbox/ansible/ansible.cfg ansible-playbook -i localhost, -c local /FluxEdge_AI_Toolbox/ansible/playbooks/AI_Toolbox.yml
