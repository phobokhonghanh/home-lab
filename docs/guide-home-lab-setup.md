---
title: Bước đầu xây dựng cụm Home Lab bằng những chiếc laptop cũ
author: Phở
category: DevOps
tags:
  - HomeLab
  - Ansible
  - Linux
  - Automation
description:
  Phân tích chuyên sâu về giải pháp tự động hóa, biến các laptop cũ thành một cụm máy chủ ổn định
  (resilient cluster) sử dụng Ansible.
---

Chuyện là tôi có job cần phải treo máy để nó chạy tự động, nhưng đau đầu là chúng tự ngủ để tiết kiệm pin, ngắt kết nối Wi-Fi khi rảnh, và cứ thế là job tự die nên tôi đã làm cho nó ngộ nhận rằng đang có một người dùng ngồi trước màn hình bằng các script lỏ lỏ của tôi. Cũng trộm vía là nó hoạt động tốt, nhưng ngày càng có nhiều job nên nhu cầu để quản lý hoặc one shot cho đỡ phải ngồi cóp, chép sang node mới cũng xuất hiện vì `tôi lười`.

Thì trước đó ở công ty, tôi có dùng Ansible để quản lý mấy con VPS nên tôi kêu con giúp việc Gemini (GEM) (được anh GOOGLE tài trợ vì mang mác sinh viên) để làm giúp, còn phần tôi thì chỉ việc ngồi chơi và lấy thành quả. hehe...

## Vấn đề: "Laptop KHÔNG phải là Server"

Khi bạn gập máy tính lại, Embedded Controller (EC) sẽ gửi tín hiệu cầu cứu hệ điều hành chuyển sang chế độ chờ (suspend). Đây là tính năng tuyệt vời cho người dùng phổ thông, nhưng tôi không phải là người dùng phổ thông nên tôi nhét script vào mồm EC để nó khỏi cầu cứu nữa.

Thì script đó ở đây `standalone/03-disable-sleep.sh` (link-github), dùng lệnh `sed` để sửa file `/etc/systemd/logind.conf` và `systemctl` để khóa các target ngủ.

```bash
# Trích từ standalone/03-disable-sleep.sh
sed -i 's/^[#]*HandleLidSwitch=.*/HandleLidSwitch=ignore/' $conf
systemctl mask sleep.target suspend.target
```

Nhưng nếu tôi lấy đâu đó được 10 chiếc laptop cũ, thì tôi lại phải ngồi SSH vào từng máy chỉ để cóp, chép script. Như vậy thì hết ngày mất, mà còn dễ gây sai sót, nhiều khi lỗi lại mất thời gian, vậy nên tôi thấy Ansible lúc này nên được triển khai.

## Triển khai Ansible

### I. Khởi tạo niềm tin (Trust Me baby)

**Làm sao để Ansible điều khiển được máy khi chưa có SSH Key?**

Đây là thử thách đầu tiên: Trước khi công cụ tự động có thể chạy, tôi cần thực hiện một số thao tác thủ công:

#### 1. **Cài đặt OS**

- Bạn cần cài sẵn `openssh-server` và kiểm tra nó thật sự hoạt động

```bash
# Cài SSH
sudo apt update && sudo apt install -y openssh-server

# Bật & chạy SSH
sudo systemctl enable --now ssh

# Mở firewall (ufw)
sudo ufw allow OpenSSH && sudo ufw reload

# Kiểm tra SSH đang listen port 22
ss -tlnp | grep :22
```

- *Vấn đề phát sinh*:

  Một cụm **10 máy mới cài** chỉ chấp nhận đăng nhập lần đầu bằng **mật khẩu**; nếu mỗi máy một mật khẩu thì **không thể nào nhớ nổi**.

  Ngoài ra, để **Ansible** có thể kết nối bằng mật khẩu thì cách đơn giản nhất là **ghi thẳng mật khẩu vào file `ini`**, nhưng cách này **không bảo mật**.

