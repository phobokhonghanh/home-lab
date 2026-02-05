<div align="center">

# 🏠 Home Lab Automation System

![Ansible](https://img.shields.io/badge/Ansible-E00-red?style=flat&logo=ansible&logoColor=white)
![Bash](https://img.shields.io/badge/Bash-4EAA25-green?style=flat&logo=gnu-bash&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420-orange?style=flat&logo=ubuntu&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED-blue?style=flat&logo=docker&logoColor=white)

**Automated system to transform old laptops into a resilient, production-ready Cloud Cluster.**

[Vietnamese Version](README.md) • [Technical Guide](docs/guide-home-lab-setup.md)

</div>

---
## Overview

This project provides a comprehensive automation suite for setting up, managing, and maintaining a home laboratory infrastructure. It adopts a **modular architecture** where every component (OS, Docker, Swarm, Git) operates independently, allowing for flexible and scalable infrastructure management.

## Prerequisites

- **Control Node**: Linux machine or WSL2 with Ansible installed (run `./setup_env.sh` to setup).
- **Target Nodes**: Debian-based Linux distribution (Ubuntu 20.04/22.04 LTS recommended).
- **Network**: All nodes must be reachable via SSH from the control node.

## Project Structure

```bash
home-lab/
├── ansible.cfg                 # Ansible global configuration
├── setup_env.sh                # Control node setup script (installs Ansible)
├── cluster/
│   ├── inventory/              # Inventory files
│   │   ├── init-home-lab.ini   # For initial connection (Bootstrap)
│   │   └── home-lab.ini        # For main operations (Root access)
│   ├── scripts/                # Wrapper scripts (Entry points)
│   │   ├── os/                 # OS configuration & status
│   │   ├── docker/             # Docker management
│   │   ├── swarm/              # Swarm cluster management
│   │   └── git/                # Git repository management
│   └── playbooks/              # Ansible Logic
│       ├── os/
│       ├── docker/
│       ├── swarm/
│       └── git/
```

## Inventory Setup

This project uses two distinct inventory files located in `cluster/inventory/`. You must configure both before starting.

### 1. Bootstrap Inventory (`init-home-lab.ini`)
Used **only** for the connection initialization script (`init_connection.sh`).

- **Purpose**: Defines initial connection details (user, password prompt) to establish SSH keys.
- **Key Groups**:
  - `[servers]`: Define all nodes with their initial non-root username (e.g., `ansible_user=ubuntu`).
  - `[os]`: Helper group to target nodes for bootstrapping.

**Example**:
```ini
[servers]
node01 ansible_host=192.168.1.10 ansible_user=ubuntu
node02 ansible_host=192.168.1.11 ansible_user=pi

[os]
node01
node02
```

### 2. Main Inventory (`home-lab.ini`)
Used for **all** other operations (install, configure, deploy).

- **Purpose**: Defines the cluster state for Ansible after SSH keys are set up. Connects as `root`.
- **Key Groups**:
  - `[os]`: Nodes receiving OS configurations (libs, ssh, power).
  - `[docker]`: Nodes where Docker Engine will be installed.
  - `[manager]`: The single node acting as Swarm Manager.
  - `[add_workers]`: Worker nodes intended to be added to the Swarm.
  - `[remove_workers]`: Nodes targeted for removal from the Swarm.
  - `[git]`: Nodes that will pull Git repositories.

**Example**:
```ini
[servers]
node01 ansible_host=192.168.1.10
node02 ansible_host=192.168.1.11
node03 ansible_host=192.168.1.12

[os]
node01
node02

[git]
node01
node02

[docker]
node01
node02

[manager]
node03

[add_workers]
node01
node02

[remove_workers]
node01

[all:vars]
ansible_user=root
```

## Usage & Scripts Guide

All operations are executed via shell script wrappers in `cluster/scripts/`. These scripts handle the complexity of Ansible commands for you.

### Targeting Mechanism

Every script accepts an optional `TARGET` argument.

**1. No Target (Default Behavior)**
If run without arguments, the script executes on the specific group defined in `home-lab.ini`.
```bash
./cluster/scripts/docker/install.sh
# Runs on all hosts in the [docker] inventory group
```

**2. With Target (Specific Control)**
You can override the default group to run on specific nodes or custom groups.
```bash
# Run on a single node
./cluster/scripts/docker/install.sh node01

# Run on multiple nodes (comma-separated)
./cluster/scripts/docker/install.sh "node01,node02"

# Run on a different inventory group
./cluster/scripts/docker/install.sh new_nodes
```

### Complete Script Reference

#### OS Module
Configuration and base setup for nodes.

| Script | Default Group | Description |
|--------|---------------|-------------|
| `./cluster/scripts/os/init_connection.sh [target]` | `Servers in init-home-lab.ini` | **Bootstrap**: Generates SSH keys and copies them to targets. Requires password. |
| `./cluster/scripts/os/install_libs.sh [target]` | `[os]` | Installs essential system libraries (curl, git, python3, htop, etc.). |
| `./cluster/scripts/os/configure_ssh.sh [target]` | `[os]` | Hardens SSH: Disables password auth, disables root login. |
| `./cluster/scripts/os/configure_power.sh [target]` | `[os]` | Configures power management (prevents laptop sleep on lid close). |
| `./cluster/scripts/os/rollback.sh [target]` | `[os]` | Reverts OS configurations to defaults. |
| `./cluster/scripts/os/status.sh [target]` | `[os]` | Checks OS status (packages, timezone, config). |

#### Docker Module
Management of Docker Engine.

| Script | Default Group | Description |
|--------|---------------|-------------|
| `./cluster/scripts/docker/install.sh [target]` | `[docker]` | Installs Docker Engine, CLI, and Compose plugin. |
| `./cluster/scripts/docker/clean.sh [target]` | `[docker]` | **Destructive**: Prunes unused system resources (containers, images, vols). |
| `./cluster/scripts/docker/restart.sh [target]` | `[docker]` | Restarts the Docker service. |
| `./cluster/scripts/docker/uninstall.sh [target]` | `[docker]` | **Destructive**: Completely removes Docker and all data. |
| `./cluster/scripts/docker/status.sh [target]` | `[docker]` | Checks Docker version and resource usage. |

#### Swarm Module
Cluster orchestration management.

| Script | Default Group | Description |
|--------|---------------|-------------|
| `./cluster/scripts/swarm/init.sh` | `[manager]` | Initializes the Swarm Manager (Run this first). |
| `./cluster/scripts/swarm/add.sh [target]` | `[add_workers]` | Defines worker nodes relative to the manager and adds them to the cluster. |
| `./cluster/scripts/swarm/remove.sh [target]` | `[remove_workers]` | **Destructive**: Forces nodes to leave swarm and removes them from manager list. |
| `./cluster/scripts/swarm/status.sh` | `[manager]` | Displays full cluster status (nodes, services, networks). |

#### Git Module
Repository management.

| Script | Default Group | Description |
|--------|---------------|-------------|
| `./cluster/scripts/git/pull.sh [target]` | `[git]` | Clones or updates configured Git repositories on target nodes. |
| `./cluster/scripts/git/status.sh [target]` | `[git]` | Checks status of cloned repositories (branch, commit, diffs). |

#### Spark Module
Deploy Apache Spark Cluster on Docker Swarm.

| Script | Default Group | Description |
|--------|---------------|-------------|
| `./cluster/scripts/spark/deploy.sh` | `[spark_managers]` | Deploys Spark stack (master, worker, history server, pyjob). |
| `./cluster/scripts/spark/remove.sh` | `[spark_managers]` | **Destructive**: Removes Spark stack and cleans Docker resources. |
| `./cluster/scripts/spark/build.sh [target]` | `[spark_clusters]` | Builds custom Docker images (pyjob, spark-custom). |
| `./cluster/scripts/spark/status.sh` | `[spark_managers]` | Checks Spark stack status (services, tasks). |

**Inventory Groups for Spark:**
- `[spark_managers]`: Node running Spark Master and History Server.
- `[spark_workers]`: Nodes running Spark Workers.
- `[spark_clusters]`: All Spark nodes (managers + workers combined).

**Stack Path:** `cluster/stacks/spark/` contains compose file and configs.

## License

Distributed under the MIT License. See `LICENSE` for more information.
