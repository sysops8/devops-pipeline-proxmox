# The Ultimate CI/CD Corporate DevOps Pipeline Project

## Полное руководство по развертыванию enterprise-grade CI/CD инфраструктуры в Proxmox с изолированной сетью

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-K3s-326CE5?logo=kubernetes)](https://k3s.io/)
[![Jenkins](https://img.shields.io/badge/Jenkins-CI%2FCD-D24939?logo=jenkins)](https://www.jenkins.io/)
[![Terraform](https://img.shields.io/badge/Terraform-IaC-7B42BC?logo=terraform)](https://www.terraform.io/)

<img width="1150" height="824" alt="image" src="https://github.com/user-attachments/assets/a7ac7ef6-d24a-4506-8dcf-cd5088571936" />


## 📋 Содержание

- [О проекте](#о-проекте)
- [Архитектура](#архитектура)
- [Требования](#требования)
- [Быстрый старт](#быстрый-старт)
- [Детальная установка](#-детальная-установка)
  - [Этап 1: Сетевая инфраструктура](#этап-1-сетевая-инфраструктура)
  - [Этап 2: DNS Server](#этап-2-dns-server)
  - [Этап 3: Jumphost](#этап-3-jumphost)
  - [Этап 4: Ngrok Tunnel](#этап-4-ngrok-tunnel)
  - [Этап 5: Создание VM через Terraform](#этап-5-создание-vm-через-terraform)
  - [Этап 6: Установка K3s кластера](#этап-3-установка-k3s-кластера)
  - [Этап 7: MetalLB Load Balancer](#этап-4-установка-metallb-load-balancer)
  - [Этап 8: Traefik Ingress](#этап-5-установка-traefik-ingress)
  - [Этап 9: Настройка внешнего доступа через Cloudflare Tunnel](#этап-6-настройка-внешнего-доступа-через-cloudflare-tunnel)
  - [Этап 10: Установка инструментов - jenkins, sonarqube, nexus, harbor, monitoring server](#этап-7-установка-инструментов-на-vm)
  - [Этап 10.1 Jenkins Server (192.168.100.20 порт 8080)](#10.1-Jenkins-Server)
  - [Этап 10.2 SonarQube Server](#10.2-sonarqube-server)
  - [Этап 10.3 Nexus Repository](#10.3-Nexus-Repository)
  - [Этап 10.4 Harbor Registry](#10.4-Harbor-Registry)
  - [Этап 10.5 Monitoring Server](#10.5-Monitoring-Server)
  - [Этап 11: Настройка Jenkins](#этап-8-настройка-jenkins-pipeline)
  - [Этап 12: Jenkins Pipeline](#этап-9-создание-jenkins-pipeline)
  - [Этап 13: Мониторинг Jenkins](#этап-10-установка-мониторинга-на-jenkins)
  - [Этап 14: Безопасность K8s](#этап-11-настройка-безопасности-k8s)
  - [Этап 15: Запуск Pipeline](#этап-12-запуск-pipeline)
  - [Этап 16: Проверка результатов](#этап-13-проверка-результатов)
  - [Этап 17: Оптимизация](#этап-14-оптимизация-и-best-practices)
  - [Этап 18: Troubleshooting](#этап-15-troubleshooting)
  - [Этап 19: Финальная проверка](#этап-16-финальная-проверка)
- [Использование](#использование)
- [Мониторинг](#мониторинг)
- [Backup и Recovery](#backup-и-recovery)
- [FAQ](#faq)
- [Contributing](#contributing)
- [Лицензия](#лицензия)
- [Безопасность изолированной сети](#-безопасность-изолированной-сети)
- [Проверка инфраструктуры](#-проверка-инфраструктуры)

---

## 🎯 О проекте

Это руководство представляет собой полную реализацию корпоративного CI/CD pipeline на базе Proxmox с изолированной сетевой архитектурой. Проект создан для закрепления навыков DevOps и демонстрации в портфолио/резюме.

### Ключевые особенности архитектуры

✅ **Полностью изолированная сеть** - внутренний контур без прямого доступа извне  
✅ **Jumphost** - единственная точка входа для администрирования  
✅ **DNS сервер** - внутреннее разрешение имен (BIND9)  
✅ **NAT Gateway** - контролируемый доступ в интернет через Ngrok/Cloudflare  
✅ **Безопасный внешний доступ** - только через туннель  
✅ **Production-ready архитектура** - соответствие корпоративным стандартам  

### Что вы получите

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

## 🗺️ Архихитектура

```
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
```

### Сетевая топология

**Внешняя сеть (vmbr0) - 10.0.10.0/24:**
- Доступ в интернет
- Jumphost (10.0.10.102)
- Ngrok Gateway (10.0.10.60)
- DNS Server (10.0.10.53)

**Изолированная сеть (vmbr1) - 192.168.100.0/24:**
- Полная изоляция от прямого доступа
- Все рабочие VM
- Доступ в интернет только через Ngrok NAT
- Внутренний DNS

### Потоки трафика

```mermaid
graph TB
    A[Admin] -->|SSH| B[Jumphost<br/>10.0.10.102]
    B -->|SSH| C[Internal VMs<br/>192.168.100.x]
    
    C -->|Internet| D[Ngrok Gateway<br/>192.168.100.60]
    D -->|NAT| E[Internet]
    
    F[External Users] -->|HTTPS| G[Ngrok/Cloudflare]
    G -->|Tunnel| D
    D -->|Forward| H[K8s Ingress<br/>192.168.100.100]
    
    C -->|DNS| I[BIND9<br/>192.168.100.53]
    I -->|Upstream| J[8.8.8.8]
```

## 💻 Требования

### Аппаратные требования

**Proxmox хост:**
- CPU: 12+ cores (Ryzen 3900 или аналог)
- RAM: 64GB
- Storage: 2TB HDD + 2TB SSD
- Network: 2x 1Gbps (минимум 1x)

**Windows машина (для управления):**
- CPU: 4+ cores
- RAM: 16GB+
- Storage: 100GB

### Программные требования

**На Proxmox:**
- Proxmox VE 8.0+
- Доступ через SSH

**На Windows машине:**
- WSL2 или Git Bash
- Terraform >= 1.5.0
- kubectl >= 1.28.0
- SSH client

### Сетевые требования

- Внешняя сеть: 10.0.10.0/24 (существующая)
- Изолированная сеть: 192.168.100.0/24 (будет создана)
- Интернет доступ с серым IP
- Ngrok или Cloudflare аккаунт (бесплатный)

### Необходимые аккаунты

- GitHub (для репозитория)
- Ngrok или Cloudflare (для туннеля)
- Gmail (для email уведомлений)

## 🚀 Быстрый старт

```bash
# 1. Клонируйте репозиторий
git clone https://github.com/sysops8/devops-pipeline-proxmox.git
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
```

⏱️ **Общее время установки: ~3-4 часа**

## 📚 Детальная установка

### Этап 1: Подготовка сетевой инфраструктуры

#### 1.1 Создание изолированной сети в Proxmox

Подключитесь к Proxmox хосту:
```bash
ssh root@10.0.10.200
```

Создайте новый bridge для изолированной сети БЕЗ физического интерфейса:
```bash
cat >> /etc/network/interfaces <<EOF

# Isolated DevOps Network (NO DIRECT INTERNET)
auto vmbr1
iface vmbr1 inet static
    address 192.168.100.1/24
    bridge-ports none
    bridge-stp off
    bridge-fd 0
    # NO NAT/MASQUERADE - полная изоляция!
EOF
```

Примените изменения:
```bash
ifreload -a
```

Проверьте созданный bridge:
```bash
ip addr show vmbr1
# Должно показать: 192.168.100.1/24

# Проверка, что нет маршрутизации
iptables -t nat -L POSTROUTING -n -v | grep 192.168.100
# Должно быть пусто!
```

#### 1.2 План виртуальных машин с двумя NIC

| Имя VM | CPU | RAM | Disk | IP (vmbr0) | IP (vmbr1) | Назначение |
|--------|-----|-----|------|------------|------------|------------|
| jumphost | 2 | 2GB | 10GB | 10.0.10.102 | 192.168.100.5 | SSH Gateway |
| ngrok-tunnel | 2 | 2GB | 10GB | 10.0.10.60 | 192.168.100.60 | NAT Gateway + Tunnel |
| dns-server | 2 | 2GB | 10GB | 10.0.10.53 | 192.168.100.53 | BIND9 DNS |
| k3s-master | 4 | 8GB | 50GB | - | 192.168.100.10 | K3s Control Plane |
| k3s-worker1 | 4 | 8GB | 50GB | - | 192.168.100.11 | K3s Worker Node |
| k3s-worker2 | 4 | 8GB | 50GB | - | 192.168.100.12 | K3s Worker Node |
| jenkins | 4 | 8GB | 60GB | - | 192.168.100.20 | Jenkins CI/CD |
| sonarqube | 2 | 4GB | 30GB | - | 192.168.100.30 | Code Quality |
| nexus | 2 | 4GB | 40GB | - | 192.168.100.31 | Artifact Repository |
| harbor | 2 | 4GB | 50GB | - | 192.168.100.32 | Container Registry |
| monitoring | 4 | 6GB | 40GB | - | 192.168.100.40 | Prometheus+Grafana |

**Итого:** 30 vCPU, 52GB RAM, 410GB Storage

#### 1.3 Создание Ubuntu Cloud-Init Template

На Proxmox хосте шаблон Ubuntu c ID 9000, из него будем создавать все ВМ.


### Этап 2: Установка DNS сервера

#### 2.1 Создание DNS Server VM

DNS сервер - первая VM, которую нужно создать, так как он будет использоваться всеми остальными.


#### 2.2 Установка и настройка BIND9

Подключитесь к DNS серверу:
```bash
ssh ubuntu@10.0.10.53
```

Установите BIND9:
```bash
sudo apt update
sudo apt install -y bind9 bind9utils bind9-doc dnsutils

# Включите автозапуск
sudo systemctl enable named
```

#### 2.3 Настройка зон DNS

Создайте конфигурацию BIND9:
```bash
sudo tee /etc/bind/named.conf.options > /dev/null <<'EOF'
options {
    directory "/var/cache/bind";

    # Слушаем на обоих интерфейсах
    listen-on { localhost; 10.0.10.53; 192.168.100.53; };
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
```

Создайте зону для внутренней сети:
```bash
sudo tee /etc/bind/named.conf.local > /dev/null <<'EOF'
# Прямая зона для local.lab
zone "local.lab" {
    type master;
    file "/etc/bind/db.local.lab";
    allow-update { none; };
};

# Обратная зона для 192.168.100.0/24
zone "100.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/db.192.168.100";
    allow-update { none; };
};
EOF
```

Создайте файл прямой зоны:
```bash
sudo tee /etc/bind/db.local.lab > /dev/null <<'EOF'
$TTL    604800
@       IN      SOA     dns.local.lab. admin.local.lab. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      dns.local.lab.
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
```

Создайте файл обратной зоны:
```bash
sudo tee /etc/bind/db.192.168.100 > /dev/null <<'EOF'
$TTL    604800
@       IN      SOA     dns.local.lab. admin.local.lab. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      dns.local.lab.

53      IN      PTR     dns.local.lab.
5       IN      PTR     jumphost.local.lab.
60      IN      PTR     ngrok.local.lab.

10      IN      PTR     k3s-master.local.lab.
11      IN      PTR     k3s-worker1.local.lab.
12      IN      PTR     k3s-worker2.local.lab.

20      IN      PTR     jenkins.local.lab.
30      IN      PTR     sonarqube.local.lab.
31      IN      PTR     nexus.local.lab.
32      IN      PTR     harbor.local.lab.
40      IN      PTR     monitoring.local.lab.

100     IN      PTR     apps.local.lab.
EOF
```

Проверьте конфигурацию и запустите:
```bash
# Проверка конфигурации
sudo named-checkconf
sudo named-checkzone local.lab /etc/bind/db.local.lab
sudo named-checkzone 100.168.192.in-addr.arpa /etc/bind/db.192.168.100

# Перезапуск
sudo systemctl restart named
sudo systemctl status named

# Проверка
dig @localhost jenkins.local.lab
dig @localhost -x 192.168.100.20
```

#### 2.4 Настройка netplan для статических IP

```bash
sudo tee /etc/netplan/00-installer-config.yaml > /dev/null <<'EOF'
network:
  version: 2
  ethernets:
    eth0:
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
    eth1:
      dhcp4: no
      addresses:
        - 192.168.100.53/24
      nameservers:
        addresses:
          - 127.0.0.1
EOF

# Установка зависимости для netplan и настройка прав на файл сетевой конфигурации
sudo apt install -y openvswitch-switch
sudo chmod 600 /etc/netplan/00-installer-config.yaml
sudo netplan apply
```

### Этап 3: Настройка Jumphost

#### 3.1 Создание Jumphost VM
Создайте ВМ jumphost на Proxmox.

#### 3.2 Настройка Jumphost

Подключитесь:
```bash
ssh ubuntu@10.0.10.102
```

Настройте netplan:
```bash
sudo tee /etc/netplan/00-installer-config.yaml > /dev/null <<'EOF'
network:
  version: 2
  ethernets:
    eth0:
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
          - local.lab
    eth1:
      dhcp4: no
      addresses:
        - 192.168.100.5/24
      nameservers:
        addresses:
          - 192.168.100.53
        search:
          - local.lab
EOF

# Установка зависимости для netplan и настройка прав на файл сетевой конфигурации
sudo apt install -y openvswitch-switch
sudo chmod 600 /etc/netplan/00-installer-config.yaml
sudo netplan apply
```

Установите полезные инструменты:
```bash
sudo apt update
sudo apt install -y htop curl wget git vim tmux net-tools dnsutils

# Проверка DNS
dig jenkins.local.lab
# Должен вернуть 192.168.100.20
```

#### 3.3 Настройка SSH конфигурации

На вашей локальной машине создайте `~/.ssh/config`:
```bash
# Jumphost
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
```

Теперь вы можете подключаться напрямую:
```bash
ssh k3s-master
ssh jenkins
```
## 🔐 Безопасность изолированной сети

### Преимущества архитектуры с jumphost

✅ **Полная изоляция** - рабочие VM не имеют прямого доступа в интернет  
✅ **Контролируемый NAT** - весь исходящий трафик через один gateway  
✅ **Single Entry Point** - доступ только через Jumphost  
✅ **Внутренний DNS** - разрешение имен без утечки запросов  
✅ **Безопасные туннели** - внешний доступ только через HTTPS  
✅ **Audit Trail** - все подключения логируются на Jumphost  

### Дополнительные меры безопасности для jumphost

```bash
# На Jumphost - ограничение SSH
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
```

### Этап 4: Настройка Ngrok Tunnel

#### 4.1 Создание Ngrok Gateway VM
Создайте Ngrok Gateway VM

#### 4.2 Установка Ngrok

Подключитесь через Jumphost:
```bash
ssh ubuntu@192.168.100.60
```

Установите Ngrok:
```bash
# Скачивание
curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | \
  sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null && \
  echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | \
  sudo tee /etc/apt/sources.list.d/ngrok.list && \
  sudo apt update && sudo apt install ngrok

# Авторизация (получите токен на https://dashboard.ngrok.com)
ngrok config add-authtoken YOUR_NGROK_TOKEN
```

#### 4.3 Настройка NAT для внутренней сети

Включите IP forwarding:
```bash
sudo tee -a /etc/sysctl.conf > /dev/null <<'EOF'
# Enable IP forwarding for NAT
net.ipv4.ip_forward = 1
net.ipv4.conf.all.forwarding = 1
EOF

sudo sysctl -p
```

Настройте iptables NAT:
```bash
sudo tee /etc/iptables-nat.sh > /dev/null <<'EOF'
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
iptables -t nat -A POSTROUTING -s 192.168.100.0/24 -o eth0 -j MASQUERADE

# Allow forwarding from internal network
iptables -A FORWARD -s 192.168.100.0/24 -o eth0 -j ACCEPT

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
```

Сохраните правила для автозапуска:
```bash
sudo apt install -y iptables-persistent
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
```

#### 4.4 Настройка Ngrok конфигурации

Создайте конфигурацию Ngrok:
```bash
mkdir -p ~/.config/ngrok

tee ~/.config/ngrok/ngrok.yml > /dev/null <<'EOF'
version: "2"
authtoken: YOUR_NGROK_TOKEN

tunnels:
  jenkins:
    proto: http
    addr: 192.168.100.20:8080
    host_header: "jenkins.local.lab"

#  boardgame:
#    proto: http
#    addr: 192.168.100.100:80
EOF
```

#### 4.5 Настройка Ngrok как systemd сервиса

```bash
sudo tee /etc/systemd/system/ngrok.service > /dev/null <<'EOF'
[Unit]
Description=Ngrok Tunnel Service
After=network.target

[Service]
Type=simple
User=admin
WorkingDirectory=/home/admin
ExecStart=/usr/local/bin/ngrok start --all --config=/home/admin/.config/ngrok/ngrok.yml
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
```

### Настройка DNS на всех VM


#### Ручная настройка jumphost

```bash
ssh admin@jumphost.local.lab

sudo systemctl disable systemd-resolved
sudo systemctl stop systemd-resolved
sudo rm -f /etc/resolv.conf

sudo bash -c 'cat > /etc/resolv.conf <<EOF
nameserver 192.168.100.53
nameserver 8.8.8.8
search local.lab
EOF'

sudo chattr +i /etc/resolv.conf

# Netplan для jumphost (2 интерфейса)
sudo bash -c 'cat > /etc/netplan/00-installer-config.yaml <<EOF
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: no
      addresses: [10.0.10.102/24]
      routes:
        - to: 0.0.0.0/0
          via: 10.0.10.1
      nameservers:
        addresses: [192.168.100.53, 8.8.8.8]
        search: [local.lab]
    eth1:
      dhcp4: no
      addresses: [192.168.100.5/24]
      nameservers:
        addresses: [192.168.100.53]
        search: [local.lab]
EOF'

sudo apt install -y openvswitch-switch
sudo chmod 600 /etc/netplan/00-installer-config.yaml
sudo netplan apply

# Проверка
ping -c 2 google.com
nslookup k3s-master.local.lab
```

Создайте скрипт для автоматизации:

```bash
# На jumphost создайте файл set-dns.sh
cat > /tmp/set-dns.sh <<'EOF'
#!/bin/bash

echo "Настройка DNS и маршрутизации..."

# Получение текущего IP
CURRENT_IP=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

# Определение gateway
if [[ $CURRENT_IP == 192.168.100.* ]]; then
    GATEWAY="192.168.100.60"  # ngrok-tunnel как gateway
    NETMASK="24"
elif [[ $CURRENT_IP == 10.0.10.* ]]; then
    GATEWAY="10.0.10.1"
    NETMASK="24"
else
    echo "Неизвестная сеть!"
    exit 1
fi

# Остановка systemd-resolved
sudo systemctl disable systemd-resolved 2>/dev/null
sudo systemctl stop systemd-resolved 2>/dev/null
sudo rm -f /etc/resolv.conf

# Создание resolv.conf
sudo bash -c 'cat > /etc/resolv.conf <<EOL
nameserver 192.168.100.53
nameserver 8.8.8.8
search local.lab
EOL'

sudo chattr +i /etc/resolv.conf

# Обновление netplan
if [ -f /etc/netplan/00-installer-config.yaml ]; then
    sudo bash -c "cat > /etc/netplan/00-installer-config.yaml <<EOL
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: no
      addresses: [${CURRENT_IP}/${NETMASK}]
      routes:
        - to: 0.0.0.0/0
          via: ${GATEWAY}
      nameservers:
        addresses: [192.168.100.53, 8.8.8.8]
        search: [local.lab]
EOL"
    sudo netplan apply
fi

echo "Настройка завершена!"
echo "Gateway: $GATEWAY"
echo "DNS: 192.168.100.53"

# Тестирование
echo ""
echo "Тестирование DNS..."
nslookup k3s-master.local.lab

echo ""
echo "Тестирование интернета..."
ping -c 2 8.8.8.8
ping -c 2 google.com
EOF

chmod +x /tmp/set-dns.sh
```

#### Применение на всех VM

```bash
# На jumphost создайте список хостов (только внутренние VM)
cat > /tmp/internal-hosts.txt <<EOF
k3s-master.local.lab
k3s-worker1.local.lab
k3s-worker2.local.lab
jenkins.local.lab
sonarqube.local.lab
nexus.local.lab
harbor.local.lab
monitoring.local.lab
EOF

# Применение скрипта на всех VM
for host in $(cat /tmp/internal-hosts.txt); do
    echo "===================================="
    echo "Настройка $host..."
    scp /tmp/set-dns.sh admin@${host}:/tmp/
    ssh admin@${host} "sudo bash /tmp/set-dns.sh"
    echo ""
done

# Для VM с двумя интерфейсами (jumphost уже настроен вручную)
```


### Проверка доступности интернета

На любой VM в сети 192.168.100.0/24:

```bash
# Проверка маршрутов
ip route show
# Должно быть: default via 192.168.100.50 dev eth0

# Проверка DNS
nslookup google.com

# Проверка интернета
ping -c 4 8.8.8.8
ping -c 4 google.com

# Установка пакетов
sudo apt update
sudo apt install -y curl wget vim
```


#### 4.6 Альтернатива: Cloudflare Tunnel

Если предпочитаете Cloudflare:
```bash
# Установка cloudflared
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
```

#### 4.7 Настройка сети на Ngrok Gateway

```bash
sudo tee /etc/netplan/50-cloud-init.yaml > /dev/null <<'EOF'
network:
  version: 2
  ethernets:
    eth0:
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
          - local.lab
    eth1:
      dhcp4: no
      addresses:
        - 192.168.100.60/24
      nameservers:
        addresses:
          - 192.168.100.53
        search:
          - local.lab
EOF

# Установка зависимости для netplan и настройка прав на файл сетевой конфигурации
sudo apt install -y openvswitch-switch
sudo chmod 600 /etc/netplan/50-cloud-init.yaml
sudo netplan apply
```

Проверка:
```bash
# Проверка NAT
ping -c 3 8.8.8.8

# Проверка DNS
dig jenkins.local.lab

# Проверка маршрутизации
ip route show
```

### Этап 5: Создание VM через Terraform

#### 5.1 Структура Terraform проекта

Настройки Terraform отдельно лежат в папке terraform

#### 5.7 Развертывание VM

```bash
# Инициализация Terraform
terraform init

# Проверка плана
terraform plan

# Применение конфигурации
terraform apply

# Подтвердите: yes
```

⏱️ **Время выполнения: ~15 минут**

Проверьте созданные VM:
```bash
terraform output

# Тест подключения
ssh -J ubuntu@10.0.10.102 ubuntu@192.168.100.10

# Проверка DNS
ssh -J ubuntu@10.0.10.102 ubuntu@192.168.100.10
dig jenkins.local.lab
ping -c 3 jenkins.local.lab

# Проверка интернета (через NAT)
ping -c 3 8.8.8.8
curl -I https://google.com
```


## Этап 6: Установка K3s кластера

### 6.1 Установка K3s Master Node

Подключитесь к master node:

```bash
ssh ubuntu@192.168.100.10
```

Обновите систему:

```bash
sudo apt update && sudo apt upgrade -y
```

Установите K3s (без Traefik, установим позже):

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik --node-ip=192.168.100.10" sh -
export KUBECONFIG=~/.kube/config
sudo mkdir ~/.kube 2> /dev/null
sudo k3s kubectl config view --raw > "$KUBECONFIG"
sudo chmod 600 "$KUBECONFIG"
echo export KUBECONFIG=~/.kube/config  >> ~/.profile
k3s server --tls-san k3s-master.local.lab
```

Получите токен для worker nodes:

```bash
sudo cat /var/lib/rancher/k3s/server/node-token
```
**Сохраните токен!** Пример: `K10abc123def456::server:xyz789`

Проверьте статус:

```bash
sudo systemctl status k3s
sudo kubectl get nodes
```
Возможно еще понадобится отключить проверку SSL для Harbor хоста:
```bash
sudo mkdir -p /etc/rancher/k3s
sudo tee /etc/rancher/k3s/registries.yaml > /dev/null <<EOF
mirrors:
  "harbor.local.lab":
    endpoint:
      - "https://harbor.local.lab"

configs:
  "harbor.local.lab":
    tls:
      insecure_skip_verify: true
EOF

sudo systemctl restart k3s
```
Проверка доступа k3s-master к образу на harbor сервере:
```bash
sudo crictl pull harbor.local.lab/library/myapp:139
```

### 6.2 Подключение Worker Nodes

**На k3s-worker1:**

```bash
ssh ubuntu@192.168.100.11

curl -sfL https://get.k3s.io | K3S_URL=https://192.168.100.10:6443 \
  K3S_TOKEN="YOUR_TOKEN_FROM_MASTER" \
  sh -
```
Возможно еще понадобится отключить проверку SSL для Harbor хоста:
```bash
sudo mkdir -p /etc/rancher/k3s
sudo tee /etc/rancher/k3s/registries.yaml > /dev/null <<EOF
mirrors:
  "harbor.local.lab":
    endpoint:
      - "https://harbor.local.lab"

configs:
  "harbor.local.lab":
    tls:
      insecure_skip_verify: true
EOF

sudo systemctl restart k3s-agent.service
```
Проверка доступа k3s-master к образу на harbor сервере:
```bash
sudo crictl pull harbor.local.lab/library/myapp:139
```
**На k3s-worker2:**

```bash
ssh ubuntu@192.168.100.12

curl -sfL https://get.k3s.io | K3S_URL=https://192.168.100.10:6443 \
  K3S_TOKEN="YOUR_TOKEN_FROM_MASTER" \
  sh -
```
Возможно еще понадобится отключить проверку SSL для Harbor хоста:
```bash
sudo mkdir -p /etc/rancher/k3s
sudo tee /etc/rancher/k3s/registries.yaml > /dev/null <<EOF
mirrors:
  "harbor.local.lab":
    endpoint:
      - "https://harbor.local.lab"

configs:
  "harbor.local.lab":
    tls:
      insecure_skip_verify: true
EOF

sudo systemctl restart k3s-agent.service
```
Проверка доступа k3s-master к образу на harbor сервере:
```bash
sudo crictl pull harbor.local.lab/library/myapp:139
```
### 6.3 Проверка кластера

На master node:

```bash
sudo kubectl get nodes
```

Ожидаемый вывод:

```
NAME          STATUS   ROLES                  AGE   VERSION
k3s-master    Ready    control-plane,master   5m    v1.28.x
k3s-worker1   Ready    <none>                 2m    v1.28.x
k3s-worker2   Ready    <none>                 2m    v1.28.x
```

### 6.4 Настройка Jumphost для управления

SSH в jumphost:

```bash
ssh admin@jumphost.local.lab
```

Установка инструментов:

```bash
# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
kubectl version --client

# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version

# ArgoCD CLI
ARGOCD_VERSION=$(curl -s https://api.github.com/repos/argoproj/argo-cd/releases/latest | grep tag_name | cut -d '"' -f 4)
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_VERSION}/argocd-linux-amd64
chmod +x argocd
sudo mv argocd /usr/local/bin/
argocd version --client

# k9s (TUI для K8s)
K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep tag_name | cut -d '"' -f 4)
wget https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz
tar -xzf k9s_Linux_amd64.tar.gz
sudo mv k9s /usr/local/bin/
rm k9s_Linux_amd64.tar.gz LICENSE README.md

# kubectx и kubens
sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens
```

Копирование kubeconfig:

```bash
mkdir -p ~/.kube

sudo scp admin@k3s-master.local.lab:/etc/rancher/k3s/k3s.yaml ~/.kube/config
# Если ошибка permission denied, от на k3s-master вводим команду sudo chmod 644 /etc/rancher/k3s/k3s.yaml
# После копирования, возвращаем права sudo chmod 600 /etc/rancher/k3s/k3s.yaml

# Замена адреса сервера
sed -i 's/127.0.0.1/k3s-master.local.lab/g' ~/.kube/config

# Установка правильных прав
chmod 600 ~/.kube/config

# Проверка доступа
kubectl get nodes
kubectl cluster-info

# Создание алиасов
cat >> ~/.bashrc <<EOF

# Kubernetes aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgn='kubectl get nodes'
alias kga='kubectl get all'
alias kdp='kubectl describe pod'
alias kl='kubectl logs'
alias kex='kubectl exec -it'
EOF

source ~/.bashrc
```

Тестирование:

```bash
k get nodes
k get pods -A
k9s  # Интерактивный интерфейс
```

---

## Этап 7: Установка MetalLB (Load Balancer)

### 7.1 Установка MetalLB

```bash
# Применяем манифест
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml

# Ждем готовности
kubectl wait --namespace metallb-system \
  --for=condition=ready pod \
  --selector=app=metallb \
  --timeout=90s
```

### 7.2 Конфигурация IP Pool

Создайте файл `metallb-config.yaml`:

```yaml
sudo tee metallb-config.yaml > /dev/null <<EOF
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.100.100-192.168.100.150

---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default
  namespace: metallb-system
spec:
  ipAddressPools:
  - default-pool
EOF
```

Примените конфигурацию:

```bash
kubectl apply -f metallb-config.yaml
```

Проверка:

```bash
kubectl get ipaddresspools -n metallb-system
kubectl get l2advertisements -n metallb-system
```

---

## Этап 8: Установка Traefik Ingress

### 8.1 Установка Helm

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### 8.2 Установка Traefik

```bash
# Добавление репозитория
helm repo add traefik https://traefik.github.io/charts
helm repo update

# Создание namespace
kubectl create namespace traefik

# Установка Traefik
helm install traefik traefik/traefik \
  --namespace traefik \
  --set service.type=LoadBalancer \
  --set ports.web.port=80 \
  --set ports.websecure.port=443
```

### 8.3 Проверка

```bash
kubectl get svc -n traefik

# Вы должны увидеть EXTERNAL-IP из диапазона MetalLB (например, 192.168.100.100)
```

---

## Этап 9: Настройка внешнего доступа через Cloudflare Tunnel

### 9.1 Установка cloudflared на Proxmox хосте

```bash
ssh root@10.0.10.200

# Скачивание
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb

# Аутентификация (откроет браузер)
cloudflared tunnel login

# Создание туннеля
cloudflared tunnel create devops-pipeline
```

**Сохраните:**
- Tunnel ID
- Path to credentials file

### 9.2 Конфигурация туннеля

Создайте файл `/etc/cloudflared/config.yml`:

```yaml
tunnel: YOUR_TUNNEL_ID
credentials-file: /root/.cloudflared/YOUR_TUNNEL_ID.json

ingress:
  # Jenkins
  - hostname: jenkins.your-domain.com
    service: http://192.168.100.20:8080
  
  # SonarQube
  - hostname: sonar.your-domain.com
    service: http://192.168.100.30:9000
  
  # Nexus
  - hostname: nexus.your-domain.com
    service: http://192.168.100.31:8081
  
  # Harbor
  - hostname: harbor.your-domain.com
    service: https://192.168.100.32
    originServerName: harbor.your-domain.com
  
  # Grafana
  - hostname: grafana.your-domain.com
    service: http://192.168.100.40:3000
  
  # Приложения в K8s (wildcard)
  - hostname: "*.apps.your-domain.com"
    service: http://192.168.100.100:80
  
  # Catch-all
  - service: http_status:404
```

### 9.3 Создание DNS записей

```bash
# Для каждого hostname создайте CNAME запись
cloudflared tunnel route dns devops-pipeline jenkins.your-domain.com
cloudflared tunnel route dns devops-pipeline sonar.your-domain.com
cloudflared tunnel route dns devops-pipeline nexus.your-domain.com
cloudflared tunnel route dns devops-pipeline harbor.your-domain.com
cloudflared tunnel route dns devops-pipeline grafana.your-domain.com
cloudflared tunnel route dns devops-pipeline "*.apps.your-domain.com"
```

### 9.4 Запуск туннеля как systemd сервиса

```bash
# Установка сервиса
sudo cloudflared service install

# Запуск
sudo systemctl start cloudflared
sudo systemctl enable cloudflared

# Проверка статуса
sudo systemctl status cloudflared

# Просмотр логов
sudo journalctl -u cloudflared -f
```

**Теперь все ваши сервисы доступны через HTTPS с автоматическими сертификатами!**

---

## Этап 10: Установка инструментов на VM

### 10.1 Jenkins Server (192.168.100.20 порт 8080)

```bash
ssh ubuntu@192.168.100.20

# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu
sudo usermod -aG docker jenkins
sudo usermod -aG docker $USER

# Установка Java 17
sudo apt install -y openjdk-17-jdk

# Установка Jenkins
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt update
sudo apt install -y jenkins

sudo systemctl enable jenkins
sudo systemctl start jenkins
sudo systemctl status jenkins

# Получение initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```
**Доступ:** `http://192.168.100.20:8080`  
**Пароль:** из файла initialAdminPassword (измените после первого входа)

**Установка kubectl:**

```bash
sudo mkdir -p /var/lib/jenkins/.kube
sudo scp admin@k3s-master.local.lab:/etc/rancher/k3s/k3s.yaml /var/lib/jenkins/.kube/config
sudo sed -i 's/127.0.0.1/k3s-master.local.lab/g' /var/lib/jenkins/.kube/config
sudo chown -R jenkins:jenkins /var/lib/jenkins/.kube
sudo chmod 600 /var/lib/jenkins/.kube/config

# Тест
sudo -u jenkins kubectl get nodes
```
Также нужно поменять адрес 127.0.0.1 при загрузке файла в jenkins credentials.

**Установка Trivy:**

```bash
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt update
sudo apt install -y trivy
```

**Установка Sonar cli scaner:**

```bash
wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-7.3.0.5189.zip -O /tmp/sonar-scanner-cli.zip
sudo unzip /tmp/sonar-scanner-cli.zip -d /var/lib/jenkins/tools/hudson.plugins.sonar.SonarRunnerInstallation/sonar-scanner
chown -R jenkins:jenkins /var/lib/jenkins/tools/hudson.plugins.sonar.SonarRunnerInstallation/sonar-scanner
curl -X https://jenkins.local.lab:8080/restart
```
**Установка Maven:**

```bash
sudo apt install -y maven
mvn --version
```

**Доступ к Jenkins:** `https://jenkins.your-domain.com:8080`


### 10.2 SonarQube Server

```bash
ssh ubuntu@192.168.100.30

# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu
sudo apt-get install -y uidmap && dockerd-rootless-setuptool.sh install


# Настройка системы для SonarQube
sudo sysctl -w vm.max_map_count=524288
sudo sysctl -w fs.file-max=131072
echo "vm.max_map_count=524288" | sudo tee -a /etc/sysctl.conf
echo "fs.file-max=131072" | sudo tee -a /etc/sysctl.conf

sudo tee docker-compose.yml > /dev/null <<EOF
services:
  db:
    image: postgres:15
    restart: unless-stopped
    container_name: sonarqube_db
    environment:
      POSTGRES_USER: sonar
      POSTGRES_PASSWORD: sonar
      POSTGRES_DB: sonarqube
  sonarqube:
    image: sonarqube:25.10.0.114319-community
    restart: unless-stopped
    depends_on:
      - db
    environment:
      SONAR_JDBC_URL: jdbc:postgresql://db:5432/sonarqube
      SONAR_JDBC_USERNAME: sonar
      SONAR_JDBC_PASSWORD: sonar
    ports:
      - "9000:9000"

EOF
```
# Запуск SonarQube 
Нужно пождать 3-5 минут
```bash
sudo docker compose up -d
```
**Проверка:**
```bash
sudo docker ps
sudo docker logs -f admin-sonarqube-1
sudo docker logs -f sonarqube_db

```

**Доступ:** `https://sonar.your-domain.com:9000`  
**Логин:** admin/admin (измените после первого входа)

### 10.3 Nexus Repository

```bash
ssh ubuntu@192.168.100.31

# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo apt-get install -y uidmap && dockerd-rootless-setuptool.sh install


# Запуск Nexus
sudo docker run -d \
  --name nexus \
  --restart=unless-stopped \
  -p 8081:8081 \
  -v nexus-data:/nexus-data \
  sonatype/nexus3

# Ожидание запуска (~2 минуты)
sleep 120

# Получение initial admin password
sudo docker exec nexus cat /nexus-data/admin.password; echo
```

**Доступ:** `https://nexus.your-domain.com:8081`  
**Логин:** admin + пароль из команды выше

**Создание репозиториев:**
1. Sign in
2. Server administration (шестеренка) → Repositories → Create repository
3. Создайте: `maven-releases` (maven2 hosted)
4. Создайте: `maven-snapshots` (maven2 hosted)

### 10.4 Harbor Registry

```bash
ssh ubuntu@192.168.100.32

# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка Docker и Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh


# Скачивание Harbor
cd ~
wget https://github.com/goharbor/harbor/releases/download/v2.9.0/harbor-offline-installer-v2.9.0.tgz
tar xzvf harbor-offline-installer-v2.9.0.tgz
cd harbor

# Конфигурация
cp harbor.yml.tmpl harbor.yml
```

Настройка SSL для Harbor:
```bash
# Генерация приватного ключа
mkdir ~/harbor/ssl
cd ~/harbor/
sudo openssl genrsa -out harbor.local.lab.key 2048

# Генерация самоподписанного сертификата
sudo openssl req -new -x509 -key harbor.local.lab.key -out harbor.local.lab.crt -days 3650 -subj "/CN=harbor.local.lab"

# Вариант 2: С дополнительными доменными именами (SAN)
# Создание конфигурационного файла
sudo tee openssl.cnf > /dev/null <<EOF
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
C = KZ
ST = State
L = City
O = Organization
OU = Organizational Unit
CN = harbor.local.lab

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = harbor.local.lab
DNS.2 = localhost
IP.1 = 127.0.0.1
EOF

# Генерация ключа и сертификата
sudo openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
    -keyout harbor.local.lab.key \
    -out harbor.local.lab.crt \
    -config openssl.cnf \
    -extensions v3_req

# 3. Проверка созданных файлов
# Проверить права доступа
sudo ls -la ~/harbor/ssl/

# Проверить содержимое сертификата
sudo openssl x509 -in harbor.local.lab.crt -text -noout
```
Отредактируйте `harbor.yml`:

```bash
nano harbor.yml
```

Измените:

```yaml
hostname: harbor.your-domain.com

# https:
# port: 80
# Закомментируйте HTTPS для начала (настроим через Cloudflare)
# https:
#   port: 443
#   certificate: /your/certificate/path
#   private_key: /your/private/key/path
port: 443
certificate: ~/ssl/harbor/ssl/harbor.local.lab.crt
private_key: ~/ssl/harbor/ssl/harbor.local.lab.key

harbor_admin_password: YourSecurePassword123!

database:
  password: root123

data_volume: /data
```

Установка:

```bash
sudo ./install.sh
```

**Проверка:**

```bash
sudo chmod 666 /var/run/docker.sock
sudo docker-compose ps
```
**Доп. команды:***

Автозапуск Harbor при перезагрузке:
```bash
sed -i 's/restart: always/restart: unless-stopped/' docker-compose.yml
sudo docker-compose down -v
sudo docker-compose up -d

# Создаем systemd unit для запуска docker-compose, по умолчанию рабочий каталог /home/admin/harbor , замените если используйте доугой, где лежит твой docker-compose.yml
sudo tee /etc/systemd/system/harbor.service > /dev/null <<EOF
[Unit]
Description=Harbor Container Registry
Requires=docker.service
After=docker.service network-online.target

[Service]
Type=oneshot
WorkingDirectory=/home/admin/harbor
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down
RemainAfterExit=yes
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable harbor.service
sudo systemctl start harbor.service
sudo systemctl status harbor.service
```
Проверяем запущены ли контейнеры:
```bash
docker ps
```
Примерный вывод:
```
admin@harbor:~/harbor$ docker ps
CONTAINER ID   IMAGE                                COMMAND                  CREATED          STATUS                    PORTS                                                                                NAMES
55b19f819883   goharbor/nginx-photon:v2.9.0         "nginx -g 'daemon of…"   17 minutes ago   Up 17 minutes (healthy)   0.0.0.0:80->8080/tcp, [::]:80->8080/tcp, 0.0.0.0:443->8443/tcp, [::]:443->8443/tcp   nginx
4b6488617048   goharbor/harbor-jobservice:v2.9.0    "/harbor/entrypoint.…"   17 minutes ago   Up 17 minutes (healthy)                                                                                        harbor-jobservice
2b59b7441e8f   goharbor/harbor-core:v2.9.0          "/harbor/entrypoint.…"   17 minutes ago   Up 17 minutes (healthy)                                                                                        harbor-core
098dfa7ebe96   goharbor/redis-photon:v2.9.0         "redis-server /etc/r…"   17 minutes ago   Up 17 minutes (healthy)                                                                                        redis
73e86709a382   goharbor/harbor-db:v2.9.0            "/docker-entrypoint.…"   17 minutes ago   Up 17 minutes (healthy)                                                                                        harbor-db
e3b395132591   goharbor/registry-photon:v2.9.0      "/home/harbor/entryp…"   17 minutes ago   Up 17 minutes (healthy)                                                                                        registry
fb403461790f   goharbor/harbor-registryctl:v2.9.0   "/home/harbor/start.…"   17 minutes ago   Up 17 minutes (healthy)                                                                                        registryctl
4780911e4933   goharbor/harbor-portal:v2.9.0        "nginx -g 'daemon of…"   17 minutes ago   Up 17 minutes (healthy)                                                                                        harbor-portal
002b3655f20f   goharbor/harbor-log:v2.9.0           "/bin/sh -c /usr/loc…"   17 minutes ago   Up 17 minutes (healthy)   127.0.0.1:1514->10514/tcp                                                            harbor-log
```


**Доступ:** `https://harbor.your-domain.com`  
**Логин:** admin/YourSecurePassword123!

**Настройка проекта:**
1. Projects → NEW PROJECT
2. Project Name: `library`
3. Access Level: Public
4. OK

### 10.5 Monitoring Server (192.168.100.40)

```bash
ssh ubuntu@192.168.100.40

# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка Docker и Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo apt install -y docker-compose
sudo apt-get install -y uidmap && dockerd-rootless-setuptool.sh install


# Создание структуры директорий
mkdir -p ~/monitoring/{prometheus,grafana,blackbox}
cd ~/monitoring
```

**Создайте `docker-compose.yml`:**

```yaml
sudo tee docker-compose.yml > /dev/null <<EOF


services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    restart: unless-stopped
    ports:
      - "9090:9090"
    volumes:  
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - ./prometheus/alerts.yml:/etc/prometheus/alerts.yml
      - prometheus_data:/prometheus
      - ./prometheus/k3s-token:/etc/prometheus/k3s-token:ro
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/usr/share/prometheus/console_libraries'
      - '--web.console.templates=/usr/share/prometheus/consoles'

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_INSTALL_PLUGINS=grafana-piechart-panel
    volumes:
      - grafana_data:/var/lib/grafana

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    restart: unless-stopped
    ports:
      - "9100:9100"
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'  # фикс: экранирование $
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro

  blackbox-exporter:
    image: prom/blackbox-exporter:latest
    container_name: blackbox-exporter
    restart: unless-stopped
    ports:
      - "9115:9115"
    volumes:
      - ./blackbox/blackbox.yml:/etc/blackbox_exporter/config.yml
    command:
      - '--config.file=/etc/blackbox_exporter/config.yml'

volumes:
  prometheus_data:
  grafana_data:
EOF
```

**Создайте `prometheus/prometheus.yml`:**

```yaml
sudo tee prometheus/prometheus.yml > /dev/null <<'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'devops-pipeline'
    environment: 'production'

alerting:
  alertmanagers:
    - static_configs:
        - targets: []

rule_files:
  - "alerts.yml"

scrape_configs:
  # Prometheus itself
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # Jenkins
  - job_name: 'jenkins'
    metrics_path: '/prometheus'
    static_configs:
      - targets: ['192.168.100.20:8080']
        labels:
          service: 'jenkins'
    basic_auth:
        username: 'admin'
        password: '11db7e618498a5e0864d7faa2684af7329'

  # Node Exporters
  - job_name: 'node-exporter'
    static_configs:
      - targets:
          - 'node-exporter:9100'
          - '192.168.100.20:9100'  # Jenkins
        labels:
          service: 'system-metrics'

  # Blackbox HTTP probes
  - job_name: 'blackbox-http'
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
          - http://192.168.100.20:8080  # Jenkins
          - http://192.168.100.30:9000  # SonarQube
          - http://192.168.100.31:8081  # Nexus
          - http://192.168.100.100:80   # K8s Apps
        labels:
          service: 'http-probe'
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: blackbox-exporter:9115

  # Kubernetes API Server
  - job_name: 'kubernetes-apiservers'
    kubernetes_sd_configs:
      - role: endpoints
        api_server: https://192.168.100.10:6443
        tls_config:
          insecure_skip_verify: true
        bearer_token_file:  /etc/prometheus/k3s-token
    scheme: https
    tls_config:
      insecure_skip_verify: true
    bearer_token_file:  /etc/prometheus/k3s-token
    relabel_configs:
      - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
        action: keep
        regex: default;kubernetes;https

  # Kubernetes Nodes
  - job_name: 'kubernetes-nodes'
    kubernetes_sd_configs:
      - role: node
        api_server: https://192.168.100.10:6443
        tls_config:
          insecure_skip_verify: true
        bearer_token_file:  /etc/prometheus/k3s-token
    scheme: https
    tls_config:
      insecure_skip_verify: true
    bearer_token_file:  /etc/prometheus/k3s-token

  # Kubernetes Pods
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
        api_server: https://192.168.100.10:6443
        tls_config:
          insecure_skip_verify: true
        bearer_token_file:  /etc/prometheus/k3s-token
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
        action: replace
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: "$1:$2"   # ✅ Ключевая правка: кавычки вокруг подстановки
        target_label: __address__

EOF

```

**Создайте `prometheus/alerts.yml`:**

```yaml
sudo tee prometheus/alerts.yml > /dev/null <<'EOF'
groups:
  - name: application_alerts
    interval: 30s
    rules:
      - alert: ServiceDown
        expr: up{job=~"jenkins|blackbox-http"} == 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Service {{ $labels.job }} is down"
          description: "{{ $labels.instance }} has been down for more than 2 minutes"

      - alert: HighMemoryUsage
        expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage on {{ $labels.instance }}"
          description: "Memory usage above 85% (current: {{ printf \"%.2f\" $value }}%)"

      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
          description: "CPU usage above 80% (current: {{ printf \"%.2f\" $value }}%)"

      - alert: DiskSpaceLow
        expr: (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100 < 15
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Low disk space on {{ $labels.instance }}"
          description: "Disk space below 15% (current: {{ printf \"%.2f\" $value }}%)"

      - alert: PodCrashLooping
        expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Pod {{ $labels.pod }} is crash looping"
          description: "Pod {{ $labels.pod }} in namespace {{ $labels.namespace }} is restarting frequently"
EOF


```

**Создайте `blackbox/blackbox.yml`:**

```yaml
sudo tee blackbox/blackbox.yml > /dev/null <<EOF
modules:
  http_2xx:
    prober: http
    timeout: 5s
    http:
      valid_http_versions: ["HTTP/1.1", "HTTP/2.0"]
      valid_status_codes: []
      method: GET
      no_follow_redirects: false
      fail_if_ssl: false
      fail_if_not_ssl: false
      preferred_ip_protocol: "ip4"
EOF
```

**Получение K3s token для Prometheus:**

```bash
# На jumphost
ssh admin@192.168.100.10
kubectl create serviceaccount prometheus -n kube-system
kubectl create clusterrolebinding prometheus --clusterrole=cluster-admin --serviceaccount=kube-system:prometheus
kubectl -n kube-system create token prometheus
# Скопируйте токен
# kubectl -n kube-system get secret $(kubectl -n kube-system get sa default -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.token}' | base64 -d
```

На monitoring сервере:

```bash
# Создайте файл с токеном
mkdir -p ~/monitoring/prometheus
echo "YOUR_K3S_TOKEN" > ~/monitoring/prometheus/k3s-token
```

**Запуск мониторинга:**

```bash
cd ~/monitoring
docker-compose up -d

# Проверка
docker-compose ps
docker-compose logs -f
```

**Доступ:**
- Prometheus: `https://grafana.your-domain.com:9090` (будет через Grafana)
- Grafana: `https://grafana.your-domain.com:3000` (admin/admin)

---

## Этап 11: Настройка Jenkins Pipeline

### 11.1 Первоначальная настройка Jenkins

Откройте `https://jenkins.your-domain.com:8080`

1. Введите initial admin password (из команды ранее)
2. Install suggested plugins
3. Create First Admin User
4. Save and Continue

### 11.2 Установка плагинов

**Manage Jenkins → Manage Plugins → Available**

Установите следующие плагины:

- Docker Pipeline
- Kubernetes CLI
- SonarQube Scanner
- Config File Provider
- Maven Integration
- Pipeline Maven Integration
- Prometheus metrics
- Email Extension Plugin   (есть только Email Extension Template)
- Blue Ocean (опционально, для красивого UI)
- CloudBees Disk Usage Simple (для Prometheus)

После установки: **Restart Jenkins**

### 11.3 Настройка Tools

**Manage Jenkins → Tools**

**JDK:**
- Name: `java17`
- ✓ Install automatically
- Version: OpenJDK 17

**Maven:**
- Name: `maven3.6`
- ✓ Install automatically
- Version: 3.9.5

**Docker:**
- Name: `docker`
- ✓ Install automatically
- Download from docker.com

**SonarQube Scanner:**
- Name: `sonar-scanner`
- ✓ Install automatically
- Version: Latest

### 11.4 Настройка Credentials

**Manage Jenkins → Manage Credentials → Global → Add Credentials**

**1. GitHub Token:**
- Kind: Secret text
- Secret: `<your-github-personal-access-token>`
- ID: `github-token`
- Description: GitHub Access Token

**Как создать GitHub Token:**
```
GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic) → Generate new token
Scopes: repo, admin:repo_hook
```

**2. Harbor Registry:**
- Kind: Username with password
- Username: `admin`
- Password: `<your-harbor-password>`
- ID: `harbor-creds`
- Description: Harbor Registry Credentials

**3. SonarQube Token:**
- Kind: Secret text
- Secret: `<sonarqube-token>`
- ID: `sonar-token`
- Description: SonarQube Authentication Token

**Как создать SonarQube Token:**
```
SonarQube → "My Account → Security → Generate Tokens
```

**4. Kubernetes Config:**
- Kind: Secret file
- File: Upload `~/.kube/config`
- ID: `k8s-kubeconfig`
- Description: Kubernetes Config
- Внутри файла поменять адрес 127.0.0.1 на k3s-master.local.lab и только потом загружать в jenkins

**5. Gmail App Password:**
- Kind: Username with password
- Username: `your-email@gmail.com`
- Password: `<gmail-app-password>`
- ID: `gmail-creds`
- Description: Gmail Credentials

**Как создать Gmail App Password:**
```
Google Account → Security → 2-Step Verification → App passwords → Jenkins
```
**6. Nexus:**
- Kind: Username with password
- Username: `jenkins`
- Password: `<your-nexus-password>`
- ID: `nexus-cred`
- Description: Nexus Credentials
- Пользователя jenkins нужно создать на сервере nexus и дать ему права админа.
  
### 11.5 Настройка SonarQube Server

**Manage Jenkins → Configure System → SonarQube servers**

- ✓ Enable injection of SonarQube server configuration
- Name: `SonarQube`
- Server URL: `http://192.168.100.30:9000`
- Server authentication token: Select `sonar-token`

### 11.6 Настройка Maven Settings

**Manage Jenkins → Managed files → Add a new Config → Global Maven settings.xml**

- ID: `maven-settings`
- Name: `Maven Settings`

Содержимое:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0
                              http://maven.apache.org/xsd/settings-1.0.0.xsd">
  <servers>
    <server>
      <id>nexus-releases</id>
      <username>${env.NEXUS_USERNAME}</username>
      <password>${env.NEXUS_PASSWORD}</password>
    </server>
    <server>
      <id>nexus-snapshots</id>
      <username>${env.NEXUS_USERNAME}</username>
      <password>${env.NEXUS_PASSWORD}</password>
    </server>
  </servers>
</settings>

```

Submit

### 11.7 Настройка Email

**Manage Jenkins → Configure System**

**Extended E-mail Notification:**
- SMTP server: `smtp.gmail.com`
- SMTP Port: `465`
- ✓ Use SSL
- Credentials: Select `gmail-creds`
- Default Content Type: HTML (text/html)
- Default Recipients: `your-email@example.com`

**E-mail Notification:**
- SMTP server: `smtp.gmail.com`
- ✓ Use SMTP Authentication
- User Name: `your-email@gmail.com`
- Password: `<gmail-app-password>`
- ✓ Use SSL
- SMTP Port: `465`
- Reply-To Address: `your-email@gmail.com`

**Test:** Send test e-mail

---

## Этап 12: Создание Jenkins Pipeline

### 12.1 Подготовка репозитория

На вашей локальной машине:

```bash
# Клонируйте оригинальный проект
git clone https://github.com/jaiswaladi246/Boardgame.git
cd Boardgame

# Создайте свой приватный репозиторий на GitHub
# Затем переключите origin
git remote set-url origin https://github.com/YOUR_USERNAME/boardgame.git
```

### 9.2 Добавление Kubernetes манифестов

Создайте файл `deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: boardgame
  namespace: production
  labels:
    app: boardgame
spec:
  replicas: 2
  selector:
    matchLabels:
      app: boardgame
  template:
    metadata:
      labels:
        app: boardgame
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/actuator/prometheus"
    spec:
      containers:
        - name: boardgame
          image: harbor.local.lab/library/boardgame:latest   #  Harbor
          imagePullPolicy: Always
          ports:
            - containerPort: 8080
              name: http
              protocol: TCP
          env:
            - name: SPRING_PROFILES_ACTIVE
              value: "prod"
          resources:
            requests:
              memory: "512Mi"
              cpu: "500m"
            limits:
              memory: "1Gi"
              cpu: "1000m"
          livenessProbe:
            httpGet:
              path: /
              port: 8080
            initialDelaySeconds: 60
            periodSeconds: 10
            timeoutSeconds: 5
            failureThreshold: 3
          readinessProbe:
            httpGet:
              path: /
              port: 8080
            initialDelaySeconds: 30
            periodSeconds: 5
            timeoutSeconds: 3
            failureThreshold: 3
      imagePullSecrets:
        - name: harbor-registry-secret
---
apiVersion: v1
kind: Service
metadata:
  name: boardgame-service
  namespace: production
  labels:
    app: boardgame
spec:
  type: LoadBalancer
  selector:
    app: boardgame
  ports:
    - port: 80
      targetPort: 8080
      protocol: TCP
      name: http
  sessionAffinity: ClientIP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: boardgame-ingress
  namespace: production
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
spec:
  ingressClassName: traefik
  rules:
    - host: boardgame.local.lab        # запись в локальном DNS, запись A с IP от metallb
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: boardgame-service
                port:
                  number: 80
  tls:
    - hosts:
        - boardgame.local.lab          #  хост который в DNS
      secretName: boardgame-tls

```
Создайте namespace с именем production:
```bash
sudo kubectl create namespace production
```

### 12.3 Обновление pom.xml

Добавьте в `pom.xml` секцию `distributionManagement`, файл pom.xml  должен лежать в корне проекта на github:

```xml
<distributionManagement>
    <repository>
        <id>nexus-releases</id>
        <name>Maven Releases Repository</name>
        <url>http://nexus.local.lab:8081/repository/maven-releases/</url>
    </repository>
    <snapshotRepository>
        <id>nexus-snapshots</id>
        <name>Maven Snapshots Repository</name>
        <url>http://nexus.local.lab:8081/repository/maven-snapshots/</url>
    </snapshotRepository>
</distributionManagement>
```

### 12.4 Создание Jenkinsfile

Создайте файл `Jenkinsfile`:

```groovy
pipeline {
    agent any
    
    tools {
        jdk 'java17'
        maven 'maven3.6'
    }
    
    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        HARBOR_REGISTRY = 'harbor.your-domain.com'
        HARBOR_PROJECT = 'library'
        IMAGE_NAME = 'boardgame'
        IMAGE_TAG = "${BUILD_NUMBER}"
        FULL_IMAGE_NAME = "${HARBOR_REGISTRY}/${HARBOR_PROJECT}/${IMAGE_NAME}:${IMAGE_TAG}"
        LATEST_IMAGE_NAME = "${HARBOR_REGISTRY}/${HARBOR_PROJECT}/${IMAGE_NAME}:latest"
    }
    
    stages {
        stage('Git Checkout') {
            steps {
                git branch: 'main',
                    credentialsId: 'github-token',
                    url: 'https://github.com/YOUR_USERNAME/boardgame.git'
            }
        }
        
        stage('Compile') {
            steps {
                sh 'mvn clean compile'
            }
        }
        
        stage('Unit Tests') {
            steps {
                sh 'mvn test'
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: '**/target/surefire-reports/*.xml'
                }
            }
        }
        
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar') {
                    sh '''
                        ${SCANNER_HOME}/bin/sonar-scanner \
                        -Dsonar.projectName=BoardGame \
                        -Dsonar.projectKey=BoardGame \
                        -Dsonar.java.binaries=target/classes
                    '''
                }
            }
        }
        
        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: false, credentialsId: 'sonar-token'
                }
            }
        }
        
        stage('Trivy FS Scan') {
            steps {
                sh '''
                    trivy fs \
                    --format table \
                    --output trivy-fs-report.html \
                    --severity HIGH,CRITICAL \
                    --exit-code 0 \
                    .
                '''
            }
        }
        
        stage('Build Application') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }
        
        stage('Publish to Nexus') {
            steps {
                configFileProvider([configFile(fileId: 'maven-settings', variable: 'MAVEN_SETTINGS')]) {
                    sh 'mvn deploy -s $MAVEN_SETTINGS -DskipTests'
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    sh """
                        docker build -t ${FULL_IMAGE_NAME} .
                        docker tag ${FULL_IMAGE_NAME} ${LATEST_IMAGE_NAME}
                    """
                }
            }
        }
        
        stage('Trivy Image Scan') {
            steps {
                sh """
                    trivy image \
                    --format table \
                    --output trivy-image-report.html \
                    --severity HIGH,CRITICAL \
                    --exit-code 0 \
                    ${FULL_IMAGE_NAME}
                """
            }
        }
        
        stage('Push to Harbor') {
            steps {
                script {
                    docker.withRegistry("https://${HARBOR_REGISTRY}", 'harbor-creds') {
                        sh """
                            docker push ${FULL_IMAGE_NAME}
                            docker push ${LATEST_IMAGE_NAME}
                        """
                    }
                }
            }
        }
        
        stage('Update Deployment Manifest') {
            steps {
                script {
                    sh """
                        sed -i 's|image:.*|image: ${FULL_IMAGE_NAME}|g' deployment.yaml
                    """
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    withKubeConfig([credentialsId: 'k8s-kubeconfig']) {
                        sh '''
                            # Создание Harbor registry secret (если не существует)
                            kubectl create secret docker-registry harbor-registry-secret \
                              --docker-server=${HARBOR_REGISTRY} \
                              --docker-username=admin \
                              --docker-password=YOUR_HARBOR_PASSWORD \
                              --namespace=default \
                              --dry-run=client -o yaml | kubectl apply -f -
                            
                            # Применение deployment
                            kubectl apply -f deployment.yaml
                            
                            # Ожидание завершения rollout
                            kubectl rollout status deployment/boardgame -n default --timeout=5m
                        '''
                    }
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                script {
                    withKubeConfig([credentialsId: 'k8s-kubeconfig']) {
                        sh '''
                            echo "=== Pods Status ==="
                            kubectl get pods -n default -l app=boardgame
                            
                            echo "=== Service Status ==="
                            kubectl get svc boardgame-service -n default
                            
                            echo "=== Ingress Status ==="
                            kubectl get ingress boardgame-ingress -n default
                            
                            echo "=== Recent Events ==="
                            kubectl get events -n default --sort-by='.lastTimestamp' | tail -10
                        '''
                    }
                }
            }
        }
    }
    
    post {
        always {
            // Архивация артефактов
            archiveArtifacts artifacts: '**/target/*.jar', allowEmptyArchive: true
            archiveArtifacts artifacts: 'trivy-*-report.html', allowEmptyArchive: true
            
            // Очистка workspace
            cleanWs()
        }
        
        success {
            emailext(
                subject: "✅ Pipeline Success: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
                    <html>
                    <body style="font-family: Arial, sans-serif;">
                        <h2 style="color: #28a745;">🎉 Pipeline Executed Successfully!</h2>
                        <table style="border-collapse: collapse; width: 100%;">
                            <tr>
                                <td style="padding: 8px; border: 1px solid #ddd;"><strong>Job:</strong></td>
                                <td style="padding: 8px; border: 1px solid #ddd;">${env.JOB_NAME}</td>
                            </tr>
                            <tr>
                                <td style="padding: 8px; border: 1px solid #ddd;"><strong>Build Number:</strong></td>
                                <td style="padding: 8px; border: 1px solid #ddd;">${env.BUILD_NUMBER}</td>
                            </tr>
                            <tr>
                                <td style="padding: 8px; border: 1px solid #ddd;"><strong>Docker Image:</strong></td>
                                <td style="padding: 8px; border: 1px solid #ddd;">${FULL_IMAGE_NAME}</td>
                            </tr>
                            <tr>
                                <td style="padding: 8px; border: 1px solid #ddd;"><strong>Application URL:</strong></td>
                                <td style="padding: 8px; border: 1px solid #ddd;">
                                    <a href="https://boardgame.apps.your-domain.com">https://boardgame.apps.your-domain.com</a>
                                </td>
                            </tr>
                            <tr>
                                <td style="padding: 8px; border: 1px solid #ddd;"><strong>Build URL:</strong></td>
                                <td style="padding: 8px; border: 1px solid #ddd;">
                                    <a href="${env.BUILD_URL}">${env.BUILD_URL}</a>
                                </td>
                            </tr>
                        </table>
                        <p style="margin-top: 20px;">Check the attached Trivy security report for details.</p>
                    </body>
                    </html>
                """,
                to: 'your-email@example.com',
                mimeType: 'text/html',
                attachmentsPattern: 'trivy-image-report.html'
            )
        }
        
        failure {
            emailext(
                subject: "❌ Pipeline Failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
                    <html>
                    <body style="font-family: Arial, sans-serif;">
                        <h2 style="color: #dc3545;">❌ Pipeline Execution Failed!</h2>
                        <table style="border-collapse: collapse; width: 100%;">
                            <tr>
                                <td style="padding: 8px; border: 1px solid #ddd;"><strong>Job:</strong></td>
                                <td style="padding: 8px; border: 1px solid #ddd;">${env.JOB_NAME}</td>
                            </tr>
                            <tr>
                                <td style="padding: 8px; border: 1px solid #ddd;"><strong>Build Number:</strong></td>
                                <td style="padding: 8px; border: 1px solid #ddd;">${env.BUILD_NUMBER}</td>
                            </tr>
                            <tr>
                                <td style="padding: 8px; border: 1px solid #ddd;"><strong>Failed Stage:</strong></td>
                                <td style="padding: 8px; border: 1px solid #ddd;">${env.STAGE_NAME}</td>
                            </tr>
                            <tr>
                                <td style="padding: 8px; border: 1px solid #ddd;"><strong>Console Output:</strong></td>
                                <td style="padding: 8px; border: 1px solid #ddd;">
                                    <a href="${env.BUILD_URL}console">${env.BUILD_URL}console</a>
                                </td>
                            </tr>
                        </table>
                        <p style="margin-top: 20px; color: #dc3545;">Please check the console output for detailed error information.</p>
                    </body>
                    </html>
                """,
                to: 'your-email@example.com',
                mimeType: 'text/html'
            )
        }
    }
}
```
Получится следущий pipeline:
```mermaid
graph TD
    A[Git Checkout] --> B[Compile]
    B --> C[Unit Tests]
    C --> D[SonarQube Analysis]
    D --> E[Quality Gate]
    E --> F[Trivy FS Scan]
    F --> G[Build Application]
    G --> H[Build Docker Image]
    H --> I[Trivy Image Scan]
    I --> J[Publish to Nexus]
    J --> K[Push to Harbor]
    K --> L[Deploy to Kubernetes]
    L --> M[Verify Deployment]
    
    %% Группировка по категориям
    subgraph "🔧 Development Phase"
        A
        B
        C
    end
    
    subgraph "✅ Code Quality"
        D
        E
    end
    
    subgraph "🔒 Security Scanning"
        F
        I
    end
    
    subgraph "🏗️ Build Phase"
        G
        H
    end
    
    subgraph "📦 Publish Phase"
        J
        K
    end
    
    subgraph "🚀 Deployment Phase"
        L
        M
    end
    
    %% Стили для блоков
    classDef default fill:#e1f5fe,stroke:#01579b,stroke-width:2px,rx:5,ry:5
    classDef dev fill:#bbdefb,stroke:#1565c0,stroke-width:2px
    classDef quality fill:#e1bee7,stroke:#7b1fa2,stroke-width:2px
    classDef security fill:#ffcdd2,stroke:#d32f2f,stroke-width:2px
    classDef build fill:#c8e6c9,stroke:#388e3c,stroke-width:2px
    classDef publish fill:#ffe0b2,stroke:#f57c00,stroke-width:2px
    classDef deploy fill:#
```
### 12.5 Коммит и пуш изменений

```bash
git add .
git commit -m "Add CI/CD pipeline configuration"
git push origin main
```

---

## Этап 13: Установка мониторинга на Jenkins

### 13.1 Установка Node Exporter на Jenkins

```bash
ssh ubuntu@192.168.100.20

# Скачивание Node Exporter
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz
tar xvfz node_exporter-1.7.0.linux-amd64.tar.gz
sudo cp node_exporter-1.7.0.linux-amd64/node_exporter /usr/local/bin/

# Создание systemd service
sudo tee /etc/systemd/system/node-exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
Type=simple
User=ubuntu
ExecStart=/usr/local/bin/node_exporter
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Запуск
sudo systemctl daemon-reload
sudo systemctl start node-exporter
sudo systemctl enable node-exporter
sudo systemctl status node-exporter
```

Проверка:

```bash
curl http://localhost:9100/metrics
```

### 13.2 Настройка Jenkins Prometheus Plugin

В Jenkins:

**Manage Jenkins → Configure System → Prometheus**

- Path: `/prometheus`
- Collecting metrics period: `120` seconds
- ✓ Count successful builds
- ✓ Count unstable builds  
- ✓ Count failed builds
- ✓ Count not built builds
- ✓ Count aborted builds

**Save**

Проверка:

```bash
curl http://192.168.100.20:8080/prometheus
```

Если выходит что нет доступа, то заходим в учетку админа на jenkins и там генерируем токен.
Далее идем с этим токеном на мониторинг сервер prometheus и в его yaml файл в секции jenkins добавляем строчки basic_auth:
```yaml
scrape_configs:
  - job_name: 'jenkins'
    metrics_path: '/prometheus'
    scheme: http
    static_configs:
      - targets: ['192.168.100.20:8080']
    basic_auth:
      username: 'admin'
      password: '<твой_jenkins_api_token>'
```
Если и это не помгает, то нужно дать права Prometheus.
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: prometheus
rules:
  - apiGroups: [""]
    resources:
      - nodes
      - services
      - endpoints
      - pods
      - ingresses
    verbs: ["get", "list", "watch"]
  - apiGroups:
      - extensions
      - apps
    resources:
      - replicasets
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: prometheus
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: prometheus
subjects:
  - kind: ServiceAccount
    name: prometheus
    namespace: kube-system    
```
kubectl apply -f prometheus-rbac.yaml
Если есть роль для Prometheus удаляем ее 
kubectl delete clusterrolebinding prometheus
и добавляем
kubectl apply -f prometheus-rbac.yaml
Генерим токен -
kubectl -n kube-system create token prometheus



### 13.3 Настройка Grafana дашбордов

Откройте Grafana: `https://grafana.your-domain.com` (admin/admin)

**Добавление Prometheus Data Source:**

1. Configuration (⚙️) → Data Sources → Add data source
2. Select: Prometheus
3. URL: `http://prometheus:9090`
4. Save & Test

**Импорт дашбордов:**

**Дашборд #1: Node Exporter Full**
1. Dashboards → Import
2. Import via grafana.com: `1860`
3. Load
4. Select Prometheus data source
5. Import

**Дашборд #2: Jenkins Performance**
1. Dashboards → Import
2. Import via grafana.com: `9964`
3. Load
4. Select Prometheus data source
5. Import

**Дашборд #3: Blackbox Exporter**
1. Dashboards → Import
2. Import via grafana.com: `7587`
3. Load
4. Select Prometheus data source
5. Import

**Дашборд #4: Kubernetes Cluster Monitoring**
1. Dashboards → Import
2. Import via grafana.com: `315`
3. Load
4. Select Prometheus data source
5. Import

---

## Этап 14: Настройка безопасности K8s

### 14.1 Установка Kubeaudit

На k3s-master:

```bash
ssh ubuntu@192.168.100.10

# Скачивание
wget https://github.com/Shopify/kubeaudit/releases/download/v0.22.0/kubeaudit_0.22.0_linux_amd64.tar.gz
tar -xzf kubeaudit_0.22.0_linux_amd64.tar.gz
sudo mv kubeaudit /usr/local/bin/
sudo chmod +x /usr/local/bin/kubeaudit

# Запуск сканирования
kubeaudit all > kubeaudit-report.txt

# Просмотр отчета
cat kubeaudit-report.txt
```

### 14.2 Создание RBAC для Jenkins

Создайте файл `jenkins-rbac.yaml`:

```yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: jenkins
  namespace: default

---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: jenkins-deployer
  namespace: default
rules:
- apiGroups: ["", "apps", "networking.k8s.io"]
  resources:
    - pods
    - pods/log
    - services
    - deployments
    - replicasets
    - ingresses
    - secrets
    - configmaps
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: [""]
  resources:
    - pods/exec
  verbs: ["create"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: jenkins-deployer-binding
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: jenkins-deployer
subjects:
- kind: ServiceAccount
  name: jenkins
  namespace: default

---
apiVersion: v1
kind: Secret
metadata:
  name: jenkins-token
  namespace: default
  annotations:
    kubernetes.io/service-account.name: jenkins
type: kubernetes.io/service-account-token
```

Применение:

```bash
kubectl apply -f jenkins-rbac.yaml

# Получение токена
kubectl get secret jenkins-token -n default -o jsonpath='{.data.token}' | base64 -d

# Сохраните токен!
```

### 14.3 Создание kubeconfig для Jenkins

Создайте файл `create-jenkins-kubeconfig.sh`:

```bash
#!/bin/bash

SERVICE_ACCOUNT=jenkins
NAMESPACE=default
SERVER_URL=https://192.168.100.10:6443

# Получение токена
TOKEN=$(kubectl get secret jenkins-token -n ${NAMESPACE} -o jsonpath='{.data.token}' | base64 -d)

# Получение CA certificate
kubectl get secret jenkins-token -n ${NAMESPACE} -o jsonpath='{.data.ca\.crt}' | base64 -d > ca.crt

# Создание kubeconfig
cat > jenkins-kubeconfig.yaml <<EOF
apiVersion: v1
kind: Config
clusters:
- name: k3s-cluster
  cluster:
    certificate-authority-data: $(kubectl get secret jenkins-token -n ${NAMESPACE} -o jsonpath='{.data.ca\.crt}')
    server: ${SERVER_URL}
contexts:
- name: jenkins-context
  context:
    cluster: k3s-cluster
    namespace: ${NAMESPACE}
    user: jenkins
current-context: jenkins-context
users:
- name: jenkins
  user:
    token: ${TOKEN}
EOF

echo "Kubeconfig created: jenkins-kubeconfig.yaml"
```

Выполнение:

```bash
chmod +x create-jenkins-kubeconfig.sh
./create-jenkins-kubeconfig.sh

# Обновите credentials в Jenkins этим файлом
```

### 14.4 Network Policies (опционально)

Создайте файл `network-policies.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: boardgame-network-policy
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: boardgame
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: traefik
    - podSelector: {}
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 53  # DNS
    - protocol: UDP
      port: 53  # DNS
  - to:
    - podSelector: {}
```

---

## Этап 15: Запуск Pipeline

### 15.1 Создание Pipeline Job в Jenkins

1. Jenkins → New Item
2. Item name: `boardgame-pipeline`
3. Type: **Pipeline**
4. OK

**General:**
- ✓ GitHub project
  - Project url: `https://github.com/YOUR_USERNAME/boardgame/`
- ✓ Discard old builds
  - Max # of builds to keep: `10`

**Build Triggers:**
- ✓ GitHub hook trigger for GITScm polling

**Pipeline:**
- Definition: **Pipeline script from SCM**
  - SCM: Git
  - Repository URL: `https://github.com/YOUR_USERNAME/boardgame.git`
  - Credentials: `github-token`
  - Branch Specifier: `*/main`
  - Script Path: `Jenkinsfile`

**Save**

### 15.2 Настройка GitHub Webhook (опционально)

В вашем GitHub репозитории:

1. Settings → Webhooks → Add webhook
2. Payload URL: `https://jenkins.your-domain.com/github-webhook/`
3. Content type: `application/json`
4. Which events: **Just the push event**
5. ✓ Active
6. Add webhook

### 15.3 Первый запуск Pipeline

В Jenkins:

1. Откройте `boardgame-pipeline`
2. **Build Now**
3. Смотрите прогресс в Console Output

**⏱️ Ожидаемое время: 10-15 минут**

### 15.4 Мониторинг выполнения

**Console Output:**
```
Started by user admin
Running in Durability level: MAX_SURVIVABILITY
[Pipeline] Start of Pipeline
[Pipeline] node
Running on Jenkins in /var/lib/jenkins/workspace/boardgame-pipeline
[Pipeline] {
[Pipeline] stage
[Pipeline] { (Git Checkout)
...
```

**Blue Ocean View (опционально):**
- Jenkins → Open Blue Ocean
- Красивый UI для просмотра pipeline

<img width="1919" height="671" alt="image" src="https://github.com/user-attachments/assets/f27b62c3-0285-487f-ace6-9b863746a73a" />

---

## Этап 16: Проверка результатов

### 16.1 Проверка Kubernetes Deployment

```bash
# Pods
kubectl get pods -n default -l app=boardgame

# Ожидаемый вывод:
# NAME                        READY   STATUS    RESTARTS   AGE
# boardgame-xxxxxxxxx-xxxxx   1/1     Running   0          5m
# boardgame-xxxxxxxxx-xxxxx   1/1     Running   0          5m

# Services
kubectl get svc boardgame-service -n default

# Ingress
kubectl get ingress boardgame-ingress -n default

# Logs
kubectl logs -f deployment/boardgame -n default

# Events
kubectl get events -n default --sort-by='.lastTimestamp' | tail -20
```

### 16.2 Доступ к приложению

**Через Ingress (рекомендуется):**
```
https://boardgame.apps.your-domain.com
```
В моем случае это адрес http://boardgame.local.lab c адресом LoadBalancer 192.168.100.103
<img width="1919" height="950" alt="image" src="https://github.com/user-attachments/assets/684edbb8-aa55-4633-9b9d-39c19356a345" />


**Через LoadBalancer IP (внутренняя сеть):**
```bash
# Получение LoadBalancer IP
LB_IP=$(kubectl get svc boardgame-service -n default -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Application URL: http://${LB_IP}"

# Пример: http://192.168.100.100
```

**Через Port Forward (для тестирования):**
```bash
kubectl port-forward svc/boardgame-service 8080:80 -n default

# Доступ: http://localhost:8080
```

### 16.3 Тестирование приложения

**Тестовые пользователи:**

| Username | Password | Role |
|----------|----------|------|
| bugs | bunny | USER |
| daffy | duck | MANAGER |

**Функции:**
- Просмотр игр (все пользователи)
- Добавление игр (все пользователи)
- Добавление отзывов (все пользователи)
- Редактирование/удаление отзывов (только MANAGER)

**Тест-кейсы:**

1. **Вход как USER:**
   ```
   Username: bugs
   Password: bunny
   ```
   - ✓ Можно просматривать игры
   - ✓ Можно добавить игру
   - ✓ Можно добавить отзыв
   - ✗ Нельзя редактировать/удалять отзывы

2. **Вход как MANAGER:**
   ```
   Username: daffy
   Password: duck
   ```
   - ✓ Можно просматривать игры
   - ✓ Можно добавить игру
   - ✓ Можно добавить отзыв
   - ✓ Можно редактировать/удалять отзывы

### 16.4 Проверка артефактов

**Jenkins:**
- Build Artifacts: `target/*.jar`
- Trivy Reports: `trivy-fs-report.html`, `trivy-image-report.html`

**Nexus:** `https://nexus.your-domain.com`
- Browse → maven-releases
- com/devops/boardgame/{VERSION}/boardgame-{VERSION}.jar

**Harbor:** `https://harbor.your-domain.com`
- Projects → library → Repositories → boardgame
- Tags: `latest`, `{BUILD_NUMBER}`

**SonarQube:** `https://sonar.your-domain.com`
- Projects → BoardGame
- Code Quality metrics, bugs, vulnerabilities

### 13.5 Проверка мониторинга

**Grafana:** `https://grafana.your-domain.com`

**Дашборды для проверки:**

1. **Node Exporter Full:**
   - CPU Usage
   - Memory Usage
   - Disk I/O
   - Network Traffic

2. **Jenkins Performance:**
   - Build Duration
   - Build Success Rate
   - Queue Length
   - Executor Usage

3. **Blackbox Exporter:**
   - HTTP Response Time
   - HTTP Status Codes
   - SSL Certificate Expiry

4. **Kubernetes Cluster:**
   - Pod Status
   - Resource Usage
   - Network I/O

### 16.6 Проверка Email уведомлений

Проверьте ваш email:

- ✅ Success notification (с приложенным Trivy report)
- Содержит: Job name, Build number, Docker image, Application URL

Для теста failure notification:
```bash
# Намеренно создайте ошибку в Jenkinsfile
# Например, некорректный синтаксис
# И запустите build
```

---

## Этап 17: Оптимизация и Best Practices

### 17.1 Horizontal Pod Autoscaler (HPA)

Создайте файл `hpa.yaml`:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: boardgame-hpa
  namespace: default
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: boardgame
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 15
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
      - type: Pods
        value: 4
        periodSeconds: 15
      selectPolicy: Max
```

Применение:

```bash
kubectl apply -f hpa.yaml

# Проверка
kubectl get hpa -n default
```

### 17.2 Persistent Volumes для данных

Создайте файл `pv-pvc.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: boardgame-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  hostPath:
    path: /mnt/data/boardgame
    type: DirectoryOrCreate

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: boardgame-pvc
  namespace: default
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
  storageClassName: manual
```

### 17.3 ConfigMap для конфигурации

Создайте файл `configmap.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: boardgame-config
  namespace: default
data:
  application.properties: |
    server.port=8080
    spring.application.name=boardgame
    spring.profiles.active=prod
    logging.level.root=INFO
    logging.level.com.devops.boardgame=DEBUG
```

### 17.4 Resource Quotas для namespace

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: default-quota
  namespace: default
spec:
  hard:
    requests.cpu: "10"
    requests.memory: 20Gi
    limits.cpu: "20"
    limits.memory: 40Gi
    persistentvolumeclaims: "10"
    services.loadbalancers: "5"
```

### 17.5 Pod Disruption Budget

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: boardgame-pdb
  namespace: default
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: boardgame
```

---

## Этап 18: Troubleshooting

### 18.1 Распространенные проблемы и решения

#### Проблема: Jenkins не может подключиться к K8s

**Симптомы:**
```
ERROR: Unable to connect to the server: dial tcp 192.168.100.10:6443: i/o timeout
```

**Решение:**
```bash
# На Jenkins сервере
kubectl cluster-info

# Проверка connectivity
telnet 192.168.100.10 6443

# Проверка kubeconfig
cat ~/.kube/config

# Обновление kubeconfig
scp ubuntu@192.168.100.10:/etc/rancher/k3s/k3s.yaml ~/.kube/config
sed -i 's/127.0.0.1/192.168.100.10/' ~/.kube/config
```

#### Проблема: Harbor "x509: certificate signed by unknown authority"

**Симптомы:**
```
Error response from daemon: Get "https://harbor.your-domain.com/v2/": x509: certificate signed by unknown authority
```

**Решение:**
```bash
# На Jenkins и всех K8s nodes
sudo mkdir -p /etc/docker/certs.d/harbor.your-domain.com

# Или добавьте в insecure registries
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "insecure-registries": ["harbor.your-domain.com", "192.168.100.32"]
}
EOF

sudo systemctl restart docker
```

#### Проблема: Pod не может скачать образ из Harbor

**Симптомы:**
```
Failed to pull image "harbor.your-domain.com/library/boardgame:latest": rpc error: code = Unknown desc = failed to pull and unpack image
```

**Решение:**
```bash
# Создайте/обновите docker-registry secret
kubectl delete secret harbor-registry-secret -n default --ignore-not-found

kubectl create secret docker-registry harbor-registry-secret \
  --docker-server=harbor.your-domain.com \
  --docker-username=admin \
  --docker-password=YOUR_HARBOR_PASSWORD \
  --namespace=default

# Проверьте
kubectl get secret harbor-registry-secret -n default -o yaml
```

#### Проблема: MetalLB не выдает IP адреса

**Симптомы:**
```
NAME                  TYPE           EXTERNAL-IP   PORT(S)
boardgame-service     LoadBalancer   <pending>     80:30123/TCP
```

**Решение:**
```bash
# Проверка MetalLB pods
kubectl get pods -n metallb-system

# Проверка logs
kubectl logs -n metallb-system -l app=metallb

# Проверка конфигурации
kubectl get ipaddresspools -n metallb-system -o yaml
kubectl get l2advertisements -n metallb-system -o yaml

# Пересоздание конфигурации
kubectl delete ipaddresspool default-pool -n metallb-system
kubectl delete l2advertisement default -n metallb-system
kubectl apply -f metallb-config.yaml

# Рестарт MetalLB
kubectl rollout restart deployment controller -n metallb-system
```

#### Проблема: Traefik Ingress не работает

**Симптомы:**
```
curl: (7) Failed to connect to boardgame.apps.your-domain.com port 443: Connection refused
```

**Решение:**
```bash
# Проверка Traefik
kubectl get svc -n traefik
kubectl get pods -n traefik
kubectl logs -n traefik -l app.kubernetes.io/name=traefik

# Проверка Ingress
kubectl describe ingress boardgame-ingress -n default

# Проверка DNS
nslookup boardgame.apps.your-domain.com

# Тест напрямую через LoadBalancer IP
LB_IP=$(kubectl get svc traefik -n traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl -H "Host: boardgame.apps.your-domain.com" http://${LB_IP}
```

#### Проблема: SonarQube Quality Gate timeout

**Симптомы:**
```
WARN: QUALITY GATE STATUS: NONE - Failed to get Quality Gate status
```

**Решение:**
```bash
# В SonarQube создайте webhook
# Administration → Configuration → Webhooks → Create

# Name: Jenkins
# URL: http://192.168.100.20:8080/sonarqube-webhook/

# Проверка webhook
# В SonarQube после анализа: Administration → Webhooks → Deliveries
```

#### Проблема: Высокое потребление ресурсов

**Симптомы:**
- Медленная работа VM
- OOM (Out of Memory) errors

**Решение:**
```bash
# Проверка ресурсов на VM
htop
free -h
df -h

# В Kubernetes
kubectl top nodes
kubectl top pods -A

# Оптимизация:
# 1. Уменьшите replicas
kubectl scale deployment boardgame --replicas=1 -n default

# 2. Установите resource limits
kubectl set resources deployment boardgame \
  --limits=cpu=500m,memory=512Mi \
  --requests=cpu=250m,memory=256Mi \
  -n default

# 3. Очистка неиспользуемых образов
docker system prune -a -f
```

### 15.2 Полезные команды для диагностики

**Kubernetes:**

```bash
# Общая информация о кластере
kubectl cluster-info
kubectl get nodes -o wide
kubectl get all -A

# Диагностика подов
kubectl get pods -n default -o wide
kubectl describe pod <pod-name> -n default
kubectl logs <pod-name> -n default
kubectl logs <pod-name> -n default --previous  # Логи предыдущего crashed контейнера

# Интерактивный доступ к поду
kubectl exec -it <pod-name> -n default -- /bin/bash

# События
kubectl get events -n default --sort-by='.lastTimestamp'
kubectl get events -A --sort-by='.lastTimestamp' | tail -50

# Ресурсы
kubectl top nodes
kubectl top pods -A

# Сетевая диагностика
kubectl get svc -A
kubectl get ingress -A
kubectl get endpoints -n default

# Конфигурация
kubectl get configmap -n default
kubectl get secret -n default

# Статус rollout
kubectl rollout status deployment/boardgame -n default
kubectl rollout history deployment/boardgame -n default

# Откат deployment
kubectl rollout undo deployment/boardgame -n default

# Масштабирование
kubectl scale deployment boardgame --replicas=3 -n default

# Удаление застрявших подов
kubectl delete pod <pod-name> -n default --force --grace-period=0
```

**Docker:**

```bash
# Список контейнеров
docker ps -a

# Логи контейнера
docker logs <container-name> -f

# Статистика
docker stats

# Очистка
docker system df
docker system prune -a -f

# Образы
docker images
docker rmi <image-id>

# Сети
docker network ls
docker network inspect bridge
```

**Системная диагностика:**

```bash
# CPU и Memory
htop
free -h
vmstat 1

# Disk
df -h
du -sh /*
iostat -x 1

# Network
netstat -tulpn
ss -tulpn
iftop

# Процессы
ps aux | grep java
ps aux | grep docker

# Логи
journalctl -u k3s -f
journalctl -u jenkins -f
journalctl -u docker -f
```

**Prometheus Queries (для отладки):**

```promql
# CPU Usage
100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory Usage
(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100

# Disk Usage
(node_filesystem_size_bytes{mountpoint="/"} - node_filesystem_free_bytes{mountpoint="/"}) / node_filesystem_size_bytes{mountpoint="/"} * 100

# HTTP Response Time
probe_duration_seconds{job="blackbox-http"}

# Pod Restarts
rate(kube_pod_container_status_restarts_total[15m])
```

---

## Этап 16: Финальная проверка

### 16.1 Чеклист готовности проекта

**Инфраструктура:**
- [ ] Proxmox сеть vmbr1 (192.168.100.0/24) создана
- [ ] Все 8 VM созданы и работают
- [ ] SSH доступ ко всем VM настроен
- [ ] Интернет работает на всех VM

**Kubernetes:**
- [ ] K3s master node работает
- [ ] 2 worker nodes подключены и Ready
- [ ] kubectl работает с вашей машины
- [ ] MetalLB установлен и выдает IP
- [ ] Traefik Ingress работает
- [ ] kubeaudit сканирование выполнено

**CI/CD Инструменты:**
- [ ] Jenkins доступен через Cloudflare Tunnel
- [ ] SonarQube работает и доступен
- [ ] Nexus работает и репозитории созданы
- [ ] Harbor работает и проект создан
- [ ] Jenkins plugins установлены
- [ ] Jenkins credentials настроены
- [ ] Jenkins tools сконфигурированы

**Мониторинг:**
- [ ] Prometheus собирает метрики
- [ ] Grafana доступна
- [ ] Все 4 дашборда импортированы
- [ ] Blackbox exporter мониторит приложения
- [ ] Node exporter работает на Jenkins
- [ ] Jenkins Prometheus plugin настроен

**Pipeline:**
- [ ] GitHub репозиторий создан (приватный)
- [ ] Jenkinsfile и deployment.yaml добавлены
- [ ] Pipeline job создан в Jenkins
- [ ] GitHub webhook настроен (опционально)
- [ ] Pipeline успешно выполнился
- [ ] Email уведомления работают

**Приложение:**
- [ ] Приложение развернуто в K8s
- [ ] Pods в статусе Running
- [ ] Service создан с LoadBalancer IP
- [ ] Ingress настроен
- [ ] Приложение доступно через URL
- [ ] Функционал приложения работает

**Безопасность:**
- [ ] RBAC настроен для Jenkins
- [ ] Network policies применены (опционально)
- [ ] Harbor registry secret создан
- [ ] Trivy сканирование проходит
- [ ] SonarQube Quality Gate настроен

**Внешний доступ:**
- [ ] Cloudflare Tunnel работает
- [ ] DNS записи созданы
- [ ] HTTPS работает для всех сервисов
- [ ] Wildcard для *.apps.your-domain.com настроен

### 16.2 Тестовый сценарий End-to-End

**1. Изменение кода:**

```bash
# На вашей машине
cd boardgame
echo "<!-- Test change -->" >> src/main/webapp/index.jsp
git add .
git commit -m "Test CI/CD pipeline"
git push
```

**2. Автоматический запуск (если webhook настроен):**
- Jenkins автоматически запустит pipeline
- Проверьте в Jenkins UI

**3. Мониторинг выполнения:**
```bash
# Смотрите в реальном времени
# Jenkins → boardgame-pipeline → Build #X → Console Output

# Или через Blue Ocean
# Jenkins → Open Blue Ocean → boardgame-pipeline
```

**4. Проверка deployment:**
```bash
kubectl get pods -n default -l app=boardgame
kubectl rollout status deployment/boardgame -n default
```

**5. Проверка приложения:**
```bash
# Откройте в браузере
https://boardgame.apps.your-domain.com

# Проверьте изменения
```

**6. Проверка артефактов:**
- Nexus: новый JAR файл
- Harbor: новый Docker image с тегом
- SonarQube: обновленный анализ

**7. Проверка мониторинга:**
- Grafana: метрики обновились
- Prometheus: новые данные

**8. Проверка уведомлений:**
- Email: получено Success notification
- Прикреплен Trivy report

### 16.3 Финальная архитектура

```
┌─────────────────────────────────────────────────────────────┐
│                         Internet                             │
│                            ↓                                 │
│                  Cloudflare Tunnel                          │
│          (TLS Termination, DDoS Protection)                 │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              Proxmox Host (10.0.10.200)                     │
│                                                              │
│  ┌────────────────────────────────────────────────────┐   │
│  │         vmbr1 Network (192.168.100.0/24)           │   │
│  │                                                      │   │
│  │  ┌────────────────────────────────────────────┐   │   │
│  │  │         CI/CD Infrastructure                │   │   │
│  │  │                                              │   │   │
│  │  │  ┌──────────┐  ┌──────────┐  ┌──────────┐ │   │   │
│  │  │  │ Jenkins  │  │SonarQube │  │  Nexus   │ │   │   │
│  │  │  │   :20    │  │   :30    │  │   :31    │ │   │   │
│  │  │  └──────────┘  └──────────┘  └──────────┘ │   │   │
│  │  │                                              │   │   │
│  │  │  ┌──────────┐  ┌──────────────────────┐   │   │   │
│  │  │  │  Harbor  │  │     Monitoring       │   │   │   │
│  │  │  │   :32    │  │ Prometheus + Grafana │   │   │   │
│  │  │  └──────────┘  │        :40           │   │   │   │
│  │  │                 └──────────────────────┘   │   │   │
│  │  └────────────────────────────────────────────┘   │   │
│  │                                                      │   │
│  │  ┌────────────────────────────────────────────┐   │   │
│  │  │       K3s Kubernetes Cluster                │   │   │
│  │  │                                              │   │   │
│  │  │  ┌────────────────────────────────────┐   │   │   │
│  │  │  │  Master Node (192.168.100.10)      │   │   │   │
│  │  │  │  - K3s Control Plane               │   │   │   │
│  │  │  │  - API Server                      │   │   │   │
│  │  │  │  - etcd (SQLite)                   │   │   │   │
│  │  │  └────────────────────────────────────┘   │   │   │
│  │  │                                              │   │   │
│  │  │  ┌────────────────┐  ┌────────────────┐   │   │   │
│  │  │  │  Worker Node 1 │  │  Worker Node 2 │   │   │   │
│  │  │  │  (.11)         │  │  (.12)         │   │   │   │
│  │  │  └────────────────┘  └────────────────┘   │   │   │
│  │  │                                              │   │   │
│  │  │  ┌────────────────────────────────────┐   │   │   │
│  │  │  │         MetalLB                     │   │   │   │
│  │  │  │  IP Pool: .100-.150                │   │   │   │
│  │  │  └────────────────────────────────────┘   │   │   │
│  │  │                                              │   │   │
│  │  │  ┌────────────────────────────────────┐   │   │   │
│  │  │  │    Traefik Ingress Controller      │   │   │   │
│  │  │  │    LoadBalancer IP: .100           │   │   │   │
│  │  │  └────────────────────────────────────┘   │   │   │
│  │  │                                              │   │   │
│  │  │  ┌────────────────────────────────────┐   │   │   │
│  │  │  │      Boardgame Application         │   │   │   │
│  │  │  │      Replicas: 2                   │   │   │   │
│  │  │  │      HPA: 2-10 pods                │   │   │   │
│  │  │  └────────────────────────────────────┘   │   │   │
│  │  └────────────────────────────────────────────┘   │   │
│  └────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### 16.4 Метрики проекта

**Инфраструктура:**
- VM: 8
- vCPU: 24
- RAM: 46GB
- Storage: 360GB

**Kubernetes:**
- Nodes: 3 (1 master + 2 workers)
- Namespaces: 4 (default, kube-system, traefik, metallb-system)
- Deployments: 1
- Services: 2
- Ingresses: 1

**CI/CD:**
- Stages: 11
- Build time: ~10-15 минут
- Artifacts: JAR, Docker Image, Reports
- Notifications: Email (Success/Failure)

**Мониторинг:**
- Metrics: 500+ time series
- Dashboards: 4
- Alerts: 5 rules

---

## 📊 Использование

### Ежедневные операции

**Запуск нового build:**
```bash
# Через Jenkins UI
Jenkins → boardgame-pipeline → Build Now

# Через API
curl -X POST https://jenkins.your-domain.com/job/boardgame-pipeline/build \
  --user admin:YOUR_API_TOKEN
```

**Проверка статуса приложения:**
```bash
kubectl get all -n default -l app=boardgame
```

**Просмотр логов:**
```bash
kubectl logs -f deployment/boardgame -n default
```

**Масштабирование:**
```bash
kubectl scale deployment boardgame --replicas=5 -n default
```

**Откат к предыдущей версии:**
```bash
kubectl rollout undo deployment/boardgame -n default
```

### Мониторинг производительности

**Grafana Dashboards:**
1. **Node Exporter** - Системные метрики серверов
2. **Jenkins Performance** - Метрики CI/CD
3. **Blackbox Exporter** - Доступность приложений
4. **Kubernetes** - Метрики кластера

**Важные метрики:**
- Response Time: < 500ms
- Success Rate: > 99%
- CPU Usage: < 80%
- Memory Usage: < 85%
- Disk Usage: < 80%

### Обслуживание

**Обновление компонентов:**

```bash
# K3s
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.29.0+k3s1 sh -

# Jenkins plugins
Jenkins → Manage Jenkins → Manage Plugins → Updates → Update all

# Docker images
docker pull sonarqube:lts-community
docker pull sonatype/nexus3:latest
```

**Очистка старых артефактов:**

```bash
# Docker на Jenkins
ssh ubuntu@192.168.100.20
docker system prune -a -f

# Nexus - через UI
# Nexus → Repository → Cleanup policies

# Harbor - через UI
# Harbor → Projects → library → Repositories → Tag Retention
```

---

## 💾 Backup и Recovery

### Backup скрипт

Создайте файл `/root/backup-devops.sh` на Proxmox хосте:

```bash
#!/bin/bash

BACKUP_ROOT="/backup/devops"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="${BACKUP_ROOT}/${DATE}"

mkdir -p ${BACKUP_DIR}

echo "Starting backup at ${DATE}"

# Backup K3s etcd snapshots
echo "Backing up K3s etcd..."
ssh admin@192.168.100.10 "sudo k3s etcd-snapshot save --name backup-${DATE}"
scp admin@192.168.100.10:/var/lib/rancher/k3s/server/db/snapshots/* ${BACKUP_DIR}/k3s-snapshots/

# Backup Kubernetes manifests
echo "Backing up Kubernetes resources..."
ssh ubuntu@192.168.100.10 "kubectl get all,ingress,configmap,secret,pv,pvc --all-namespaces -o yaml" > ${BACKUP_DIR}/k8s-resources.yaml

# Backup Jenkins
echo "Backing up Jenkins..."
rsync -avz --exclude='workspace' --exclude='caches' \
  ubuntu@192.168.100.20:/var/lib/jenkins/ ${BACKUP_DIR}/jenkins/

# Backup SonarQube database
echo "Backing up SonarQube..."
ssh ubuntu@192.168.100.30 "docker exec sonarqube sh -c 'pg_dump -U sonar sonar' | gzip" > ${BACKUP_DIR}/sonarqube-db.sql.gz

# Backup Nexus data
echo "Backing up Nexus..."
ssh ubuntu@192.168.100.31 "docker exec nexus tar czf - /nexus-data" > ${BACKUP_DIR}/nexus-data.tar.gz

# Backup Harbor
echo "Backing up Harbor..."
ssh ubuntu@192.168.100.32 "cd /root/harbor && docker-compose exec -T database pg_dumpall -U postgres" | gzip > ${BACKUP_DIR}/harbor-db.sql.gz

# Backup Prometheus data
echo "Backing up Prometheus..."
rsync -avz ubuntu@192.168.100.40:~/monitoring/prometheus_data/ ${BACKUP_DIR}/prometheus/

# Backup Grafana
echo "Backing up Grafana..."
rsync -avz ubuntu@192.168.100.40:~/monitoring/grafana_data/ ${BACKUP_DIR}/grafana/

# Cleanup old backups (keep last 7 days)
find ${BACKUP_ROOT} -type d -mtime +7 -exec rm -rf {} \;

echo "Backup completed: ${BACKUP_DIR}"
echo "Backup size: $(du -sh ${BACKUP_DIR} | cut -f1)"
```

Сделайте скрипт исполняемым:

```bash
chmod +x /root/backup-devops.sh
```

Настройте cron:

```bash
crontab -e

# Добавьте: ежедневно в 2:00 AM
0 2 * * * /root/backup-devops.sh >> /var/log/devops-backup.log 2>&1
```

### Recovery процедура

**Восстановление K3s:**

```bash
# На master node
sudo k3s server \
  --cluster-init \
  --cluster-reset \
  --cluster-reset-restore-path=/path/to/snapshot
```

**Восстановление Jenkins:**

```bash
# Остановите Jenkins
sudo systemctl stop jenkins

# Восстановите данные
sudo rsync -avz /backup/devops/DATE/jenkins/ /var/lib/jenkins/

# Установите права
sudo chown -R jenkins:jenkins /var/lib/jenkins

# Запустите Jenkins
sudo systemctl start jenkins
```

**Восстановление других компонентов аналогично.**

---

## ❓ FAQ

### Q: Нужен ли мне статический IP адрес?

**A:** Нет. Cloudflare Tunnel работает без статического IP. Он создает исходящее соединение от вашего Proxmox хоста к Cloudflare.

### Q: Можно ли использовать другой домен вместо Cloudflare?

**A:** Да, но тогда вам понадобится:
- Статический IP или DDNS
- Проброс портов на роутере
- SSL сертификаты (Let's Encrypt)
- Альтернативы: ngrok, Tailscale, WireGuard

### Q: Сколько стоит запустить этот проект?

**A:** Бесплатно! Все компоненты open-source. Нужны только:
- Сервер с Proxmox (ваш существующий)
- Домен (~$10/год, опционально)
- Cloudflare (бесплатный план)

### Q: Можно ли использовать меньше ресурсов?

**A:** Да, минимальная конфигурация:
- 3 VM (1 для K3s, 1 для Jenkins+tools, 1 для monitoring)
- 12 vCPU, 24GB RAM, 150GB Storage
- Уменьшите replicas до 1
- Используйте single-node K3s

### Q: Работает ли это с Windows Hyper-V / VMware?

**A:** Да, концепция та же. Измените только:
- Terraform provider (для Hyper-V/VMware)
- Сетевые настройки
- Остальное идентично

### Q: Как добавить еще одно приложение?

**A:** 
1. Создайте новый Git repo
2. Создайте новый Jenkins job
3. Используйте тот же Jenkinsfile как шаблон
4. Deploy в тот же K8s кластер
5. Создайте новый Ingress с другим hostname

### Q: Можно ли использовать с GitLab вместо GitHub?

**A:** Да! Измените в Jenkinsfile:
- Git URL на GitLab
- Credentials для GitLab
- Webhook URL
- Остальное аналогично

### Q: Что делать если у меня нет домена?

**A:** Используйте:
- Free domains: freenom.com, afraid.org
- Cloudflare Tunnel с их поддоменом
- Локальный DNS (bind9) для внутренней сети
- IP адреса напрямую для тестирования

### Q: Как мониторить затраты ресурсов?

**A:** В Grafana настроены дашборды для:
- CPU/Memory каждого сервера
- Disk usage
- Network traffic
- K8s pod resources

### Q: Безопасно ли это для production?

**A:** Проект создан для обучения. Для production добавьте:
- Настоящие SSL сертификаты
- Более строгие Network Policies
- Secrets management (Vault)
- Regular security updates
- Monitoring alerts
- Incident response plan

**Q: Почему изолированная сеть лучше?**  
**A:** Изолированная сеть обеспечивает:
- Полный контроль над трафиком
- Защиту от внешних атак
- Соответствие корпоративным стандартам безопасности
- Простоту аудита и мониторинга
- Возможность легкой блокировки исходящих подключений

**Q: Что делать если NAT не работает?**  
**A:** Проверьте на Ngrok Gateway:
```bash
# IP forwarding
cat /proc/sys/net/ipv4/ip_forward  # Должно быть 1

# Iptables правила
sudo iptables -t nat -L -n -v

# Routing
ip route show

# Тест с внутренней VM
ssh -J jumphost ubuntu@192.168.100.20
ping 8.8.8.8
```

**Q: Как добавить новую VM в DNS?**  
**A:** На DNS сервере:
```bash
sudo vim /etc/bind/db.local.lab
# Добавьте: newvm  IN  A  192.168.100.X

sudo vim /etc/bind/db.192.168.100
# Добавьте: X  IN  PTR  newvm.local.lab.

# Увеличьте Serial в обоих файлах
# Перезапустите
sudo systemctl restart named
sudo rndc reload
```

**Q: Можно ли обойтись без Jumphost?**  
**A:** Технически да, но не рекомендуется для production:
- Jumphost - стандарт безопасности
- Централизованная точка аудита
- Простота управления доступами
- Дополнительный уровень защиты

---

## 🤝 Contributing

Этот проект создан для обучения. Предложения и улучшения приветствуются!

**Как внести вклад:**

1. Fork репозиторий
2. Создайте feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit изменения (`git commit -m 'Add some AmazingFeature'`)
4. Push в branch (`git push origin feature/AmazingFeature`)
5. Откройте Pull Request

**Идеи для улучшения:**
- [ ] Добавить ArgoCD для GitOps
- [ ] Интеграция с Slack для уведомлений
- [ ] Добавить EFK (Elasticsearch, Fluentd, Kibana) stack
- [ ] Настроить Vault для secrets
- [ ] Добавить Istio service mesh
- [ ] Создать Ansible playbooks для автоматизации
- [ ] Добавить Terraform modules
- [ ] Интеграция с Jira

---

## 📝 Лицензия

Этот проект распространяется под лицензией MIT. См. файл `LICENSE` для подробностей.

---

## 📧 Контакты

**Автор:** Sysops8
**Email:** almastvx@gmail.com
**GitHub:** [@yourusername](https://github.com/sysops8)  


---

## 🙏 Благодарности

- [Aditya Jaiswal](https://github.com/jaiswaladi246) - оригинальный проект
- Kubernetes Community
- CNCF Projects
- HashiCorp Terraform
- Cloudflare
- Все open-source contributors

---

## 📚 Дополнительные ресурсы

**Документация:**
- [Kubernetes](https://kubernetes.io/docs/)
- [K3s](https://docs.k3s.io/)
- [Jenkins](https://www.jenkins.io/doc/)
- [Terraform](https://www.terraform.io/docs/)
- [Proxmox](https://pve.proxmox.com/wiki/)

**Обучающие материалы:**
- [Kubernetes Tutorial](https://kubernetes.io/docs/tutorials/)
- [Jenkins Pipeline Tutorial](https://www.jenkins.io/doc/book/pipeline/)
- [Docker Documentation](https://docs.docker.com/)
- [Prometheus Documentation](https://prometheus.io/docs/)

**Сообщества:**
- [Kubernetes Slack](https://slack.k8s.io/)
- [DevOps Subreddit](https://reddit.com/r/devops)
- [CNCF Slack](https://cloud-native.slack.com/)

---

## 📊 Статистика проекта

- **Строк кода:** ~1500
- **Конфигурационных файлов:** 20+
- **VM:** 8
- **Контейнеров:** 15+
- **Сервисов:** 10+
- **Время установки:** 2-3 часа
- **Поддерживаемые ОС:** Ubuntu 22.04
- **Kubernetes версия:** 1.28+

---

**Важные замечания:**
- **DNS**: Используйте `jenkins.local.lab` вместо IP адресов
- **Gateway**: Все VM используют `192.168.100.60` как шлюз
- **Доступ**: Только через Jumphost (`ssh -J`)
- **Внешний доступ**: Только через Ngrok/Cloudflare туннель


## 📊 Проверка инфраструктуры

### Чеклист готовности базовой инфраструктуры

- [ ] DNS Server запущен и отвечает
- [ ] Jumphost настроен и доступен
- [ ] Ngrok Gateway настроен и работает NAT
- [ ] Все VM созданы через Terraform
- [ ] DNS резолвит все внутренние имена
- [ ] Интернет работает через NAT
- [ ] SSH через Jumphost работает
- [ ] Ngrok туннели активны

### Тест DNS

```bash
# На любой внутренней VM
dig jenkins.local.lab
dig k3s-master.local.lab
dig apps.local.lab

# Reverse DNS
dig -x 192.168.100.20
```

### Тест сети

```bash
# На любой внутренней VM
ping -c 3 jenkins.local.lab
ping -c 3 8.8.8.8
curl -I https://google.com
traceroute 8.8.8.8  # Должен идти через 192.168.100.60
```

---


**⭐ Если этот проект помог вам, поставьте звезду на GitHub!**

**🚀 Удачи!**

---

*Последнее обновление: 2025*

*Версия: 1.0.0*
                
