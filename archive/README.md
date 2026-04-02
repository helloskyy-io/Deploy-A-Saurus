![Logo](frame_002.jpg)

# Welcome to Hello Skyy

The purpose of **Hello Skyy** is To provide a central hub, on decentralized infrastructure, to educate, document, and assemble the information, tools, and collaborative development space needed, for exploring alternatives to big tech companies. We want to offer viable options to mainstream tech solutions and empower individuals to choose freedom and privacy over convenience by exploring web3, blockchain, decentralization, and open source technologies.

- [Learn more about us](https://web.helloskyy.io)
- [Join our Discord](https://discord.io/techdufus)

# FluxEdge Deployment Toolbox

The **FluxEdge Deployment Toolbox** streamlines the configuration of custom container environments and deployment management on FluxEdge using an Ansible framework. This toolbox automates the setup and configuration of various AI and Deep learning applicaitons and models, in a simple easy to use framework that encourages COmmunity involvement in creating and maintaining quick deployments not maintained by the Flux Team. 

Our goal is to enable rapid reproduction of custom work environments, letting data scientists focus on learning AI rather than on technical setup complexities.

## Features

- **Kubernetes .yml files** for overall deployment management. 
- **Bash script installation** of Ansible, a user-friendly "Configuration as Code" tool using YAML.
- **Execution of Ansible plays/tasks/roles** to configure necessary packages, dependencies, and environmnet utilizing miniconda.
- **Rapid project deployment**, this framework can be forked and used for private deployment development for individuals and organizations
## Community and Contributions

These tools are freely available for both private and public use. We encourage you to use this framework to enhance your deployment projects and welcome contributions that benefit the community maintained library of "quick deployments" by creating a method to submit your deployments to the team for inclusion on the platform.

## Getting Started (from here down needs to be revised completely)

Ensure you've met the following prerequisites:

1. Created a project at FluxEdge.
2. Are working in the GUI Terminal in the FluxEdge app.
3. Have chosen the Ubuntu Custom option from the AI menu.

### Initial Setup

Copy/paste the following commands into the FluxEdge GUI terminal and follow the prompts:

```bash
apt update && apt install curl -y
bash <(curl -s https://raw.githubusercontent.com/helloskyy-io/FluxEdge-AI-Toolbox/main/bash/AI_toolbox.sh)
```

### Relaunching the AI Toolbox

After the initial run of FluxEdge AI Toolbox, you can relaunch the Ansible menu with the below command:

```bash
ANSIBLE_CONFIG=/FluxEdge_AI_Toolbox/ansible/ansible.cfg ansible-playbook -i localhost, -c local /FluxEdge_AI_Toolbox/ansible/playbooks/AI_Toolbox.yml
```









Public market

