The Ultimate CI/CD Corporate DevOps Pipeline Project

Полное руководство по развертыванию enterprise-grade CI/CD инфраструктуры в Proxmox с изолированной сетью

Show Image
Show Image
Show Image
Show Image
📋 Содержание

О проекте
Архитектура
Требования
Быстрый старт
Детальная установка

Этап 1: Сетевая инфраструктура
Этап 2: DNS Server
Этап 3: Jumphost
Этап 4: Ngrok Tunnel
Этап 5: Создание VM через Terraform
Последующие этапы...




🎯 О проекте
Это руководство представляет собой полную реализацию корпоративного CI/CD pipeline на базе Proxmox с изолированной сетевой архитектурой. Проект создан для закрепления навыков DevOps и демонстрации в портфолио/резюме.
Ключевые особенности архитектуры

✅ Полностью изолированная сеть - внутренний контур без прямого доступа извне
✅ Jumphost - единственная точка входа для администрирования
✅ DNS сервер - внутреннее разрешение имен (BIND9)
✅ NAT Gateway - контролируемый доступ в интернет через Ngrok/Cloudflare
✅ Безопасный внешний доступ - только через туннель
✅ Production-ready архитектура - соответствие корпоративным стандартам

Что вы получите

✅ Полностью автоматизированный CI/CD pipeline
✅ Kubernetes кластер (K3s) с 3 нодами
✅ Безопасный внешний доступ через Ngrok/Cloudflare Tunnel
✅ Полный стек мониторинга (Prometheus + Grafana)
✅ Приватный container registry (Harbor)
✅ Анализ качества кода (SonarQube)
✅ Управление артефактами (Nexus)
✅ Сканирование безопасности (Trivy)
✅ Infrastructure as Code (Terraform)
✅ Внутренний DNS (BIND9)
✅ Jumphost для администрирования


🗺️ Архитектура
                          Internet
                             ↓
                    ┌────────────────┐
                    │  Your Router   │
                    │  10.0.10.1     │
                    └────────┬───────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        │              Proxmox Host               │
        │            (10.0.10.200)                │
        │                                         │
        │    ┌─────────────────────────────┐     │
        │    │  vmbr0 (Внешняя сеть)      │     │
        │    │  10.0.10.0/24               │     │
        │    └──┬──────────┬───────────┬───┘     │
        │       │          │           │         │
        │   ┌───┴───┐  ┌───┴────┐  ┌───┴────┐   │
        │   │Jumphost│ │Ngrok   │  │DNS     │   │
        │   │.102    │ │.60     │  │.53     │   │
        │   │2 NIC   │ │2 NIC   │  │2 NIC   │   │
        │   └───┬───┘  └───┬────┘  └───┬────┘   │
        │       │          │           │         │
        │    ┌──┴──────────┴───────────┴───┐     │
        │    │  vmbr1 (Изолированная сеть) │     │
        │    │  192.168.100.0/24            │     │
        │    │  (NO INTERNET ACCESS)        │     │
        │    └──┬───────────────────────┬───┘     │
        │       │                       │         │
        │   ┌───┴────┐            ┌─────┴─────┐   │
        │   │Jumphost│            │Ngrok      │   │
        │   │.5      │            │.60        │   │
        │   └────────┘            │(NAT GW)   │   │
        │                         └───────────┘   │
        │                                         │
        │    ┌────────────────────────────────┐   │
        │    │   CI/CD Infrastructure         │   │
        │    │   (192.168.100.20-40)          │   │
        │    │                                │   │
        │    │  ┌─────────┐  ┌──────────┐    │   │
        │    │  │Jenkins  │  │SonarQube │    │   │
        │    │  │  :20    │  │   :30    │    │   │
        │    │  └─────────┘  └──────────┘    │   │
        │    │                                │   │
        │    │  ┌─────────┐  ┌──────────┐    │   │
        │    │  │ Nexus   │  │  Harbor  │    │   │
        │    │  │  :31    │  │   :32    │    │   │
        │    │  └─────────┘  └──────────┘    │   │
        │    │                                │   │
        │    │  ┌──────────────────────────┐ │   │
        │    │  │     Monitoring :40       │ │   │
        │    │  │  Prometheus + Grafana    │ │   │
        │    │  └──────────────────────────┘ │   │
        │    └────────────────────────────────┘   │
        │                                         │
        │    ┌────────────────────────────────┐   │
        │    │   K3s Kubernetes Cluster       │   │
        │    │   (192.168.100.10-12)          │   │
        │    │                                │   │
        │    │  ┌──────────────────────────┐  │   │
        │    │  │ Master Node (.10)        │  │   │
        │    │  │ - K3s Control Plane      │  │   │
        │    │  └──────────────────────────┘  │   │
        │    │                                │   │
        │    │  ┌──────────┐  ┌──────────┐   │   │
        │    │  │Worker 1  │  │Worker 2  │   │   │
        │    │  │  (.11)   │  │  (.12)   │   │   │
        │    │  └──────────┘  └──────────┘   │   │
        │    │                                │   │
        │    │  MetalLB: .100-.150            │   │
        │    │  Traefik Ingress               │   │
        │    └────────────────────────────────┘   │
        │                                         │
        │    ┌────────────────────────────────┐   │
        │    │   DNS Server (.53)             │   │
        │    │   BIND9 + Internal Zones       │   │
        │    └────────────────────────────────┘   │
        │                                         │
        └─────────────────────────────────────────┘
