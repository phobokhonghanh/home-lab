<div align="center">

# 🏠 Home Lab Automation System

![Ansible](https://img.shields.io/badge/Ansible-E00-red?style=flat&logo=ansible&logoColor=white)
![Bash](https://img.shields.io/badge/Bash-4EAA25-green?style=flat&logo=gnu-bash&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420-orange?style=flat&logo=ubuntu&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED-blue?style=flat&logo=docker&logoColor=white)

**Automated system to transform old laptops into a resilient, production-ready Cloud Cluster.**

[Vietnamese Version](README.md) • [Technical Blog](docs/guide-home-lab-setup.md)

</div>

---

## 🏗 Project Architecture (Modular Monolithic)

The project follows a **Modular Monolithic** structure using Ansible Roles, ensuring scalability and maintainability.

```text
cluster/
├── inventory/          # 📋 Server List (Hosts)
├── vars/               # 💾 Global Configs (Credentials, Repos)
├── roles/              # 🧱 Modules (Core Logic)
│   ├── os/             # -> OS Configuration (SSH, Power, Libs)
│   ├── docker/         # -> Docker Engine Management
│   ├── swarm/          # -> Docker Swarm Cluster Management
│   └── git/            # -> Source Code Management
├── playbooks/          # 🎬 Orchestration (Calls Roles)
└── scripts/            # ⚡ Wrapper Scripts (Quick Execution)
```

## 🚀 Quick Run (Summary)

Grant execution permissions scripts before running:
```bash
chmod +x cluster/scripts/*/*.sh
```

**1. Initialization (Uses `init-home-lab.ini`)**
*   **Init SSH**: `./cluster/scripts/os/init_connection.sh` (Only step using password to copy SSH keys)

**2. Setup & Operations (Uses `home-lab.ini`)**
*   **Install Libs**: `./cluster/scripts/os/install_libs.sh os` (OS Environment Setup - uses SSH Key)
*   **Install Docker**: `./cluster/scripts/docker/install.sh` (Install Docker)
*   **Setup Swarm**: `./cluster/scripts/swarm/setup.sh` (Cluster Setup)
*   **Deploy Code**: `./cluster/scripts/git/pull_code.sh` (Pull code)

## 🛠 Detailed Installation Guide

Follow these steps to set up your system from scratch.

### 1. Prerequisites

On your Control Node, run the following script to automatically install the latest Ansible and necessary dependencies:

```bash
# Grant permission and run the setup script
chmod +x setup_env.sh
./setup_env.sh

# After completion, refresh your terminal
source ~/.bashrc
```

> **Why this script?** It ensures you have **Ansible Core 2.14+**, which is required to manage servers running Ubuntu 24.04 (Python 3.12).

Define your servers in `cluster/inventory/init-home-lab.ini` (for initial setup):
```ini
[servers]
node00 ansible_host=... # Control Node
node01 ansible_host=...

[os]
node01 # Only run OS config on these nodes
```

And `cluster/inventory/home-lab.ini` (for everything else):
```ini
[os]
node01 # OS Config

[docker]
node01 # Install Docker

[manager]
node00
[workers]
node01
```

---

### 2. OS Module: System Configuration
Standardizes the Ubuntu server environment.

#### Step 2.1: Bootstrap Connection
Copies your SSH Key to all servers. You only need to enter the root password once.
- **Script**: `./cluster/scripts/os/init_connection.sh`
- **Playbook**: `playbooks/os/bootstrap.yml`

#### Step 2.2: Install Libraries (Libs)
Installs basic packages: `curl`, `git`, `htop`, `vim`, `net-tools`, `sensors`... and sets Timezone.
- **Script**: `./cluster/scripts/os/install_libs.sh`
- **Playbook**: `playbooks/os/setup.yml` (Tags: `libs`)

#### Step 2.3: Power Optimization
Prevents laptop suspension when lid is closed and disables Wi-Fi power saving to reduce latency.
- **Script**: `./cluster/scripts/os/configure_power.sh`
- **Playbook**: `playbooks/os/setup.yml` (Tags: `power`)

#### Step 2.4: SSH Security
Disables password login (`PasswordAuthentication no`), enforcing SSH Key-only access for security. (For Home Lab, you can re-enable this for convenience).
- **Script**: `./cluster/scripts/os/configure_ssh.sh`
- **Playbook**: `playbooks/os/setup.yml` (Tags: `ssh`)

---

### 3. Docker Module: Container Management
Automates the installation of the stable Docker Engine.

#### Install Docker
Adds repos, GPG key, and installs Docker CE + Docker Compose automatically.
- **Script**: `./cluster/scripts/docker/install.sh`
- **Playbook**: `playbooks/docker/setup.yml`

#### Uninstall / Cleanup
- **Uninstall**: `./cluster/scripts/docker/uninstall.sh`
- **Cleanup (Prune)**: `./cluster/scripts/docker/clean.sh` (Removes unused containers/images)

---

### 4. Swarm Module: Cluster Orchestration
Turns individual nodes into a unified cluster.

#### Initialize Cluster
This script automatically:
1.  Initializes Swarm on the `manager` node.
2.  Retrieves the Join Token.
3.  Joins `workers` to the cluster.
- **Script**: `./cluster/scripts/swarm/setup.sh`
- **Playbook**: `playbooks/swarm/setup.yml`

#### Leave Cluster
Forces nodes to leave the Swarm.
- **Script**: `./cluster/scripts/swarm/leave.sh`

---

### 5. Git Module: Source Code Management
Pulls code from Repositories to the server (e.g., app deployment).

1.  Configure Repos in: `cluster/vars/git_repos.yaml`
2.  Configure Token in: `cluster/vars/git_credentials.yaml`
3.  **Run Script**: `./cluster/scripts/git/pull_code.sh`

---

## ❓ FAQ

**Q: Can I run Playbooks manually?**
A: Absolutely. Scripts are just wrappers. Example:
```bash
ansible-playbook -i cluster/inventory/init-home-lab.ini cluster/playbooks/os/setup.yml --tags libs
```

**Q: How do I add a new server?**
A: Add IP to `inventory/init-home-lab.ini` and re-run setup scripts. Then add to `inventory/home-lab.ini` to join Swarm.
