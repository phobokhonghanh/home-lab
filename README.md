<div align="center">

# 🏠 Hệ Thống Tự Động Hóa Home Lab

![Ansible](https://img.shields.io/badge/Ansible-E00-red?style=flat&logo=ansible&logoColor=white)
![Bash](https://img.shields.io/badge/Bash-4EAA25-green?style=flat&logo=gnu-bash&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420-orange?style=flat&logo=ubuntu&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED-blue?style=flat&logo=docker&logoColor=white)

**Hệ thống tự động hóa giúp biến các laptop cũ thành một Cloud Cluster mạnh mẽ, sẵn sàng cho môi trường production.**

[English Version](README.en.md) • [Hướng Dẫn Kỹ Thuật](docs/guide-home-lab-setup.md)

</div>

---
## Tổng quan

Dự án này cung cấp một bộ công cụ tự động hóa toàn diện để thiết lập, quản lý và duy trì hạ tầng home lab. Hệ thống áp dụng **kiến trúc mô-đun (modular architecture)**, trong đó mọi thành phần (OS, Docker, Swarm, Git, Spark, Notebook) hoạt động độc lập. Đặc biệt, hệ thống xử lý triệt để các vấn đề mạng phức tạp (như MTU mismatch trên Tailscale) và đảm bảo quy trình build Docker đồng bộ, mạnh mẽ.

## Yêu cầu tiên quyết

- **Control Node**: Máy Linux hoặc WSL2 đã cài đặt Ansible (chạy `./setup_env.sh` để cài đặt).
- **Target Nodes**: Các máy cần quản lý chạy Linux (khuyên dùng Ubuntu 20.04/22.04 LTS).
- **Mạng**: Tất cả các node phải có thể truy cập được qua SSH từ control node.

## Cấu trúc dự án

```bash
home-lab/
├── ansible.cfg                 # Cấu hình Ansible toàn cục
├── setup_env.sh                # Script cài đặt môi trường trên Control node
├── cluster/
│   ├── inventory/              # Các file chứa thông tin máy chủ (Inventory)
│   │   ├── init-home-lab.ini   # Dùng cho kết nối lần đầu (Bootstrap)
│   │   └── home-lab.ini        # Dùng cho các vận hành chính (Quyền Root)
│   ├── scripts/                # Các script wrapper (Điểm truy cập)
│   │   ├── os/                 # Cấu hình & trạng thái OS
│   │   ├── docker/             # Quản lý Docker
│   │   ├── swarm/              # Quản lý Swarm cluster
│   │   └── git/                # Quản lý Git repository
│   └── playbooks/              # Logic xử lý của Ansible
│       ├── os/
│       ├── docker/
│       ├── swarm/
│       └── git/
```

## Cấu hình Inventory

Dự án này sử dụng 2 file inventory riêng biệt nằm trong `cluster/inventory/`. Bạn cần cấu hình cả hai trước khi bắt đầu.

### 1. Inventory Khởi tạo (`init-home-lab.ini`)
Chỉ được sử dụng **duy nhất** cho script khởi tạo kết nối (`init_connection.sh`).

- **Mục đích**: Khai báo thông tin kết nối ban đầu (user, mật khẩu) để thiết lập SSH keys.
- **Các nhóm chính**:
  - `[servers]`: Khai báo tất cả các node với user ban đầu (ví dụ: `ansible_user=ubuntu`).
  - `[os]`: Nhóm phụ để chọn các node cần chạy bootstrap.

**Ví dụ**:
```ini
[servers]
node01 ansible_host=192.168.1.10 ansible_user=ubuntu
node02 ansible_host=192.168.1.11 ansible_user=pi

[os]
node01
node02
```

### 2. Inventory Chính (`home-lab.ini`)
Được sử dụng cho **tất cả** các hoạt động khác (cài đặt, cấu hình, triển khai).

- **Mục đích**: Định nghĩa trạng thái cluster cho Ansible sau khi SSH keys đã được thiết lập. Kết nối dưới quyền `root`.
- **Các nhóm chính**:
  - `[os]`: Các node sẽ được cấu hình OS (thư viện, ssh, nguồn điện).
  - `[docker]`: Các node sẽ được cài đặt Docker Engine.
  - `[manager]`: Node duy nhất đóng vai trò Swarm Manager.
  - `[add_workers]`: Các worker node dự kiến sẽ được thêm vào Swarm.
  - `[remove_workers]`: Các node mục tiêu cần xóa khỏi Swarm.
  - `[git]`: Các node sẽ thực hiện pull Git repositories.

**Ví dụ**:
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

## Hướng dẫn Sử dụng & Scripts

Mọi thao tác được thực hiện thông qua các shell script wrapper trong `cluster/scripts/`. Các script này giúp xử lý sự phức tạp của các lệnh Ansible thay cho bạn.

### Cơ chế chọn mục tiêu (Target)

Mọi script đều chấp nhận tham số tùy chọn `TARGET`.

**1. Không có Target (Mặc định)**
Nếu chạy không có tham số, script sẽ thực thi trên nhóm mặc định được định nghĩa trong `home-lab.ini`.
```bash
./cluster/scripts/docker/install.sh
# Chạy trên tất cả các host trong nhóm [docker]
```

**2. Có Target (Điều khiển cụ thể)**
Bạn có thể ghi đè nhóm mặc định để chạy trên node cụ thể hoặc nhóm tùy chỉnh.
```bash
# Chạy trên một node đơn lẻ
./cluster/scripts/docker/install.sh node01

# Chạy trên nhiều node (cách nhau bởi dấu phẩy)
./cluster/scripts/docker/install.sh "node01,node02"

# Chạy trên một nhóm inventory khác
./cluster/scripts/docker/install.sh new_nodes
```

### Danh sách Script đầy đủ

#### Module OS
Cấu hình và thiết lập cơ bản cho các node.

| Script | Nhóm Mặc định | Mô tả |
|--------|---------------|-------|
| `./cluster/scripts/os/init_connection.sh [target]` | `Servers trong init-home-lab.ini` | **Bootstrap**: Tạo và copy SSH key lên target. Yêu cầu nhập mật khẩu. |
| `./cluster/scripts/os/install_libs.sh [target]` | `[os]` | Cài đặt thư viện hệ thống cần thiết (curl, git, python3, htop, v.v.). |
| `./cluster/scripts/os/configure_ssh.sh [target]` | `[os]` | Bảo mật SSH: Tắt đăng nhập mật khẩu & tắt root login trực tiếp. |
| `./cluster/scripts/os/configure_power.sh [target]` | `[os]` | Cấu hình quản lý nguồn (ngăn laptop ngủ khi gập máy). |
| `./cluster/scripts/os/rollback.sh [target]` | `[os]` | Khôi phục cấu hình OS về mặc định. |
| `./cluster/scripts/os/status.sh [target]` | `[os]` | Kiểm tra trạng thái OS (packages, múi giờ, config). |

#### Module Docker
Quản lý Docker Engine.

| Script | Nhóm Mặc định | Mô tả |
|--------|---------------|-------|
| `./cluster/scripts/docker/install.sh [target]` | `[docker]` | Cài đặt Docker Engine, CLI, và Compose plugin. |
| `./cluster/scripts/docker/clean.sh [target]` | `[docker]` | **Nguy hiểm**: Dọn dẹp tài nguyên hệ thống không dùng (containers, images, vols). |
| `./cluster/scripts/docker/restart.sh [target]` | `[docker]` | Khởi động lại dịch vụ Docker. |
| `./cluster/scripts/docker/uninstall.sh [target]` | `[docker]` | **Nguy hiểm**: Gỡ bỏ hoàn toàn Docker và toàn bộ dữ liệu. |
| `./cluster/scripts/docker/status.sh [target]` | `[docker]` | Kiểm tra phiên bản Docker và tài nguyên sử dụng. |

#### Module Swarm
Quản lý điều phối Cluster.

| Script | Nhóm Mặc định | Mô tả |
|--------|---------------|-------|
| `./cluster/scripts/swarm/init.sh` | `[manager]` | Khởi tạo Swarm Manager (Chạy cái này đầu tiên). |
| `./cluster/scripts/swarm/add.sh [target]` | `[add_workers]` | Thêm các worker node vào cluster (dựa trên token từ manager). |
| `./cluster/scripts/swarm/remove.sh [target]` | `[remove_workers]` | **Nguy hiểm**: Buộc node rời khỏi swarm và xóa khỏi danh sách quản lý. |
| `./cluster/scripts/swarm/status.sh` | `[manager]` | Hiển thị trạng thái toàn bộ cluster (nodes, services, networks). |

#### Module Git
Quản lý Source Code Repository.

| Script | Nhóm Mặc định | Mô tả |
|--------|---------------|-------|
| `./cluster/scripts/git/pull.sh [target]` | `[git]` | Clone hoặc cập nhật Git repositories đã cấu hình trên target nodes. |
| `./cluster/scripts/git/status.sh [target]` | `[git]` | Kiểm tra trạng thái repositories (nhánh, commit, thay đổi). |

#### Module Spark
Triển khai Apache Spark Cluster trên Docker Swarm.

| Script | Nhóm Mặc định | Mô tả |
|--------|---------------|-------|
| `./cluster/scripts/spark/deploy.sh` | `[spark_managers]` | Triển khai Spark stack (master, worker, history server, pyjob). |
| `./cluster/scripts/spark/remove.sh` | `[spark_managers]` | **Nguy hiểm**: Xóa Spark stack và dọn dẹp Docker resources. |
| `./cluster/scripts/spark/build.sh [target]` | `[spark_clusters]` | Build custom Docker images (pyjob, spark-custom). |
| `./cluster/scripts/spark/status.sh` | `[spark_managers]` | Kiểm tra trạng thái Spark stack (services, tasks). |
| `./cluster/scripts/spark/clean.sh` | `[spark_clusters]` | **Nguy hiểm**: Xóa stack, toàn bộ file dữ liệu và prune images trên toàn cluster. |

#### Module Notebook
Triển khai Jupyter Lab trên Docker Swarm.

| Script | Nhóm Mặc định | Mô tả |
|--------|---------------|-------|
| `./cluster/scripts/notebook/deploy.sh` | `[manager]` | Triển khai Notebook stack. |
| `./cluster/scripts/notebook/build.sh` | `[manager]` | Build Jupyter Lab Docker image trên các node. |
| `./cluster/scripts/notebook/remove.sh` | `[manager]` | Xóa Notebook stack. |
| `./cluster/scripts/notebook/status.sh` | `[manager]` | Kiểm tra trạng thái Notebook stack (services, tasks). |

**Inventory Groups cho Spark:**
- `[spark_managers]`: Node chạy Spark Master và History Server.
- `[spark_workers]`: Các node chạy Spark Worker.
- `[spark_clusters]`: Tất cả Spark nodes (kết hợp managers + workers).

**Stack Path:** `cluster/stacks/spark/` chứa compose file và configs.

**Inventory Groups cho Notebook:**
- `[notebook_managers]`: Node được ưu tiên để chạy Jupyter Lab service.

**Stack Path:** `cluster/stacks/notebook/` chứa compose file và configs.
221:
222: ## Các tính năng Build nâng cao
223:
224: Hệ thống tích hợp các cơ chế build thông minh để vượt qua các hạn chế thường gặp trong môi trường lab:
225:
226: - **Xử lý MTU (Tailscale/VPN)**: Sử dụng `--network host` trong quá trình build Docker để tránh rớt gói tin HTTPS lớn khi MTU của mạng ảo (1280) thấp hơn MTU mặc định của Docker (1500).
227: - **Build đồng bộ**: Cả Spark và Notebook đều sử dụng chung một Dockerfile đa tầng (Multi-stage) tại `repo_process/`, đảm bảo tính nhất quán về thư viện và môi trường.
228: - **Tối ưu hóa Layer**: Sử dụng `bitnamilegacy/spark` làm base layer để tránh việc download Spark binaries từ internet, giảm thiểu lỗi connection timeout.
229: - **Quản lý Dependency**: Tự động nâng cấp `pip`, `setuptools`, `wheel` và cài đặt sẵn các build-dependencies (`python-dateutil`) để đảm bảo cài đặt gói `home-lab` ở chế độ editable (`-e .`) luôn thành công.

## Phát triển (Development)

Dự án này sử dụng `pre-commit` để đảm bảo chất lượng code và tuân thủ các quy tắc format.

### Cài đặt và Sử dụng

1. **Cài đặt pre-commit**:
   ```bash
   pip install pre-commit
   ```

2. **Thiết lập hooks**:
   ```bash
   pre-commit install
   ```

3. **Chạy thủ công trên tất cả các file**:
   ```bash
   pre-commit run --all-files
   ```

Hệ thống sẽ tự động kiểm tra:
- Cấu hình YAML (`check-yaml`).
- Format cuối file và khoảng trắng thừa.
- Ansible Lint để đảm bảo best practices cho các playbooks.

## Giấy phép

Được phân phối dưới giấy phép MIT License. Xem file `LICENSE` để biết thêm chi tiết.