Сетевая топология
Внешняя сеть (vmbr0) - 10.0.10.0/24:

Доступ в интернет
Jumphost (10.0.10.102)
Ngrok Gateway (10.0.10.60)
DNS Server (10.0.10.53)

Изолированная сеть (vmbr1) - 192.168.100.0/24:

Полная изоляция от прямого доступа
Все рабочие VM
Доступ в интернет только через Ngrok NAT
Внутренний DNS

Потоки трафика
mermaidgraph TB
    A[Admin] -->|SSH| B[Jumphost<br/>10.0.10.102]
    B -->|SSH| C[Internal VMs<br/>192.168.100.x]
    
    C -->|Internet| D[Ngrok Gateway<br/>192.168.100.60]
    D -->|NAT| E[Internet]
    
    F[External Users] -->|HTTPS| G[Ngrok/Cloudflare]
    G -->|Tunnel| D
    D -->|Forward| H[K8s Ingress<br/>192.168.100.100]
    
    C -->|DNS| I[BIND9<br/>192.168.100.53]
    I -->|Upstream| J[8.8.8.8]

💻 Требования
Аппаратные требования
Proxmox хост:

CPU: 12+ cores (Ryzen 3900 или аналог)
RAM: 64GB
Storage: 2TB HDD + 2TB SSD
Network: 2x 1Gbps (минимум 1x)

Windows машина (для управления):

CPU: 4+ cores
RAM: 16GB+
Storage: 100GB

Программные требования
На Proxmox:

Proxmox VE 8.0+
Доступ через SSH

На Windows машине:

WSL2 или Git Bash
Terraform >= 1.5.0
kubectl >= 1.28.0
SSH client

Сетевые требования

Внешняя сеть: 10.0.10.0/24 (существующая)
Изолированная сеть: 192.168.100.0/24 (будет создана)
Интернет доступ с серым IP
Ngrok или Cloudflare аккаунт (бесплатный)

Необходимые аккаунты

GitHub (для репозитория)
Ngrok или Cloudflare (для туннеля)
Gmail (для email уведомлений)


🚀 Быстрый старт
bash# 1. Клонируйте репозиторий
git clone https://github.com/YOUR_USERNAME/devops-pipeline-proxmox.git
cd devops-pipeline-proxmox

# 2. Настройте Terraform
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Отредактируйте terraform.tfvars с вашими параметрами

# 3. Создайте инфраструктуру
terraform init
terraform plan
terraform apply -auto-approve

# 4. Подключитесь через Jumphost
ssh -J root@10.0.10.102 ubuntu@192.168.100.10

# 5. Настройте остальные компоненты согласно инструкции
⏱️ Общее время установки: ~3-4 часа

📚 Детальная установка
Этап 1: Подготовка сетевой инфраструктуры
1.1 Создание изолированной сети в Proxmox
Подключитесь к Proxmox хосту:
bashssh root@10.0.10.200
Создайте новый bridge для изолированной сети БЕЗ физического интерфейса:
bashcat >> /etc/network/interfaces <<EOF

# Isolated DevOps Network (NO DIRECT INTERNET)
auto vmbr1
iface vmbr1 inet static
    address 192.168.100.1/24
    bridge-ports none
    bridge-stp off
    bridge-fd 0
    # NO NAT/MASQUERADE - полная изоляция!
EOF
Примените изменения:
bashifreload -a
Проверьте созданный bridge:
baship addr show vmbr1
# Должно показать: 192.168.100.1/24

# Проверка, что нет маршрутизации
iptables -t nat -L POSTROUTING -n -v | grep 192.168.100
# Должно быть пусто!
1.2 План виртуальных машин с двумя NIC
Имя VMCPURAMDiskIP (vmbr0)IP (vmbr1)Назначениеjumphost22GB10GB10.0.10.102192.168.100.5SSH Gatewayngrok-tunnel22GB10GB10.0.10.60192.168.100.60NAT Gateway + Tunneldns-server22GB10GB10.0.10.53192.168.100.53BIND9 DNSk3s-master48GB50GB-192.168.100.10K3s Control Planek3s-worker148GB50GB-192.168.100.11K3s Worker Nodek3s-worker248GB50GB-192.168.100.12K3s Worker Nodejenkins48GB60GB-192.168.100.20Jenkins CI/CDsonarqube24GB30GB-192.168.100.30Code Qualitynexus24GB40GB-192.168.100.31Artifact Repositoryharbor24GB50GB-192.168.100.32Container Registrymonitoring46GB40GB-192.168.100.40Prometheus+Grafana
Итого: 30 vCPU, 52GB RAM, 410GB Storage
1.3 Создание Ubuntu Cloud-Init Template
На Proxmox хосте:
bashcd /var/lib/vz/template/iso/