- *Giải pháp tạm thời*

  Để tăng mức độ bảo mật, có thể cấu hình thêm cho **Ansible** (ví dụ: sử dụng **Ansible Vault**). Tuy nhiên, do:

  - Việc này **chỉ dùng cho lần setup đầu tiên**
  - Sau đó **không sử dụng thường xuyên**
  - Muốn giữ quy trình **đơn giản, nhanh gọn**

  nên mình chọn cách **setup tất cả máy mới với cùng một mật khẩu** để dễ nhớ, và **nhập thủ công mật khẩu ở lần chạy Ansible đầu tiên khi được hỏi**.

  - *Thao tác thực hiện*: Vào terminal tôi đặt mật khẩu đơn giản, dễ nhớ cho nó

    ```bash
    passwd
    ```

#### 2. **Thiết lập mạng nhện**

Cách 1: **Kết nối các node trong cùng mạng**

  Để máy **host** có thể `ping` và kết nối được tới các **node**, các node cần có **IP** và nằm trong **cùng một network**. Cách đơn giản nhất là:

- Kết nối tất cả máy vào **cùng một router Wi-Fi**
- Hoặc cắm dây LAN vào **cùng một switch**

  Khi đó, các máy sẽ giao tiếp với nhau trực tiếp trong mạng LAN.

Cách 2: **Truy cập từ xa (không cùng mạng LAN)**

  Trong trường hợp muốn kết nối từ xa mà **không chung mạng LAN**, bạn cần cấu hình **port forwarding** trên router để chuyển tiếp **port 22 (SSH)** về đúng IP của máy trong mạng nội bộ.

  Cách này hoạt động được, nhưng có một số nhược điểm:

- Cấu hình **rườm rà**
- Dễ cấu hình sai
- Tiềm ẩn rủi ro **bảo mật** nếu expose SSH ra internet

Cách 3: **Tailscale**

  Một cách đơn giản và gọn hơn là sử dụng **Tailscale** ([link-tailscale]) để tạo một **mạng riêng ảo (VPN)** giữa các máy với nhau.

Ưu điểm của Tailscale:

- Không cần port forwarding
- Các máy có thể kết nối với nhau như trong cùng mạng LAN
- Mỗi máy có một IP riêng trong mạng Tailscale
- Phù hợp cho setup **homelab**, **cluster nhỏ**, hoặc **quản lý từ xa**

Nhược điểm của Tailscale:

- Cần cài đặt phần mềm Tailscale trên mỗi máy
- Có thời gian hết hạn khi sử dụng miễn phí

Sau khi cài Tailscale trên host và các node, Ansible có thể kết nối trực tiếp qua **IP Tailscale**, giúp việc quản lý và tự động hoá trở nên đơn giản hơn.

#### 3. **Thiết lập SSH Key**

   Hai bước đầu (OS, Network) đã tạo nền móng vật lý. Bây giờ, ta thực hiện bước 'nhập môn' quan trọng nhất: thiết lập cơ chế xác thực không mật khẩu (passwordless auth) từ Control Node tới toàn bộ Cluster.

   Chúng ta sẽ không copy key thủ công. Chúng ta sử dụng Ansible để làm điều đó một cách "Atomic" và an toàn.

##### 3.1 **Chiến lược Playbook (Playbook Strategy)**

   Playbook `playbooks/init-ssh.yml` được thiết kế tối giản, bỏ qua bước thu thập thông tin (`gather_facts: false`) để tăng tốc độ và tập trung vào hai nhiệm vụ chính:

   1. **Generate**: Sinh cặp khóa SSH trên máy quản lý (một lần duy nhất).
   2. **Distribute**: Đẩy Public Key vào tài khoản `root` của các máy đích.

##### 3.2 **Cơ chế hoạt động (Deep Dive)**

Task 1: **Generate SSH Key (Control Node)**

   ```yaml
   - name: Generate SSH key
     command: ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
     delegate_to: localhost
     run_once: true
     args:
       creates: ~/.ssh/id_rsa
   ```

