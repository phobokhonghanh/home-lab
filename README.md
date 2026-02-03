<div align="center">

# 🏠 Home Lab Automation System

![Ansible](https://img.shields.io/badge/Ansible-E00-red?style=flat&logo=ansible&logoColor=white)
![Bash](https://img.shields.io/badge/Bash-4EAA25-green?style=flat&logo=gnu-bash&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420-orange?style=flat&logo=ubuntu&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED-blue?style=flat&logo=docker&logoColor=white)

**Hệ thống tự động hóa biến cụm Laptop cũ thành Cloud Cluster mạnh mẽ.**

[English Version](README.en.md) • [Blog Kỹ thuật](docs/guide-home-lab-setup.md)

</div>

---

## 🏗 Kiến trúc Dự án (Modular Monolithic)

Dự án được tổ chức theo mô hình **Modular Monolithic** với Ansible Roles, giúp dễ dàng mở rộng và bảo trì.

```text
cluster/
├── inventory/          # 📋 Danh sách máy chủ (Hosts)
├── vars/               # 💾 Biến cấu hình toàn cục (Credentials, Repos)
├── roles/              # 🧱 Modules (Logic chính)
│   ├── os/             # -> Cấu hình Hệ điều hành (SSH, Power, Libs)
│   ├── docker/         # -> Quản lý Docker Engine
│   ├── swarm/          # -> Quản lý Docker Swarm Cluster
│   └── git/            # -> Quản lý Source Code
├── playbooks/          # 🎬 Kịch bản điều phối (Gọi Roles)
└── scripts/            # ⚡ Scripts thực thi nhanh (Wrapper)
```

## 🚀 Quick Run (Tóm tắt)

Cấp quyền thực thi cho scripts trước khi chạy:
```bash
chmod +x cluster/scripts/*/*.sh
```

**1. Khởi tạo (Dùng `init-home-lab.ini`)**
*   **Init SSH**: `./cluster/scripts/os/init_connection.sh` (Bước duy nhất dùng password để copy SSH key)

**2. Cài đặt & Vận hành (Dùng `home-lab.ini`)**
*   **Install Libs**: `./cluster/scripts/os/install_libs.sh os` (Cài đặt môi trường OS - chạy qua SSH Key)
*   **Install Docker**: `./cluster/scripts/docker/install.sh` (Cài Docker)
*   **Setup Swarm**: `./cluster/scripts/swarm/setup.sh` (Dựng Cluster)
*   **Deploy Code**: `./cluster/scripts/git/pull_code.sh` (Pull code)

## 🛠 Hướng dẫn Cài đặt Chi tiết

Hãy làm theo từng bước dưới đây để thiết lập hệ thống từ con số 0.

### 1. Chuẩn bị (Prerequisites)

Trên máy của bạn (Control Node), cài đặt các công cụ cần thiết:
```bash
sudo apt update && sudo apt install ansible sshpass -y
```

Khai báo các máy vào `cluster/inventory/init-home-lab.ini` (dành cho cài đặt ban đầu):
```ini
[servers]
node00 ansible_host=... # Control Node
node01 ansible_host=...

[os]
node01 # Chỉ chạy cấu hình OS trên các node này
```

Và `cluster/inventory/home-lab.ini` (dành cho tất cả các việc còn lại):
```ini
[os]
node01 # Cấu hình OS

[docker]
node01 # Cài Docker

[manager]
node00
[workers]
node01
```

---

### 2. Module OS: Cấu hình Hệ thống
Module này giúp chuẩn hóa môi trường Ubuntu server.

#### Bước 2.1: Khởi tạo kết nối (Bootstrap)
Script này sẽ copy SSH Key từ máy bạn lên toàn bộ server. Bạn chỉ cần nhập mật khẩu root 1 lần duy nhất.
- **Script**: `./cluster/scripts/os/init_connection.sh`
- **Playbook**: `playbooks/os/bootstrap.yml`

#### Bước 2.2: Cài đặt thư viện (Libs)
Cài đặt các gói cơ bản: `curl`, `git`, `htop`, `vim`, `net-tools`, `sensors`... và thiết lập Timezone.
- **Script**: `./cluster/scripts/os/install_libs.sh`
- **Playbook**: `playbooks/os/setup.yml` (Tags: `libs`)

#### Bước 2.3: Tối ưu nguồn điện (Power)
Ngăn laptop ngủ khi gập máy (Lid Switch Ignore) và tắt chế độ tiết kiệm điện Wifi để giảm độ trễ.
- **Script**: `./cluster/scripts/os/configure_power.sh`
- **Playbook**: `playbooks/os/setup.yml` (Tags: `power`)

#### Bước 2.4: Bảo mật SSH (Security)
Tắt login mật khẩu (`PasswordAuthentication no`), chỉ cho phép SSH Key để đảm bảo an toàn tuyệt đối. (Trong môi trường Home Lab, bạn có thể bật lại nếu muốn tiện lợi).
- **Script**: `./cluster/scripts/os/configure_ssh.sh`
- **Playbook**: `playbooks/os/setup.yml` (Tags: `ssh`)

---

### 3. Module Docker: Quản lý Container
Module này tự động cài đặt Docker Engine bản ổn định nhất.

#### Cài đặt Docker
Tự động thêm repos, GPG key và cài đặt Docker CE + Docker Compose.
- **Script**: `./cluster/scripts/docker/install.sh`
- **Playbook**: `playbooks/docker/setup.yml`

#### Gỡ cài đặt / Dọn dẹp
- **Gỡ bỏ Docker**: `./cluster/scripts/docker/uninstall.sh`
- **Dọn dẹp (Prune)**: `./cluster/scripts/docker/clean.sh` (Xóa container/image rác)

---

### 4. Module Swarm: Cluster Orchestration
Biến các máy lẻ thành một cụm thống nhất.

#### Khởi tạo Cluster
Script này sẽ tự động:
1.  Khởi tạo Swarm trên node `manager`.
2.  Lấy Join Token.
3.  Join các node `workers` vào cluster.
- **Script**: `./cluster/scripts/swarm/setup.sh`
- **Playbook**: `playbooks/swarm/setup.yml`

#### Rời Cluster
Cho các node rời khỏi Swarm (Force Leave).
- **Script**: `./cluster/scripts/swarm/leave.sh`

---

### 5. Module Git: Quản lý Source Code
Kéo code từ các Repository về server (ví dụ: deploy app).

1.  Cấu hình danh sách Repo tại: `cluster/vars/git_repos.yaml`
2.  Cấu hình Token tại: `cluster/vars/git_credentials.yaml`
3.  **Chạy Script**: `./cluster/scripts/git/pull_code.sh`

---

## ❓ Câu hỏi thường gặp

**Q: Tôi có thể chạy thủ công Playbook không?**
A: Hoàn toàn được. Script chỉ là wrapper. Ví dụ:
```bash
ansible-playbook -i cluster/inventory/init-home-lab.ini cluster/playbooks/os/setup.yml --tags libs
```

**Q: Làm sao để thêm server mới?**
A: Thêm IP vào `inventory/init-home-lab.ini` và chạy lại các script setup. Sau đó thêm vào `inventory/home-lab.ini` để join vào Swarm.