# Скачиваем Ubuntu 22.04 Cloud Image
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

# Создаем VM template (ID 9000)
qm create 9000 --name ubuntu-2204-template --memory 2048 --cores 2 --net0 virtio,bridge=vmbr1

# Импортируем диск
qm importdisk 9000 jammy-server-cloudimg-amd64.img local-lvm

# Присоединяем диск
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0

# Добавляем Cloud-Init
qm set 9000 --ide2 local-lvm:cloudinit

# Настраиваем boot
qm set 9000 --boot c --bootdisk scsi0

# Добавляем serial console
qm set 9000 --serial0 socket --vga serial0

# Конвертируем в template
qm template 9000

Этап 2: Установка DNS сервера
2.1 Создание DNS Server VM
DNS сервер - первая VM, которую нужно создать, так как он будет использоваться всеми остальными.
bash# На Proxmox хосте
qm clone 9000 150 --name dns-server --full

# Настройка 2 сетевых интерфейсов
qm set 150 --net0 virtio,bridge=vmbr0
qm set 150 --net1 virtio,bridge=vmbr1

# Ресурсы
qm set 150 --memory 2048 --cores 2

# Cloud-Init конфигурация
qm set 150 --ipconfig0 ip=10.0.10.53/24,gw=10.0.10.1
qm set 150 --ipconfig1 ip=192.168.100.53/24
qm set 150 --nameserver 8.8.8.8
qm set 150 --searchdomain devops.local
qm set 150 --ciuser ubuntu
qm set 150 --sshkeys ~/.ssh/id_rsa.pub

# Запуск
qm start 150

# Ожидание запуска
sleep 30
2.2 Установка и настройка BIND9
Подключитесь к DNS серверу:
bashssh ubuntu@10.0.10.53
Установите BIND9:
bashsudo apt update
sudo apt install -y bind9 bind9utils bind9-doc dnsutils

# Включите автозапуск
sudo systemctl enable named
2.3 Настройка зон DNS
Создайте конфигурацию BIND9:
bashsudo tee /etc/bind/named.conf.options > /dev/null <<'EOF'
options {
    directory "/var/cache/bind";

    # Слушаем на обоих интерфейсах
    listen-on { 10.0.10.53; 192.168.100.53; };
    listen-on-v6 { none; };

    # Разрешаем запросы из обеих сетей
    allow-query { 
        localhost; 
        10.0.10.0/24; 
        192.168.100.0/24; 
    };

    # Пересылка внешних запросов
    forwarders {
        8.8.8.8;
        8.8.4.4;
    };

    # Безопасность
    recursion yes;
    allow-recursion { 
        localhost; 
        10.0.10.0/24; 
        192.168.100.0/24; 
    };

    dnssec-validation auto;
};
EOF
Создайте зону для внутренней сети:
bashsudo tee /etc/bind/named.conf.local > /dev/null <<'EOF'
# Прямая зона для devops.local
zone "devops.local" {
    type master;
    file "/etc/bind/db.devops.local";
    allow-update { none; };
};

# Обратная зона для 192.168.100.0/24
zone "100.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/db.192.168.100";
    allow-update { none; };
};
EOF
Создайте файл прямой зоны:
bashsudo tee /etc/bind/db.devops.local > /dev/null <<'EOF'
$TTL    604800
@       IN      SOA     dns.devops.local. admin.devops.local. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      dns.devops.local.
dns     IN      A       192.168.100.53

; Gateway
jumphost        IN      A       192.168.100.5
ngrok           IN      A       192.168.100.60
gateway         IN      A       192.168.100.60

; K3s Cluster
k3s-master      IN      A       192.168.100.10
k3s-worker1     IN      A       192.168.100.11
k3s-worker2     IN      A       192.168.100.12

; CI/CD Tools
jenkins         IN      A       192.168.100.20
sonarqube       IN      A       192.168.100.30
sonar           IN      CNAME   sonarqube
nexus           IN      A       192.168.100.31
harbor          IN      A       192.168.100.32
monitoring      IN      A       192.168.100.40
prometheus      IN      CNAME   monitoring
grafana         IN      CNAME   monitoring

; Wildcard для K8s приложений
*.apps          IN      A       192.168.100.100
boardgame       IN      CNAME   apps
EOF
Создайте файл обратной зоны:
bashsudo tee /etc/bind/db.192.168.100 > /dev/null <<'EOF'
$TTL    604800
@       IN      SOA     dns.devops.local. admin.devops.local. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      dns.devops.local.

