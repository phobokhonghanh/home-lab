<div align="center">

# 🏠 Home Lab Automation System

![Ansible](https://img.shields.io/badge/Ansible-E00-red?style=flat&logo=ansible&logoColor=white)
![Bash](https://img.shields.io/badge/Bash-4EAA25-green?style=flat&logo=gnu-bash&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420-orange?style=flat&logo=ubuntu&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue?style=flat)

**Biến những chiếc laptop cũ thành một cụm Kubernetes hoặc Home Lab mạnh mẽ, ổn định.**

[English Version](README.en.md) • [Blog Kỹ thuật](docs/guide-home-lab-setup.md)

</div>

---

## 🚀 Tính năng nổi bật

Một bộ công cụ tự động hóa tối giản, thiết kế riêng cho trường hợp sử dụng "Laptop-as-a-Server".

- **🔌 Nguồn điện liên tục**: Cấu hình systemd chuyên sâu để ngăn laptop chuyển sang chế độ ngủ
  (suspend) khi gập máy.
- **🛡️ Bảo mật SSH**: Tự động hóa việc phân phối SSH Key cho tài khoản root, đảm bảo an toàn nhưng
  vẫn tiện dụng.
- **⚡ Kết nối ổn định**: Can thiệp cấp thấp vào NetworkManager để tắt chế độ tiết kiệm điện của
  card Wi-Fi, giảm độ trễ (latency).
- **📦 Cài đặt chuẩn hóa**: Tiếp cận theo hướng "Infrastructure as Code" để cài đặt các công cụ giám
  sát (htop, sensors) và dev tools.

## 🛠 Bắt đầu nhanh

### 1. Chuẩn bị

Trên máy quản lý (máy chạy lệnh), bạn cần cài Ansible và `sshpass`:

```bash
sudo apt update && sudo apt install ansible sshpass -y
```

> [!CAUTION] Tất cả các laptop đích (Managed Nodes) **bắt buộc** phải được cài `openssh-server`
> trước khi thực hiện.

### 2. Cấu hình Inventory

Khai báo các máy của bạn vào file `cluster/inventory/home-lab.ini`:

```ini
[servers]
node-01 ansible_host=192.168.1.100
node-02 ansible_host=192.168.1.101
```

### 3. Triển khai

Chạy các script tự động hóa theo thứ tự:

```bash
# 1. Khởi tạo kết nối SSH (nhập password user 1 lần duy nhất)
./cluster/scripts/01-init-connection.sh

# 2. Cài đặt công cụ cần thiết
./cluster/scripts/02-install-requirements.sh

# 3. Tối ưu hóa nguồn điện (Chống ngủ)
./cluster/scripts/03-configure-power.sh

# 4. Gia cố bảo mật
./cluster/scripts/04-configure-ssh-security.sh
```

## 🏗 Kiến trúc

Dự án được chia thành 3 tầng rõ ràng:

```text
home-lab/
├── cluster/      # 🤖 Quản lý cụm tập trung bằng Ansible
│   ├── inventory/
│   ├── playbooks/
│   └── scripts/
├── standalone/   # 🛠 Script chạy lẻ trên từng máy (Cứu hộ)
└── docs/         # 📚 Tài liệu kỹ thuật
```

## 📚 Tài liệu

Để hiểu sâu hơn về kiến trúc kỹ thuật và chiến lược mở rộng:

- [**Bài viết kỹ thuật: Xây dựng Cluster từ Laptop**](docs/guide-home-lab-setup.md)
