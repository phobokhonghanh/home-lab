<div align="center">

# 🏠 Home Lab Automation System

![Ansible](https://img.shields.io/badge/Ansible-E00-red?style=flat&logo=ansible&logoColor=white)
![Bash](https://img.shields.io/badge/Bash-4EAA25-green?style=flat&logo=gnu-bash&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420-orange?style=flat&logo=ubuntu&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue?style=flat)

**Transform unused laptops into a resilient, production-ready Kubernetes or Home Lab cluster.**

[Vietnamese Version](README.md) • [Technical Blog](docs/guide-home-lab-setup.md)

</div>

---

## 🚀 Key Features

A minimal, opinionated automation suite designed for the "Laptop-as-a-Server" use case.

- **🔌 Always-On Power**: Hardened systemd configurations to prevent laptops from suspending when
  the lid is closed or during idle periods.
- **🛡️ SSH Hardening**: Automated zero-touch key distribution for the root account, maintaining
  security while ensuring ease of access.
- **⚡ Wireless Persistence**: Low-level NetworkManager hacks to disable power-saving modes on Wi-Fi
  cards, reducing latency.
- **📦 Standardized Provisioning**: "Infrastructure as Code" approach to installing essential
  monitoring (htop, sensors) and dev tools.

## 🛠 Quick Start

### 1. Prerequisites

On your control node, ensure you have Ansible and `sshpass` installed:

```bash
sudo apt update && sudo apt install ansible sshpass -y
```

> [!CAUTION] All target laptops must have `openssh-server` installed before proceeding.

### 2. Configure Inventory

Define your nodes in `cluster/inventory/home-lab.ini`:

```ini
[servers]
node-01 ansible_host=192.168.1.100
node-02 ansible_host=192.168.1.101
```

### 3. Deploy

Run the automation scripts in order:

```bash
# 1. Bootstrap SSH connection (asks for password once)
./cluster/scripts/01-init-connection.sh

# 2. Install essential tools
./cluster/scripts/02-install-requirements.sh

# 3. Apply power management hacks
./cluster/scripts/03-configure-power.sh

# 4. Harden security
./cluster/scripts/04-configure-ssh-security.sh
```

## 🏗 Architecture

The project is structured into three clear layers:

```text
home-lab/
├── cluster/      # 🤖 Ansible-driven cluster management
│   ├── inventory/
│   ├── playbooks/
│   └── scripts/
├── standalone/   # 🛠 Native shell scripts for single-host setup
└── docs/         # 📚 Technical documentation
```

## 📚 Documentation

For deep dives into the technical architecture and scaling strategies:

- [**Engineering Guide: Building a Laptop Cluster**](docs/guide-home-lab-setup.md)