53      IN      PTR     dns.devops.local.
5       IN      PTR     jumphost.devops.local.
60      IN      PTR     ngrok.devops.local.

10      IN      PTR     k3s-master.devops.local.
11      IN      PTR     k3s-worker1.devops.local.
12      IN      PTR     k3s-worker2.devops.local.

20      IN      PTR     jenkins.devops.local.
30      IN      PTR     sonarqube.devops.local.
31      IN      PTR     nexus.devops.local.
32      IN      PTR     harbor.devops.local.
40      IN      PTR     monitoring.devops.local.

100     IN      PTR     apps.devops.local.
EOF
Проверьте конфигурацию и запустите:
bash# Проверка конфигурации
sudo named-checkconf
sudo named-checkzone devops.local /etc/bind/db.devops.local
sudo named-checkzone 100.168.192.in-addr.arpa /etc/bind/db.192.168.100

# Перезапуск
sudo systemctl restart named
sudo systemctl status named

# Проверка
dig @localhost jenkins.devops.local
dig @localhost -x 192.168.100.20
2.4 Настройка netplan для статических IP
bashsudo tee /etc/netplan/50-cloud-init.yaml > /dev/null <<'EOF'
network:
  version: 2
  ethernets:
    ens18:
      dhcp4: no
      addresses:
        - 10.0.10.53/24
      routes:
        - to: 0.0.0.0/0
          via: 10.0.10.1
      nameservers:
        addresses:
          - 127.0.0.1
          - 8.8.8.8
    ens19:
      dhcp4: no
      addresses:
        - 192.168.100.53/24
      nameservers:
        addresses:
          - 127.0.0.1
EOF

sudo netplan apply

Этап 3: Настройка Jumphost
3.1 Создание Jumphost VM
bash# На Proxmox хосте
qm clone 9000 100 --name jumphost --full

# Настройка 2 сетевых интерфейсов
qm set 100 --net0 virtio,bridge=vmbr0
qm set 100 --net1 virtio,bridge=vmbr1

# Ресурсы
qm set 100 --memory 2048 --cores 2

# Cloud-Init
qm set 100 --ipconfig0 ip=10.0.10.102/24,gw=10.0.10.1
qm set 100 --ipconfig1 ip=192.168.100.5/24
qm set 100 --nameserver 192.168.100.53
qm set 100 --searchdomain devops.local
qm set 100 --ciuser ubuntu
qm set 100 --sshkeys ~/.ssh/id_rsa.pub

# Запуск
qm start 100
sleep 30
3.2 Настройка Jumphost
Подключитесь:
bashssh ubuntu@10.0.10.102
Настройте netplan:
bashsudo tee /etc/netplan/50-cloud-init.yaml > /dev/null <<'EOF'
network:
  version: 2
  ethernets:
    ens18:
      dhcp4: no
      addresses:
        - 10.0.10.102/24
      routes:
        - to: 0.0.0.0/0
          via: 10.0.10.1
      nameservers:
        addresses:
          - 192.168.100.53
          - 8.8.8.8
        search:
          - devops.local
    ens19:
      dhcp4: no
      addresses:
        - 192.168.100.5/24
      nameservers:
        addresses:
          - 192.168.100.53
        search:
          - devops.local
EOF

sudo netplan apply
Установите полезные инструменты:
bashsudo apt update
sudo apt install -y htop curl wget git vim tmux net-tools dnsutils

# Проверка DNS
dig jenkins.devops.local
# Должен вернуть 192.168.100.20
3.3 Настройка SSH конфигурации
На вашей локальной машине создайте ~/.ssh/config:
bash# Jumphost
Host jumphost
    HostName 10.0.10.102
    User ubuntu
    IdentityFile ~/.ssh/id_rsa
    ForwardAgent yes

# Все VM через Jumphost
Host 192.168.100.*
    ProxyJump jumphost
    User ubuntu
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking no

# Именованные хосты
Host k3s-master
    HostName 192.168.100.10
    ProxyJump jumphost

Host jenkins
    HostName 192.168.100.20
    ProxyJump jumphost

# И так далее для всех VM...
Теперь вы можете подключаться напрямую:
bashssh k3s-master
ssh jenkins

Этап 4: Настройка Ngrok Tunnel
4.1 Создание Ngrok Gateway VM
bash# На Proxmox хосте
qm clone 9000 160 --name ngrok-tunnel --full

# Настройка 2 сетевых интерфейсов
qm set 160 --net0 virtio,bridge=vmbr0
qm set 160 --net1 virtio,bridge=vmbr1

# Ресурсы
qm set 160 --memory 2048 --cores 2