- **`delegate_to: localhost`**: Ansible thường chạy lệnh trên máy đích, nhưng lệnh này buộc phải chạy trên máy quản lý (Control Node) của bạn.
- **`run_once: true`**: Dù inventory có 100 máy, task này chỉ chạy duy nhất một lần.
- **`args.creates`**: Đảm bảo tính **Idempotency** (bất biến). Nếu file key đã tồn tại, Ansible sẽ bỏ qua task này, tránh việc ghi đè vô ý làm mất quyền truy cập của các session cũ.
- *Technical Tip*: Mặc định dùng RSA 4096. Nếu hạ tầng hỗ trợ, hãy ưu tiên **Ed25519** (`ssh-keygen -t ed25519`) để có hiệu suất ký/xác thực nhanh hơn và khóa ngắn hơn.

Task 2: **Phân phối Key (Worker Nodes)**

  ```yaml
  - name: Install SSH Key to Root Account (Requires User Password + Sudo)
    ansible.posix.authorized_key:
      user: root
      state: present
      key: "{{ lookup('file', '~/.ssh/id_rsa.pub') }}"
    become: true
  ```

Sử dụng module `ansible.posix.authorized_key`:

- **`lookup('file', '~/.ssh/id_rsa.pub')`**: Đọc public key từ file local của bạn.
- **`become: true`**: Leo quyền `sudo` trên máy đích để ghi vào file `/root/.ssh/authorized_keys`. Module này tự động xử lý permission (Folder `.ssh` 700, File 600) - một chi tiết nhỏ nhưng quan trọng mà script thủ công thường hay sai sót.

##### 3.3 Chạy scripts

   Trong lần chạy đầu tiên, Ansible chưa có Key để vào, nên nó cần một "giấy thông hành" tạm thời: Mật khẩu.

   ```bash
   ansible-playbook playbooks/init-ssh.yml -i inventory/home-lab.ini -u ubuntu --ask-pass --ask-become-pass
   # or
   chmod +x cluster/scripts/01-init-connection.sh && cluster/scripts/01-init-connection.sh
   # or
   bash cluster/scripts/01-init-connection.sh
   ```

   **Giải phẫu câu lệnh:**

- `-u ubuntu`: User khởi tạo (bootstrap user) đã có trên máy đích.
- `--ask-pass`: Ansible sẽ prompt hỏi mật khẩu SSH để login.
- `--ask-become-pass`: Prompt hỏi mật khẩu sudo (để task leo quyền root ghi file).

##### 3.4 Tại sao an toàn hơn copy thủ công?

   1. **Isolation**: Private Key không bao giờ rời khỏi Control Node.
   2. **Zero-Knowledge Inventory**: Mật khẩu không bao giờ được lưu cứng (hardcoded) trong code hay inventory. Nó chỉ tồn tại trong RAM lúc bạn gõ command và biến mất ngay sau đó.
   3. **Consistency**: Đảm bảo 100% các node có cùng một cấu hình authorized_keys chuẩn, tránh lỗi người dùng.

##### 3.5 Lưu ý

- **Permission Hell**: Nếu đã chạy playbook mà vẫn đòi mật khẩu, SSH vào node kiểm tra `ls -la /root/.ssh`. Quyền bắt buộc phải là `700` cho thư mục và `600` cho file authorized_keys.
- **Lookup Path**: Nếu bạn tùy chỉnh đường dẫn key, đảm bảo param của hàm `lookup` trỏ đúng vào file `.pub` trên máy Control.
- **Non-root User**: Nếu không muốn dùng root, đổi `user: root` thành user mong muốn và bỏ `become: true` (nếu user đó trùng với user kết nối).

Sau khi phân phối Key thì cánh cửa đã mở. Bạn có thể:

   1. Chạy các playbook vận hành sau này mà không cần cờ `--ask-pass`.
   2. **Hardening**: Cấu hình `PasswordAuthentication no` trong `sshd_config` để triệt tiêu nguy cơ Brute-force mật khẩu.
   3. Bảo vệ Private Key trên máy mình (chmod 600) và cân nhắc dùng SSH Agent nếu đặt passphrase.

### II. Chuẩn hóa Môi trường & Thư viện (Standardize Environment)

Khi đã kết nối được vào cluster, việc tiếp theo là đồng bộ hóa môi trường. Không ai muốn phải SSH vào từng máy để gõ `apt install htop` cả. Chúng ta cần một nền tảng (baseline) giống hệt nhau trên mọi node.

#### 1. Chiến lược Playbook

