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

Chuyện là tôi có job cần phải treo máy để nó chạy tự động, nhưng đau đầu là chúng tự ngủ để tiết
kiệm pin, ngắt kết nối Wi-Fi khi rảnh, và cứ thế là job tự die nên tôi đã làm cho nó ngộ nhận rằng
đang có một người dùng ngồi trước màn hình bằng các script lỏ lỏ của tôi. Cũng trộm vía có nhiều job
nên càng ngày nhu cầu để quản lý hoặc one shot cho đỡ phải ngồi cóp, chép sang node mới cũng xuất
hiện vì `tôi lười`.

Thì trước đó ở công ty, tôi có dùng Ansible để quản lý mấy con vps nên tôi kêu con giúp việc Gemini
(Gem) nhà tôi được anh GOOGLE tài trợ cho tôi vì mang mác sinh viên (sv) để làm giúp tôi và tôi chỉ
việc ngồi chơi, chơi xong tôi lấy thành quả. hehe...

## Vấn đề: "Laptop KHÔNG phải là Server"

Khi bạn gập máy tính lại, Embedded Controller (EC) sẽ gửi tín hiệu cầu cứu hệ điều hành chuyển sang
chế độ chờ (suspend). Đây là tính năng tuyệt vời cho người dùng phổ thông, nhưng tôi không phải là
người dùng phổ thông nên tôi nhét script của tôi vào miện EC để nó khỏi cầu cứu nữa.

Thì script đó ở đây `standalone/03-disable-sleep.sh` (link-github), dùng lệnh `sed` để sửa file
`/etc/systemd/logind.conf` và `systemctl` để khóa các target ngủ.

```bash
# Trích từ standalone/03-disable-sleep.sh
sed -i 's/^[#]*HandleLidSwitch=.*/HandleLidSwitch=ignore/' $conf
systemctl mask sleep.target suspend.target
```

Nếu chỉ có một hai máy thì cách này ổn. nhưng tự nhiên jobs từ đâu tới, thì cứ ngồi phải SSH vào
từng máy trong số 5-10 máy để copy/paste script lại dễ gây sai sót, nhiều khi lỗi lại mất thời gian.
Vậy nên tôi kêu em Gem nhà tôi tìm hiểu Ansible và giúp tôi tự động hóa việc này.

## Kiến trúc: Mô hình cấu hình 4 lớp

Để giải quyết vấn đề một cách hệ thống, tôi thiết kế mô hình cấu hình phân lớp:

### Lớp 1: Khởi tạo niềm tin (Trust Bootstrap)

Đây là thử thách đầu tiên: **Làm sao để Ansible điều khiển được máy khi chưa có SSH Key?**

Trước khi công cụ tự động có thể chạy, con người cần thực hiện một thao tác thủ công duy nhất (Step
0):

1. **Cài đặt OS**: Khi cài Ubuntu Server (hoặc Desktop), bạn cần cài sẵn `openssh-server`.
2. **Đảm bảo mạng**: Máy cần có IP và có thể ping được từ máy quản lý.

Vấn đề là: Một cụm 10 máy mới cài sẽ chỉ chấp nhận đăng nhập bằng **Mật khẩu** (Password
Authentication), trong khi tự động hóa cần **SSH Key**.

Tôi giải quyết bằng script `cluster/scripts/01-init-connection.sh`. Cách hoạt động như sau:

1. Ansible sẽ hỏi bạn mật khẩu của user (ví dụ: user `ubuntu` password `1`). Bạn chỉ cần nhập **1
    lần duy nhất**.
2. Ansible dùng mật khẩu đó để tạm thời đăng nhập vào hàng loạt máy trong danh sách.
3. Nó thực hiện task quan trọng nhất: **Copy Public Key** của máy quản lý vào file
    `authorized_keys` của tài khoản `root` trên các máy đích.

```bash
# cluster/scripts/01-init-connection.sh
# --ask-pass: Hỏi password SSH để login lần đầu
# --ask-become-pass: Hỏi password sudo để leo quyền root cài key
ansible-playbook playbooks/init-ssh.yml ... --ask-pass --ask-become-pass
```

Sau bước này, "cánh cửa" đã mở. Ansible có thể ra vào tự do bằng SSH Key mà không cần hỏi password
nữa.

### Lớp 2: Chuẩn hóa môi trường (Provisioning)

Khi đã kết nối được, ta cần một môi trường chuẩn. Không ai muốn phải gõ `apt install` trên từng máy
cả.

`cluster/playbooks/install-tools.yml` đảm bảo mọi node đều có chung một bộ công cụ chẩn đoán
(`htop`, `iotop`, `lm-sensors`) và các thư viện cần thiết mà các script standalone của tôi (như
`network-manager`) yêu cầu.

### Lớp 3: Trừu tượng hóa phần cứng (Chế độ Server)

Đây là lớp quan trọng nhất. Chúng ta phải "đánh lừa" `systemd` để nó bỏ qua các thực tế vật lý.

Trong `cluster/playbooks/configure-power.yml`, tôi áp dụng 3 kỹ thuật can thiệp (hacks) mà tôi đã
thử nghiệm trước đó ở `standalone/`:

1. **Ghi đè Logind**: Khai báo `HandleLidSwitch=ignore` trong `logind.conf`.
2. **Masking Targets**: Tôi mask toàn bộ `sleep.target`, `suspend.target`, `hibernate.target`, và
    `hybrid-sleep.target`. Việc này về cơ bản là xóa bỏ hoàn toàn khả năng "ngủ" của hệ điều hành.
3. **Duy trì mạng (Network Persistence)**: Vô hiệu hóa `wifi.powersave` trong NetworkManager. Sử
    dụng module `blockinfile` của Ansible an toàn hơn nhiều so với việc dùng `sed` vì nó quản lý
    file theo trạng thái.

```yaml
# Ansible đảm bảo cấu hình này tồn tại chính xác mà không làm hỏng file gốc
- name: Disable Wi-Fi Power Save (NetworkManager)
  ansible.builtin.copy:
    dest: /etc/NetworkManager/conf.d/default-wifi-powersave-on.conf
    content: |
      [connection]
      wifi.powersave = 2
```

### Lớp 4: Gia cố bảo mật (Security Hardening)

Cuối cùng, ta khóa cửa lại. `cluster/playbooks/configure-ssh.yml` sẽ tắt tính năng đăng nhập bằng
mật khẩu cho root (`PermitRootLogin prohibit-password`). Cách này an toàn hơn nhiều so với việc kiểm
tra thủ công trong `standalone/02-setup-auth.sh` vì Ansible đảm bảo trạng thái này được áp dụng tức
thì trên toàn bộ cluster.

## Quy trình làm việc: Mở rộng Cluster

Giờ đây, việc thêm một node mới vào cluster là một quy trình chuẩn, không còn là cuộc phiêu lưu may
rủi.

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

Hệ thống này chuyển dịch sự phức tạp từ giai đoạn "vận hành/bảo trì" sang giai đoạn "tự động hóa
thiết lập". Dù các script trong `standalone/` rất hữu ích để sửa nhanh một máy lẻ, nhưng Ansible
cluster cho phép tôi coi các laptop vật lý như những cloud instance tạm thời (ephemeral). Nếu một
máy hỏng, tôi chỉ cần lôi một máy khác từ trong tủ ra, chạy 4 script, và nó sẽ gia nhập cluster
trong chưa đầy 10 phút.