# Cloud-Init
qm set 160 --ipconfig0 ip=10.0.10.60/24,gw=10.0.10.1
qm set 160 --ipconfig1 ip=192.168.100.60/24
qm set 160 --nameserver 192.168.100.53
qm set 160 --searchdomain devops.local
qm set 160 --ciuser ubuntu
qm set 160 --sshkeys ~/.ssh/id_rsa.pub

# Запуск
qm start 160
sleep 30
4.2 Установка Ngrok
Подключитесь через Jumphost:
bashssh ubuntu@192.168.100.60
Установите Ngrok:
bash# Скачивание
curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | \
  sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null && \
  echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | \
  sudo tee /etc/apt/sources.list.d/ngrok.list && \
  sudo apt update && sudo apt install ngrok

# Авторизация (получите токен на https://dashboard.ngrok.com)
ngrok config add-authtoken YOUR_NGROK_TOKEN
4.3 Настройка NAT для внутренней сети
Включите IP forwarding:
bashsudo tee -a /etc/sysctl.conf > /dev/null <<'EOF'
# Enable IP forwarding for NAT
net.ipv4.ip_forward = 1
net.ipv4.conf.all.forwarding = 1
EOF

sudo sysctl -p
Настройте iptables NAT:
bashsudo tee /etc/iptables-nat.sh > /dev/null <<'EOF'
#!/bin/bash

# Flush existing rules
iptables -F
iptables -t nat -F

# Default policies
iptables -P FORWARD DROP
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT

# Allow established connections
iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT

# NAT for internal network
iptables -t nat -A POSTROUTING -s 192.168.100.0/24 -o ens18 -j MASQUERADE

# Allow forwarding from internal network
iptables -A FORWARD -sRetryClaude does not have the ability to run the code it generates yet.AContinuebash# Allow forwarding from internal network
iptables -A FORWARD -s 192.168.100.0/24 -o ens18 -j ACCEPT

# Allow DNS
iptables -A FORWARD -p udp --dport 53 -j ACCEPT
iptables -A FORWARD -p tcp --dport 53 -j ACCEPT

# Allow HTTP/HTTPS
iptables -A FORWARD -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -p tcp --dport 443 -j ACCEPT

# Log dropped packets (optional)
iptables -A FORWARD -j LOG --log-prefix "IPTables-Dropped: "
EOF

sudo chmod +x /etc/iptables-nat.sh
sudo /etc/iptables-nat.sh
Сохраните правила для автозапуска:
bashsudo apt install -y iptables-persistent
sudo netfilter-persistent save

# Добавьте в автозапуск
sudo tee /etc/systemd/system/iptables-nat.service > /dev/null <<'EOF'
[Unit]
Description=IPTables NAT rules
After=network.target

[Service]
Type=oneshot
ExecStart=/etc/iptables-nat.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable iptables-nat.service
sudo systemctl start iptables-nat.service
4.4 Настройка Ngrok конфигурации
Создайте конфигурацию Ngrok:
bashmkdir -p ~/.config/ngrok

tee ~/.config/ngrok/ngrok.yml > /dev/null <<'EOF'
version: "2"
authtoken: YOUR_NGROK_TOKEN

tunnels:
  jenkins:
    proto: http
    addr: 192.168.100.20:8080
    domain: YOUR_DOMAIN.ngrok-free.app
    
  sonarqube:
    proto: http
    addr: 192.168.100.30:9000
    
  nexus:
    proto: http
    addr: 192.168.100.31:8081
    
  harbor:
    proto: http
    addr: 192.168.100.32:80
    
  grafana:
    proto: http
    addr: 192.168.100.40:3000
    
  boardgame:
    proto: http
    addr: 192.168.100.100:80
EOF
4.5 Настройка Ngrok как systemd сервиса
bashsudo tee /etc/systemd/system/ngrok.service > /dev/null <<'EOF'
[Unit]
Description=Ngrok Tunnel Service
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu
ExecStart=/usr/local/bin/ngrok start --all --config=/home/ubuntu/.config/ngrok/ngrok.yml
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable ngrok
sudo systemctl start ngrok

# Проверка статуса
sudo systemctl status ngrok

# Просмотр логов
sudo journalctl -u ngrok -f
4.6 Альтернатива: Cloudflare Tunnel
Если предпочитаете Cloudflare:
bash# Установка cloudflared
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb

# Авторизация
cloudflared tunnel login

# Создание туннеля
cloudflared tunnel create devops-pipeline

# Конфигурация
mkdir -p ~/.cloudflared

tee ~/.cloudflared/config.yml > /dev/null <<'EOF'
tunnel: YOUR_TUNNEL_ID
credentials-file: /home/ubuntu/.cloudflared/YOUR_TUNNEL_ID.json