Playbook `playbooks/install-tools.yml` đóng vai trò là "người phục vụ", chuẩn bị đầy đủ nguyên liệu trước khi các món chính được nấu.

1. **System Update**: Cập nhật toàn bộ package list và upgrade hệ thống.
2. **Dependencies**: Cài đặt các gói phần mềm nền tảng cho việc giám sát và vận hành.
3. **Time Synchronization**: Đồng bộ múi giờ để log file khớp nhau trên mọi node.

#### 2. Cơ chế hoạt động (Deep Dive)

**Task 1: Cài đặt Common Packages**

```yaml
- name: Install basic packages (Debian/Ubuntu)
  ansible.builtin.apt:
    name:
      - htop        # Giám sát tài nguyên
      - iotop       # Giám sát I/O đĩa
      - lm-sensors  # Đọc cảm biến nhiệt độ (quan trọng cho laptop cũ)
      - net-tools   # ifconfig, netstat
      - curl
      - git
    state: present
    update_cache: yes
```

* **`update_cache: yes`**: Đảm bảo apt được làm mới trước khi cài đặt (tương đương `apt update`).
- **Hash List**: Khai báo danh sách gói gọn gàng, dễ dàng thêm bớt sau này.

**Task 2: Đồng bộ Thời gian (Timezone)**

```yaml
- name: Set Timezone to Asia/Bangkok
  community.general.timezone:
    name: Asia/Bangkok

- name: Ensure NTP service is active
  ansible.builtin.service:
    name: ntp
    state: started
    enabled: true
```

* **Timezone**: Thiết lập cứng về `Asia/Bangkok`. Điều này cực kỳ quan trọng khi debug log phân tán (distributed logs). Nếu mỗi node chạy một múi giờ, việc điều tra sự cố sẽ là địa ngục.
- **NTP**: Đảm bảo service `ntp` luôn chạy để đồng bộ clock chính xác từng mili-giây.

#### 3. Lợi ích vận hành

Việc chuẩn hóa này đảm bảo rằng các script giám sát (như script theo dõi nhiệt độ `monitor-temp.sh`) sẽ luôn chạy đúng trên mọi máy mà không gặp lỗi "command not found".

#### 4. Yêu cầu thực thi (Execution Command)

```bash
ansible-playbook playbooks/install-tools.yml -i inventory/home-lab.ini
# or
bash cluster/scripts/02-install-requirements.sh
```

### III. Chuyển đổi công năng (Laptop to Server)

Đây là tầng quan trọng nhất, nơi "phép thuật" xảy ra. Chúng ta phải can thiệp sâu vào hệ điều hành để "đánh lừa" nó, khiến nó quên đi bản năng của một chiếc laptop (ngủ khi gập máy, tiết kiệm pin) và hoạt động như một server thực thụ.

#### 1. Chiến lược Playbook

Playbook `playbooks/configure-power.yml` thực hiện 3 kỹ thuật can thiệp cốt lõi (Intervention Techniques):

1. **Lid Switch Override**: Bỏ qua cảm biến nắp máy.
2. **Sleep Target Masking**: Vô hiệu hóa vĩnh viễn các trạng thái ngủ.
3. **Network Persistence**: Ngăn card mạng tự ngắt để tiết kiệm điện.

#### 2. Cơ chế hoạt động (Deep Dive)

**Task 1: Logind Configuration**

```yaml
- name: Ignore Lid Switch (HandleLidSwitch)
  lineinfile:
    path: /etc/systemd/logind.conf
    regexp: '^#?HandleLidSwitch='
    line: 'HandleLidSwitch=ignore'
  notify: Restart logind
```

* **`lineinfile`**: Module này tìm dòng cấu hình khớp với regex và sửa đổi nó. An toàn hơn `sed` vì nó kiểm tra trạng thái file trước khi ghi.

**Task 2: Masking Systemd Targets**

```yaml
- name: Mask sleep targets
  systemd:
    name: "{{ item }}"
    enabled: no
    masked: yes
  loop:
    - sleep.target
    - suspend.target
    - hibernate.target
    - hybrid-sleep.target
```