ingress:
  - hostname: jenkins.your-domain.com
    service: http://192.168.100.20:8080
  
  - hostname: sonar.your-domain.com
    service: http://192.168.100.30:9000
  
  - hostname: nexus.your-domain.com
    service: http://192.168.100.31:8081
  
  - hostname: harbor.your-domain.com
    service: http://192.168.100.32:80
  
  - hostname: grafana.your-domain.com
    service: http://192.168.100.40:3000
  
  - hostname: "*.apps.your-domain.com"
    service: http://192.168.100.100:80
  
  - service: http_status:404
EOF

# DNS записи
cloudflared tunnel route dns devops-pipeline jenkins.your-domain.com
cloudflared tunnel route dns devops-pipeline sonar.your-domain.com
cloudflared tunnel route dns devops-pipeline nexus.your-domain.com
cloudflared tunnel route dns devops-pipeline harbor.your-domain.com
cloudflared tunnel route dns devops-pipeline grafana.your-domain.com
cloudflared tunnel route dns devops-pipeline "*.apps.your-domain.com"

# Запуск как сервис
sudo cloudflared service install
sudo systemctl start cloudflared
sudo systemctl enable cloudflared
4.7 Настройка сети на Ngrok Gateway
bashsudo tee /etc/netplan/50-cloud-init.yaml > /dev/null <<'EOF'
network:
  version: 2
  ethernets:
    ens18:
      dhcp4: no
      addresses:
        - 10.0.10.60/24
      routes:
        - to: 0.0.0.0/0
          via: 10.0.10.1
      nameservers:
        addresses:
          - 192.168.100.53
          - 8.8.8.8
        search:
          - devops.local
    ens19:
      dhcp4: no
      addresses:
        - 192.168.100.60/24
      nameservers:
        addresses:
          - 192.168.100.53
        search:
          - devops.local
EOF

sudo netplan apply
Проверка:
bash# Проверка NAT
ping -c 3 8.8.8.8

# Проверка DNS
dig jenkins.devops.local

# Проверка маршрутизации
ip route show

Этап 5: Создание VM через Terraform
5.1 Структура Terraform проекта
Создайте структуру:
bashmkdir -p ~/devops-pipeline-proxmox/terraform
cd ~/devops-pipeline-proxmox/terraform
5.2 Terraform providers.tf
hclterraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "2.9.14"
    }
  }
}

provider "proxmox" {
  pm_api_url      = var.proxmox_api_url
  pm_user         = var.proxmox_user
  pm_password     = var.proxmox_password
  pm_tls_insecure = true
}
5.3 Terraform variables.tf
hclvariable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
  default     = "https://10.0.10.200:8006/api2/json"
}

variable "proxmox_user" {
  description = "Proxmox user"
  type        = string
  default     = "root@pam"
}

variable "proxmox_password" {
  description = "Proxmox password"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}

variable "target_node" {
  description = "Proxmox node name"
  type        = string
  default     = "pve"
}

variable "dns_server" {
  description = "Internal DNS server IP"
  type        = string
  default     = "192.168.100.53"
}

variable "gateway_ip" {
  description = "Internal gateway IP (Ngrok)"
  type        = string
  default     = "192.168.100.60"
}
5.4 Terraform main.tf
hcl# K3s Master Node
resource "proxmox_vm_qemu" "k3s_master" {
  name        = "k3s-master"
  target_node = var.target_node
  clone       = "ubuntu-2204-template"
  
  cores   = 4
  memory  = 8192
  
  disk {
    size    = "50G"
    type    = "scsi"
    storage = "local-lvm"
  }
  
  network {
    model  = "virtio"
    bridge = "vmbr1"
  }
  
  ipconfig0  = "ip=192.168.100.10/24,gw=${var.gateway_ip}"
  nameserver = var.dns_server
  searchdomain = "devops.local"
  ciuser     = "ubuntu"
  sshkeys    = var.ssh_public_key
  
  # Ожидание готовности
  agent = 1
}

# K3s Worker Nodes
resource "proxmox_vm_qemu" "k3s_workers" {
  count       = 2
  name        = "k3s-worker${count.index + 1}"
  target_node = var.target_node
  clone       = "ubuntu-2204-template"
  
  cores   = 4
  memory  = 8192
  
  disk {
    size    = "50G"
    type    = "scsi"
    storage = "local-lvm"
  }
  
  network {
    model  = "virtio"
    bridge = "vmbr1"
  }
  
  ipconfig0  = "ip=192.168.100.${11 + count.index}/24,gw=${var.gateway_ip}"
  nameserver = var.dns_server
  searchdomain = "devops.local"
  ciuser     = "ubuntu"
  sshkeys    = var.ssh_public_key
  
  agent = 1
}

# Jenkins Server
resource "proxmox_vm_qemu" "jenkins" {
  name        = "jenkins"
  target_node = var.target_node
  clone       = "ubuntu-2204-template"
  
  cores   = 4
  memory  = 8192
  
  disk {
    size    = "60G"
    type    = "scsi"
    storage = "local-lvm"
  }
  
  network {
    model  = "virtio"
    bridge = "vmbr1"
  }
  
  ipconfig0  = "ip=192.168.100.20/24,gw=${var.gateway_ip}"
  nameserver = var.dns_server
  searchdomain = "devops.local"
  ciuser     = "ubuntu"
  sshkeys    = var.ssh_public_key
  
  agent = 1
}

# SonarQube Server
resource "proxmox_vm_qemu" "sonarqube" {
  name        = "sonarqube"
  target_node = var.target_node
  clone       = "ubuntu-2204-template"
  
  cores   = 2
  memory  = 4096
  
  disk {
    size    = "30G"
    type    = "scsi"
    storage = "local-lvm"
  }
  
  network {
    model  = "virtio"
    bridge = "vmbr1"
  }
  
  ipconfig0  = "ip=192.168.100.30/24,gw=${var.gateway_ip}"
  nameserver = var.dns_server
  searchdomain = "devops.local"
  ciuser     = "ubuntu"
  sshkeys    = var.ssh_public_key
  
  agent = 1
}

# Nexus Server
resource "proxmox_vm_qemu" "nexus" {
  name        = "nexus"
  target_node = var.target_node
  clone       = "ubuntu-2204-template"
  
  cores   = 2
  memory  = 4096
  
  disk {
    size    = "40G"
    type    = "scsi"
    storage = "local-lvm"
  }
  
  network {
    model  = "virtio"
    bridge = "vmbr1"
  }
  
  ipconfig0  = "ip=192.168.100.31/24,gw=${var.gateway_ip}"
  nameserver = var.dns_server
  searchdomain = "devops.local"
  ciuser     = "ubuntu"
  sshkeys    = var.ssh_public_key
  
  agent = 1
}

# Harbor Registry
resource "proxmox_vm_qemu" "harbor" {
  name        = "harbor"
  target_node = var.target_node
  clone       = "ubuntu-2204-template"
  
  cores   = 2
  memory  = 4096
  
  disk {
    size    = "50G"
    type    = "scsi"
    storage = "local-lvm"
  }
  
  network {
    model  = "virtio"
    bridge = "vmbr1"
  }
  
  ipconfig0  = "ip=192.168.100.32/24,gw=${var.gateway_ip}"
  nameserver = var.dns_server
  searchdomain = "devops.local"
  ciuser     = "ubuntu"
  sshkeys    = var.ssh_public_key
  
  agent = 1
}

# Monitoring Server
resource "proxmox_vm_qemu" "monitoring" {
  name        = "monitoring"
  target_node = var.target_node
  clone       = "ubuntu-2204-template"
  
  cores   = 4
  memory  = 6144
  
  disk {
    size    = "40G"
    type    = "scsi"
    storage = "local-lvm"
  }
  
  network {
    model  = "virtio"
    bridge = "vmbr1"
  }
  
  ipconfig0  = "ip=192.168.100.40/24,gw=${var.gateway_ip}"
  nameserver = var.dns_server
  searchdomain = "devops.local"
  ciuser     = "ubuntu"
  sshkeys    = var.ssh_public_key
  
  agent = 1
}
5.5 Terraform outputs.tf
hcloutput "k3s_master_ip" {
  value = proxmox_vm_qemu.k3s_master.default_ipv4_address
  description = "K3s master node IP"
}

output "k3s_workers_ips" {
  value = proxmox_vm_qemu.k3s_workers[*].default_ipv4_address
  description = "K3s worker nodes IPs"
}

output "jenkins_ip" {
  value = proxmox_vm_qemu.jenkins.default_ipv4_address
  description = "Jenkins server IP"
}

output "sonarqube_ip" {
  value = proxmox_vm_qemu.sonarqube.default_ipv4_address
  description = "SonarQube server IP"
}

output "nexus_ip" {
  value = proxmox_vm_qemu.nexus.default_ipv4_address
  description = "Nexus repository IP"
}

output "harbor_ip" {
  value = proxmox_vm_qemu.harbor.default_ipv4_address
  description = "Harbor registry IP"
}

output "monitoring_ip" {
  value = proxmox_vm_qemu.monitoring.default_ipv4_address
  description = "Monitoring server IP"
}

output "gateway_ip" {
  value = var.gateway_ip
  description = "Internal gateway IP (Ngrok/Cloudflare)"
}

output "dns_server" {
  value = var.dns_server
  description = "Internal DNS server IP"
}

output "connection_info" {
  value = <<-EOT
    
    === Connection Information ===
    
    1. Connect to Jumphost:
       ssh ubuntu@10.0.10.102
    
    2. Or connect directly to internal VM:
       ssh -J ubuntu@10.0.10.102 ubuntu@192.168.100.10
    
    3. DNS Server: ${var.dns_server}
    4. Gateway: ${var.gateway_ip}
    
    All internal services use .devops.local domain
    EOT
}
5.6 Terraform terraform.tfvars
hclproxmox_api_url  = "https://10.0.10.200:8006/api2/json"
proxmox_user     = "root@pam"
proxmox_password = "YOUR_PROXMOX_PASSWORD"
ssh_public_key   = <<-EOT
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAA... your-public-key-here
EOT
target_node      = "pve"
dns_server       = "192.168.100.53"
gateway_ip       = "192.168.100.60"
5.7 Развертывание VM
bash# Инициализация Terraform
terraform init