* **`masked: yes`**: Đây là mức độ vô hiệu hóa cao nhất. Nó link các service này về `/dev/null`, khiến cho dù hệ thống hay user có cố tình gọi lệnh `systemctl suspend` cũng sẽ không có tác dụng.

**Task 3: Network Manager Config**

```yaml
- name: Disable Wi-Fi Power Save
  copy:
    dest: /etc/NetworkManager/conf.d/default-wifi-powersave-on.conf
    content: |
      [connection]
      wifi.powersave = 2
```

* `wifi.powersave = 2`: Giá trị magic number để tắt tính năng tiết kiệm điện (Disable), giữ kết nối luôn ổn định.

#### 3. Yêu cầu thực thi (Execution Command)

```bash
ansible-playbook playbooks/configure-power.yml -i inventory/home-lab.ini
# or
bash cluster/scripts/03-configure-power.sh
```

### IV. Gia cố bảo mật (Security Hardening)

Sau khi hệ thống đã vận hành trơn tru, bước cuối cùng là "khóa cửa" để ngăn chặn các truy cập trái phép.

#### 1. Chiến lược Playbook

Playbook `playbooks/configure-ssh.yml` tập trung vào việc siết chặt cấu hình SSH Server (`sshd`), biến Key-based Auth thành phương thức duy nhất.

#### 2. Cơ chế hoạt động (Deep Dive)
**Task: Hardening SSHD**

```yaml
- name: Disable Password Configuration
  lineinfile:
    path: /etc/ssh/sshd_config
    regexp: "{{ item.regexp }}"
    line: "{{ item.line }}"
  loop:
    - { regexp: '^#?PermitRootLogin', line: 'PermitRootLogin prohibit-password' }
    - { regexp: '^#?PasswordAuthentication', line: 'PasswordAuthentication no' }
  notify: Restart ssh
```

* **`PermitRootLogin prohibit-password`**: Vẫn cho phép root đăng nhập, NHƯNG chỉ được phép dùng Key. Mật khẩu root sẽ bị từ chối.
- **`PasswordAuthentication no`**: Chặn đứng các cuộc tấn công Brute-force mật khẩu. Kẻ tấn công không thể thử mật khẩu nếu server không cho phép nhập mật khẩu.

#### 3. Lưu ý quan trọng

Trước khi chạy module này, hãy **chắc chắn 100%** rằng bạn đã setup thành công SSH Key (Bước 1) và đã login thử thành công. Nếu không, bạn sẽ tự nhốt mình ở ngoài (Lockout) và phải cắm màn hình rời để cứu hộ.

#### 4. Yêu cầu thực thi (Execution Command)

```bash
ansible-playbook playbooks/configure-ssh.yml -i inventory/home-lab.ini
# or
bash cluster/scripts/04-secure-ssh.sh
```

## Quy trình làm việc: Mở rộng Cluster

Giờ đây, việc thêm một node mới vào cluster là một quy trình chuẩn, không còn là cuộc phiêu lưu may rủi.

1. **Cập nhật Inventory**: Thêm IP mới vào `cluster/inventory/home-lab.ini`.
2. **Cấp phát (Provision)**: Chạy pipeline tự động nhắm vào đúng node đó.

```bash
# Ví dụ: Cài đặt cho một node cụ thể
./cluster/scripts/01-init-connection.sh 192.168.1.105
./cluster/scripts/02-install-requirements.sh 192.168.1.105
```

Bằng cách hỗ trợ tham số mục tiêu (`$1`), tôi có thể cài đặt chính xác các máy phần cứng mới mà
không hề làm gián đoạn hay ảnh hưởng đến cluster đang chạy.

## Kết luận

Hệ thống này chuyển dịch sự phức tạp từ giai đoạn "vận hành/bảo trì" sang giai đoạn "tự động hóa thiết lập". Dù các script trong `standalone/` rất hữu ích để sửa nhanh một máy lẻ, nhưng Ansible cluster cho phép tôi coi các laptop vật lý như những cloud instance tạm thời (ephemeral). Nếu một máy hỏng, tôi chỉ cần lôi một máy khác từ trong tủ ra, chạy 4 script, và nó sẽ gia nhập cluster chưa đầy 10 phút.