# Проверка плана
terraform plan

# Применение конфигурации
terraform apply

# Подтвердите: yes
⏱️ Время выполнения: ~15 минут
Проверьте созданные VM:
bashterraform output

# Тест подключения
ssh -J ubuntu@10.0.10.102 ubuntu@192.168.100.10

# Проверка DNS
ssh -J ubuntu@10.0.10.102 ubuntu@192.168.100.10
dig jenkins.devops.local
ping -c 3 jenkins.devops.local

# Проверка интернета (через NAT)
ping -c 3 8.8.8.8
curl -I https://google.com

Последующие этапы
Далее следуйте оригинальной инструкции начиная с:

Этап 3: Установка K3s кластера (теперь это будет Этап 6)
Установка MetalLB
Traefik Ingress
Установка инструментов (Jenkins, SonarQube и т.д.)
Настройка Jenkins Pipeline
Мониторинг
И так далее...

Важные отличия:

DNS: Используйте jenkins.devops.local вместо IP адресов
Gateway: Все VM используют 192.168.100.60 как шлюз
Доступ: Только через Jumphost (ssh -J)
Внешний доступ: Только через Ngrok/Cloudflare туннель


🔐 Безопасность изолированной сети
Преимущества архитектуры
✅ Полная изоляция - рабочие VM не имеют прямого доступа в интернет
✅ Контролируемый NAT - весь исходящий трафик через один gateway
✅ Single Entry Point - доступ только через Jumphost
✅ Внутренний DNS - разрешение имен без утечки запросов
✅ Безопасные туннели - внешний доступ только через HTTPS
✅ Audit Trail - все подключения логируются на Jumphost
Дополнительные меры безопасности
bash# На Jumphost - ограничение SSH
sudo tee -a /etc/ssh/sshd_config <<'EOF'
# Security hardening
PermitRootLogin no
PasswordAuthentication no
MaxAuthTries 3
MaxSessions 5
ClientAliveInterval 300
ClientAliveCountMax 2

# Logging
LogLevel VERBOSE
EOF

sudo systemctl restart sshd

# Установка fail2ban
sudo apt install -y fail2ban

sudo tee /etc/fail2ban/jail.local <<'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
EOF

sudo systemctl enable fail2ban
sudo systemctl start fail2ban

📊 Проверка инфраструктуры
Чеклист готовности базовой инфраструктуры

 DNS Server запущен и отвечает
 Jumphost настроен и доступен
 Ngrok Gateway настроен и работает NAT
 Все VM созданы через Terraform
 DNS резолвит все внутренние имена
 Интернет работает через NAT
 SSH через Jumphost работает
 Ngrok туннели активны

Тест DNS
bash# На любой внутренней VM
dig jenkins.devops.local
dig k3s-master.devops.local
dig apps.devops.local

# Reverse DNS
dig -x 192.168.100.20
Тест сети
bash# На любой внутренней VM
ping -c 3 jenkins.devops.local
ping -c 3 8.8.8.8
curl -I https://google.com
traceroute 8.8.8.8  # Должен идти через 192.168.100.60

❓ FAQ (Дополнения)
Q: Почему изолированная сеть лучше?
A: Изолированная сеть обеспечивает:

Полный контроль над трафиком
Защиту от внешних атак
Соответствие корпоративным стандартам безопасности
Простоту аудита и мониторинга
Возможность легкой блокировки исходящих подключений

Q: Что делать если NAT не работает?
A: Проверьте на Ngrok Gateway:
bash# IP forwarding
cat /proc/sys/net/ipv4/ip_forward  # Должно быть 1

# Iptables правила
sudo iptables -t nat -L -n -v

# Routing
ip route show

# Тест с внутренней VM
ssh -J jumphost ubuntu@192.168.100.20
ping 8.8.8.8
Q: Как добавить новую VM в DNS?
A: На DNS сервере:
bashsudo vim /etc/bind/db.devops.local
# Добавьте: newvm  IN  A  192.168.100.X

sudo vim /etc/bind/db.192.168.100
# Добавьте: X  IN  PTR  newvm.devops.local.

# Увеличьте Serial в обоих файлах
# Перезапустите
sudo systemctl restart named
sudo rndc reload
Q: Можно ли обойтись без Jumphost?
A: Технически да, но не рекомендуется для production:

Jumphost - стандарт безопасности
Централизованная точка аудита
Простота управления доступами
Дополнительный уровень защиты
