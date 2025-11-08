# The Ultimate CI/CD Corporate DevOps Pipeline Project (v4)

## Полное руководство по развертыванию enterprise-grade CI/CD инфраструктуры в Proxmox с изолированной сетью

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-K3s-326CE5?logo=kubernetes)](https://k3s.io/)
[![Jenkins](https://img.shields.io/badge/Jenkins-CI%2FCD-D24939?logo=jenkins)](https://www.jenkins.io/)
[![Terraform](https://img.shields.io/badge/Terraform-IaC-7B42BC?logo=terraform)](https://www.terraform.io/)

<img width="1150" height="824" alt="image" src="https://github.com/user-attachments/assets/a7ac7ef6-d24a-4506-8dcf-cd5088571936" />


## 📋 Содержание

- [О проекте](#-О-проекте)
- [Часть 1: Базовая инфраструктура](#часть-1-Базовая-инфраструктура)
  - [Этап 1: Сетевая инфраструктура](#Сетевая-топология)
  - [Этап 2: DNS Server](#Этап-2-Установка-DNS-сервера)
  - [Этап 3: Jumphost](#Этап-3-Настройка-Jumphost)
  - [Этап 4: Ngrok Tunnel](#Этап-4-Настройка-Ngrok-Tunnel)
- [Часть 2: Kubernetes кластер](#часть-2-Kubernetes-кластер)
  - [Этап 6: Установка K3s кластера](#Этап-6-Установка-K3s-кластера)
  - [Этап 7: MetalLB Load Balancer](#Этап-7-Установка-MetalLB)
  - [Этап 8: Traefik Ingress](#Этап-8-Установка-Traefik-Ingress)
- [Часть 3: CI/CD инструменты](#часть-3-cicd-инструменты)  
  - [Этап 10.1 Jenkins Server](#101-jenkins-server)
  - [Этап 10.2 SonarQube Server](#102-SonarQube-Server)
  - [Этап 10.3 Nexus Repository](#103-Nexus-Repository)
  - [Этап 10.4 Harbor Registry](#104-Harbor-Registry)
  - [Этап 10.5 Monitoring Server](#105-Monitoring-Server)
- [Часть 4: Интеграция и Pipeline](#Часть-4-Интеграция-и-Pipeline)
  - [Этап 11: Настройка Jenkins](#Этап-11-Настройка-Jenkins-Pipeline)
  - [Этап 12: Jenkins Pipeline](#этап-12-создание-jenkins-pipeline)
  - [Этап 13: Мониторинг Jenkins](#этап-13-установка-мониторинга-на-jenkins)
  - [Этап 14: Безопасность K8s](#этап-14-настройка-безопасности-k8s)
  - [Этап 15: Запуск Pipeline](#этап-15-запуск-pipeline)
  - [Этап 16: Проверка результатов](#этап-16-проверка-результатов)
- [Часть 5: Опционально настройка GitOps с ArgoCD](#Часть-5-Опционально-настройка-GitOps)
  - [Этап 16.1: Настройка Gitops ArgoCD](#Этап-16.1-Настройка-Gitop--ArgoCD)
- [Часть 6: Дополнительные настройки](#Часть-6-Дополнительные-настройки)
  - [Backup и Recovery](#Backup-и-Recovery)    
  
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

## Часть 1: Базовая инфраструктура

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
Отключаем systemd-resolver отвечает за файл /etc/resolv.conf и автоматически подставляет свой адрес 127.0.0.53
```bash
# Отключаем systemd-resolved чтобы небыло адреса 127.0.0.53 в /etc/resolv.conf:
sudo systemctl disable --now systemd-resolved
# =========== Проверяем его статус =============
echo Просмотр логов, нажмите CTRL+C
sudo systemctl status systemd-resolved
# Удаляем символическую ссылку на systemd-resolver
sudo rm /etc/resolv.conf
# Создаем новый resolv.conf с нашим сервером localhost где будет слушать теперь bind
sudo tee /etc/resolv.conf > /dev/null <<'EOF'
nameserver 127.0.0.1
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
grep -rn "127.0.0.1" /etc/resolv.conf || echo "сервер 127.0.0.1 не найден в /etc/resolv.conf"
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

Обновите пакеты 
```bash
sudo apt update -y
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

# Просмотр логов, нажмите CTRL+C
echo Просмотр логов, нажмите CTRL+C
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
grep -rn "192.168.100.53" /etc/resolv.conf || echo "Сервер 192.168.100.53 не найден в /etc/resolv.conf"

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
**Желательно скрипт запустить 2 раза, повторный для проверки, так как бывает что не прописывается DNS сервер**

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

## Часть 2: Kubernetes кластер

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
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -s - \
	--disable traefik \
        --write-kubeconfig-mode 644 \
        --node-name k3s-master \
        --cluster-domain local.lab \
        --node-ip 192.168.100.10 \
        --node-external-ip 192.168.100.10 \
        --tls-san k3s-master.local.lab \
        --tls-san 192.168.100.10 
```

Получите токен для worker nodes:

```bash
sudo cat /var/lib/rancher/k3s/server/node-token
```
**Сохраните токен!** Пример: `K10abc123def456::server:xyz789`

Проверька статуса запуска:

```bash
# Ожидание запуска (30-60 секунд)
sleep 60

# Проверка статуса
sudo systemctl status k3s

# Проверка ноды
sudo kubectl get nodes
```

### 6.2 Подключение Worker Nodes

**На k3s-worker1:**

```bash
ssh ubuntu@192.168.100.11
```
```bash


sudo apt update && sudo apt upgrade -y
curl -sfL https://get.k3s.io | K3S_URL=https://192.168.100.10:6443 \
  K3S_TOKEN="YOUR_TOKEN_FROM_MASTER" \
  sh -
```
**На k3s-worker2:**

```bash
ssh ubuntu@192.168.100.12
```
```bash
sudo apt update && sudo apt upgrade -y
curl -sfL https://get.k3s.io | K3S_URL=https://192.168.100.10:6443 \
  K3S_TOKEN="YOUR_TOKEN_FROM_MASTER" \
  sh -
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

## Этап 7: Установка MetalLB

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
Добавление строк включают веб интерфейс traefik на порт 9000
```
--set additionalArguments="{--api.insecure=true,--api.dashboard=true}" \
--set ports.traefik.port=9000
```


### 8.3 Проверка

```bash
kubectl get svc -n traefik

# Вы должны увидеть EXTERNAL-IP из диапазона MetalLB (например, 192.168.100.100)
```

---

## Часть 3: CI/CD инструменты

### 10.1 Jenkins Server

```bash
ssh ubuntu@192.168.100.20
```
```bash
# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```
## Некоторые ошибки при работе Docker
Ошибка: Если при во время сборки контейнера Docker в пайплайне, возникает ошибка "permision denied" :
```
+ docker build -t harbor.local.lab/library/boardgame:2 .

ERROR: permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Head "http://%2Fvar%2Frun%2Fdocker.sock/_ping": dial unix /var/run/docker.sock: connect: permission denied
```
Как исправить: Чтобы ее небыло, поправьте права для Docker:
```bash
sudo chmod 666 /var/run/docker.sock
sudo systemctl restart docker
sudo docker-compose ps
```

Ошибка: Docker не может соединится с Harbor потому-что у него самоподписанный сертификат, и что имя хоста не прописано в SAN, как резуультат в пайплайне видим "Unable docker login" или ошибку в логах:
```
Nov 06 09:05:52 jenkins dockerd[17233]: time="2025-11-06T09:05:52.411932345Z" level=info msg="Error logging in to endpoint, trying next endpoint" endpoint="{false https://harbor.local.lab false false false 0xc003a6e780}" error="Get \"https://harbor.local.lab/v2/\": tls: failed to verify certificate: x509: certificate relies on legacy Common Name field, use SANs instead"
Nov 06 09:05:52 jenkins dockerd[17233]: time="2025-11-06T09:05:52.411987949Z" level=error msg="Handler for POST /v1.51/auth returned error: Get \"https://harbor.local.lab/v2/\": tls: failed to verify certificate: x509: certificate relies on legacy Common Name field, use SANs instead"

```
Как исправить:

Добавляем цент сертификации Harbor в доверенные на машине Jenkins:
```bash
sudo scp admin@harbor.local.lab:/home/admin/harbor/ssl/harbor.local.lab.crt /usr/local/share/ca-certificates/harbor-ca.crt
sudo update-ca-certificates
sudo systemctl restart docker
```
Устанавливаем java17 и стартуем jenkins:
```
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

**Установка нужных прав для Jenkins**
```bash
sudo usermod -aG docker jenkins
sudo usermod -aG docker $USER
echo Проверка user jenkins  должен быть в группе docker
sudo getent group docker
```

**Установка kubectl:**


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
Примечание: При копировании config k3s мастера в Jenkins, возможно нужно поменять адрес 127.0.0.1 при загрузке файла через веб в jenkins credentials.

**Установка Trivy:**

```bash
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt update
sudo apt install -y trivy
```

**Установка Maven:**

```bash
sudo apt install -y maven
mvn --version
```
## Некоторые ошибки при работе sonar и maven которые возникают из за прав
**Установка нужных разрешений на каталог со сборщиком maven и сканером sonar cli, в этот каталог автоматически качаются нужные инструменты Jenkins'ом**

В основном все файлы и каталоги внутри /var/lib/jenkins должны иметь похожие разрешения, иначе могут возникнуть проблемы с закачкой или запуском плагинов. Если прав нет, при старте пайплайна можно увидеть ошибки установки sonarscaner или maven: 
```
sonar-scanner
— Use a tool from a predefined Tool Installation
3s
java.io.IOException: Failed to install https://repo1.maven.org/maven2/org/sonarsource/scanner/cli/sonar-scanner-cli/7.3.0.5189/sonar-scanner-cli-7.3.0.5189.zip to /var/lib/jenkins/tools/hudson.plugins.sonar.SonarRunnerInstallation/sonar-scanner
```
или
```
maven3.6
— Use a tool from a predefined Tool Installation
<1s
java.io.IOException: Failed to install https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/3.9.5/apache-maven-3.9.5-bin.zip to /var/lib/jenkins/tools/hudson.tasks.Maven_MavenInstallation/maven3.6
```
Ставим нужные права на каталог tools чтобы избежать ошибок которые сверху:
```bash
sudo mkdir -p /var/lib/jenkins/tools/
sudo chown -R jenkins:jenkins /var/lib/jenkins/tools/
sudo chmod 755 -R /var/lib/jenkins/tools/
```

**Доступ к Jenkins:** `https://jenkins.your-domain.com:8080`


### 10.2 SonarQube Server

```bash
ssh ubuntu@192.168.100.30
```
```bash
# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка Docker
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl vim openssl docker.io docker-compose
sudo systemctl enable docker --now
docker --version
docker-compose --version
sudo usermod -aG docker $USER
sudo usermod -aG docker ubuntu

# Настройка системы для SonarQube
sudo sysctl -w vm.max_map_count=524288
sudo sysctl -w fs.file-max=131072
echo "vm.max_map_count=524288" | sudo tee -a /etc/sysctl.conf
echo "fs.file-max=131072" | sudo tee -a /etc/sysctl.conf

sudo tee docker-compose.yml > /dev/null <<'EOF'
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


**Примечание:**    По умолчанию контейнер SonarQube и Postgresql стирают свои данные при перезапуске (sudo docker-compose down).  Поэтому нужно создать другой yaml файл с persistent volume, то есть хранением данных на хостовой машине. Вот пример постоянной машины Sonarqube:
```
sudo tee docker-compose.yml > /dev/null <<EOF
services:
  db:
    image: postgres:15
    container_name: sonarqube_db
    restart: unless-stopped
    environment:
      POSTGRES_USER: sonar
      POSTGRES_PASSWORD: sonar
      POSTGRES_DB: sonarqube
    volumes:
      - sonarqube_db_data:/var/lib/postgresql/data

  sonarqube:
    image: sonarqube:25.10.0.114319-community
    container_name: sonarqube
    restart: unless-stopped
    depends_on:
      - db
    environment:
      SONAR_JDBC_URL: jdbc:postgresql://db:5432/sonarqube
      SONAR_JDBC_USERNAME: sonar
      SONAR_JDBC_PASSWORD: sonar
    ports:
      - "9000:9000"
    volumes:
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_extensions:/opt/sonarqube/extensions
      - sonarqube_logs:/opt/sonarqube/logs

volumes:
  sonarqube_db_data:
  sonarqube_data:
  sonarqube_extensions:
  sonarqube_logs:
EOF
```


### Запуск SonarQube если он не запущен

```bash
sudo docker-compose up -d
```
Нужно пождать 3-5 минут пока скачаются docker образы sonarqube и postgresql.

**Проверка:**
```bash
sudo docker-compose logs
sudo docker ps
sudo docker logs -f admin-sonarqube-1
sudo docker logs -f sonarqube_db

```
**Настройка Webhook для этапа QualityGate:**
Нужно обязательно настроить веб хуки для Jenkins, когда код проекта будет проверен, SonarQube отправит вебхук в Jenkins, что проверка завршена. В противном случае,задание Quality Gate будет висеть минут 5 и потом вывалится в ошибку, так как Jenkins не получил веб хук от SonarQube.


- **Указываем адрес хоста SonarQube чтобы при отправке webhook формировался верный json:** Administration → Congiguration → General Settings → Server base URL → http://sonar.local.lab:9000
- **Создаем вебхук идем в меню Administration:**
Administration -> Configuration -> Webhooks -> Create
Project -> Boardgame -> Project Settings -> Webhooks -> Create
- Name: jenkins-webhook
- URL: http://jenkins.local.lab:8080/sonarqube-webhook/
- Create

**Также можно повешать вебхуки на отдельный проект**
Project -> Boardgame -> Project Settings -> Webhooks -> Create



<img width="1100" height="755" alt="image" src="https://github.com/user-attachments/assets/ae38f361-e5f3-49be-8548-fa819e3c0cc0" />
Веб интерфейс sonarqube.

**Доступ:** `https://sonar.your-domain.com:9000`  
**Логин:** admin/admin (измените после первого входа)

### 10.3 Nexus Repository

```bash
ssh ubuntu@192.168.100.31
```

```bash


# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка Docker
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl vim openssl docker.io docker-compose
sudo systemctl enable docker --now
docker --version
docker-compose --version
sudo usermod -aG docker $USER
sudo usermod -aG docker ubuntu

# Запуск Nexus
sudo docker run -d \
  --name nexus \
  --restart=unless-stopped \
  -p 8081:8081 \
  -v nexus-data:/nexus-data \
  sonatype/nexus3

# Ожидание запуска (~15  секунд)
sleep 15

# Получение initial admin password
sudo docker exec nexus cat /nexus-data/admin.password; echo
```

**Доступ:** `https://nexus.your-domain.com:8081`  
**Логин:** admin + пароль из команды выше

Примечание: При установке Nexus по умолчанию создаются 2 репозитория **maven-releases** и **maven-snapshots**. Если их нет, нужно будет создать. 

**Создание репозиториев:**
1. Sign in
2. Server administration (шестеренка) → Repositories → Create repository
3. Создайте: `maven-releases` (maven2 hosted)
4. Создайте: `maven-snapshots` (maven2 hosted)

### 10.4 Harbor Registry

```bash
ssh ubuntu@192.168.100.32
```
```bash

# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка Docker и Docker Compose
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl vim openssl docker.io docker-compose
sudo systemctl enable docker --now
docker --version
docker-compose --version

# Скачивание Harbor
cd ~
wget https://github.com/goharbor/harbor/releases/download/v2.9.0/harbor-offline-installer-v2.9.0.tgz
tar xzvf harbor-offline-installer-v2.9.0.tgz
cd harbor

# Конфигурация
cp harbor.yml.tmpl harbor.yml
```
## Некоторые ошибки при работе Harbor
**Настройка SSL для Harbor:**
По сути Harbor может работать по HTTP, внутри локальной сети это безопасно, так как закрытый контур. Но для большей безопасности, можно настроить HTTPS доступ. Правильная настройка SSL важна, так как могут возникнуть ошибки доступа, например:
```
Hmmm… can't reach this page It looks like the webpage at https://harbor.local.lab/harbor/projects might be having issues, or it may have moved permanently to a new web address. ERR_SSL_KEY_USAGE_INCOMPATIBLE
```
**Важные замечания:** Настройки генерации сертификата san.cnf должны содержать блок для корректной работы nginx, chrome, edge:
```
[v3_req]
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
```
Почему это важно:
- digitalSignature — разрешает использовать сертификат для установления TLS-соединения (подписание сессии).
- keyEncipherment — разрешает шифрование ключей в процессе обмена.
- dataEncipherment в браузерах не нужен и иногда вызывает конфликт (особенно в Chrome).
- 
**Если данного блока не будет - Chrome/Edge увидят, что сертификат «не предназначен для TLS-аутентификации», и покажут ошибку ERR_SSL_KEY_USAGE_INCOMPATIBLE**

Генерация ключей без sudo, если будет через sudo, владельцем ключей станет учетная запись root, из за этого harbor не будет видет ключи.
```bash
mkdir -p ~/harbor/ssl
cd ~/harbor/ssl
# Создаем собственной центр сертификации
# Здесь ca.key — приватный ключ вашей CA.
openssl genrsa -out ca.key 4096         
 # ca.crt — корневой сертификат, который будет подписывать серверные сертификаты, в нашем случае Harbor.
openssl req -x509 -new -nodes -key ca.key -sha256 -days 3650 -out ca.crt -subj "/CN=MyHarborCA"        

# Генерация приватного ключа и запроса для Harbor сервера
# harbor.local.lab.key — приватный ключ Harbor.
# harbor.local.lab.csr — запрос на сертификат (CSR), который потом подпишет наша CA.
openssl genrsa -out harbor.local.lab.key 4096
openssl req -new -key harbor.local.lab.key -out harbor.local.lab.csr -subj "/CN=harbor.local.lab"

# Создание SAN-конфига
# Этот файл указывает все имена (SAN) - harbor.local.lab. 192.168.100.32, 127.0.0.1
# по которым сертификат будет считаться валидным. 
sudo tee san.cnf > /dev/null <<EOF
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
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = harbor.local.lab
DNS.2 = localhost
IP.1 = 127.0.0.1
IP.2 = 192.168.100.32
EOF

# Подписание серверного сертификата CA
openssl x509 -req -in harbor.local.lab.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out harbor.local.lab.crt -days 3650 -sha256 -extfile san.cnf -extensions v3_req

```
Проверка что сертификат выписан на хост harbor.local.lab:
```
openssl x509 -in harbor.local.lab.crt -noout -text | grep -A1 "Subject Alternative Name"
```
Отредактируйте `harbor.yml`:

```bash
cd ..
nano harbor.yml
```

Измените:

```yaml
# hostname harbor.local.lab
hostname: harbor.your-domain.com

# https:
# port: 80
# Закомментируйте HTTPS для начала (настроим через Cloudflare)
# https:
#   port: 443
#   certificate: /your/certificate/path
#   private_key: /your/private/key/path
port: 443
# #абсолютные пути
certificate: /home/admin/harbor/ssl/harbor.local.lab.crt
private_key: /home/admin/harbor/ssl/harbor.local.lab.key

harbor_admin_password: YourSecurePassword123!

database:
  password: root123

data_volume: /data
```
Здесь важно поменять:
- hostname:
- port и пути к сертификатам

Установка:

```bash
sudo ./install.sh
```
<img width="1889" height="709" alt="image" src="https://github.com/user-attachments/assets/3f4cc9ac-1bb5-44bc-bda4-d1c0dcd983ab" />
Успешный запуск Harbor.

**Проверка:**
```bash
cd ~/harbor
sudo docker-compose ps

```
Примерный вывод:
```bash
admin@harbor:~/harbor$ sudo docker compose ps
WARN[0000] /home/admin/harbor/docker-compose.yml: the attribute `version` is obsolete, it will be ignored, please remove it to avoid potential confusion 
NAME                IMAGE                                COMMAND                  SERVICE       CREATED         STATUS                   PORTS
harbor-core         goharbor/harbor-core:v2.9.0          "/harbor/entrypoint.…"   core          6 minutes ago   Up 6 minutes (healthy)   
harbor-db           goharbor/harbor-db:v2.9.0            "/docker-entrypoint.…"   postgresql    6 minutes ago   Up 6 minutes (healthy)   
harbor-jobservice   goharbor/harbor-jobservice:v2.9.0    "/harbor/entrypoint.…"   jobservice    6 minutes ago   Up 5 minutes (healthy)   
harbor-log          goharbor/harbor-log:v2.9.0           "/bin/sh -c /usr/loc…"   log           6 minutes ago   Up 6 minutes (healthy)   127.0.0.1:1514->10514/tcp
harbor-portal       goharbor/harbor-portal:v2.9.0        "nginx -g 'daemon of…"   portal        6 minutes ago   Up 6 minutes (healthy)   
nginx               goharbor/nginx-photon:v2.9.0         "nginx -g 'daemon of…"   proxy         6 minutes ago   Up 6 minutes (healthy)   0.0.0.0:80->8080/tcp, [::]:80->8080/tcp, 0.0.0.0:443->8443/tcp, [::]:443->8443/tcp
redis               goharbor/redis-photon:v2.9.0         "redis-server /etc/r…"   redis         6 minutes ago   Up 6 minutes (healthy)   
registry            goharbor/registry-photon:v2.9.0      "/home/harbor/entryp…"   registry      6 minutes ago   Up 6 minutes (healthy)   
registryctl         goharbor/harbor-registryctl:v2.9.0   "/home/harbor/start.…"   registryctl   6 minutes ago   Up 6 minutes (healthy)   

```


========================================
**Доп. команды:***

Автозапуск Harbor при перезагрузке:
```bash
cd ~/harbor
# Ставим unless-stopped вместо always, так как при always контейнер всегда пытается перезапустится даже если сбой, unless-stopped если сбой останаливает работу
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
sudo docker ps
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

Примечание: При первой установке Harbor создается библиотека library, если ее нет создайте в ручную через настрйку проекта снизу.

**Настройка проекта:**
1. Projects → NEW PROJECT
2. Project Name: `library`
3. Access Level: Public
4. OK


## Некоторые ошибки при работе k3s нод с хранилищем Harbor, ноды проверяют валидность сертификата и выдают ошибку если он самоподписанный
**k3s-master и worker ноды k3s-worker-1 и k3s-worker-2 проверяют сертификат Harbor, так как он самоподписанный, возникает ошибка:**

```
E1106 14:42:23.565238   11549 log.go:32] "PullImage from image service failed" err="rpc error: code = Unknown desc = failed to pull and unpack image \"harbor.local.lab/library/boardgame:65\": failed to resolve reference \"harbor.local.lab/library/boardgame:65\": failed to do request: Head \"https://harbor.local.lab/v2/library/boardgame/manifests/65\": tls: failed to verify certificate: x509: certificate signed by unknown authority" image="harbor.local.lab/library/boardgame:65"
FATA[0000] pulling image: failed to pull and unpack image "harbor.local.lab/library/boardgame:65": failed to resolve reference "harbor.local.lab/library/boardgame:65": failed to do request: Head "https://harbor.local.lab/v2/library/boardgame/manifests/65": tls: failed to verify certificate: x509: certificate signed by unknown authority
```
Поэтому нужно отключить отключить проверку SSL для Harbor хоста на всех 3 нодах кластера k3s-master и 2-х worker:
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
```
Перезапуск на master ноде:
```bash
sudo systemctl restart k3s
```
Перезапуск на worker1 и worker2 ноде:
```bash
sudo systemctl restart k3s-agent
```

Проверка доступа k3s-master и worker1-2 нодах к образу на harbor сервере, должна быть закачка:
```bash
sudo crictl pull harbor.local.lab/library/myapp:139
# Примерный вывод
echo "Image is up to date for sha256:12ed91993dd46b4a37671240000ad784d159759ad52a3f35fac225a99f12f59b"
```

## Ошибка при работе с jenkins: Docker на машине Jenkins не может соединится с Harbor потому-что у него самоподписанный сертификат, и что имя хоста не прописано в SAN, как резуультат в пайплайне видим "Unable docker login" или ошибку в логах:
```
Nov 06 09:05:52 jenkins dockerd[17233]: time="2025-11-06T09:05:52.411932345Z" level=info msg="Error logging in to endpoint, trying next endpoint" endpoint="{false https://harbor.local.lab false false false 0xc003a6e780}" error="Get \"https://harbor.local.lab/v2/\": tls: failed to verify certificate: x509: certificate relies on legacy Common Name field, use SANs instead"
Nov 06 09:05:52 jenkins dockerd[17233]: time="2025-11-06T09:05:52.411987949Z" level=error msg="Handler for POST /v1.51/auth returned error: Get \"https://harbor.local.lab/v2/\": tls: failed to verify certificate: x509: certificate relies on legacy Common Name field, use SANs instead"

```
Как исправить:

Переходим на машину Jenkins и добавляем центр сертификации Harbor в доверенные:
```bash
sudo scp admin@harbor.local.lab:/home/admin/harbor/ssl/harbor.local.lab.crt /usr/local/share/ca-certificates/harbor-ca.crt
sudo update-ca-certificates
sudo systemctl restart docker
```

### 10.5 Monitoring Server

```bash
ssh ubuntu@192.168.100.40
```

```bash


# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка Docker и Docker Compose
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl vim openssl docker.io docker-compose
sudo systemctl enable docker --now
docker --version
docker-compose --version


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
```
```bash
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
sudo docker-compose up -d

# Проверка
sudo docker-compose ps
sudo docker-compose logs -f
```

**Доступ:**
- Prometheus: `http://prometheus.local.lab:9090` или лучше http://monitoring.local.lab:9090 (будет через Grafana)
- Grafana: `http://grafana.local.lab:3000` (admin/admin) или лучше http://monitoring.local.lab:3000
- По умолчанию доступ только по http без шифрования

## Настройка nginx reversy proxy для включения доступ к контейнерам по HTTPS
Чтобы заработало HTTPS шифрование по самоподписанному сертификату нужно настроить nginx reversy proxy.
Сертификат создадим для следующих URL (SAN) - monitoring.local.lab, grafana.local.lab, prometheus.local.lab

**Важные замечания:** Сертификат должен отвечать за разные доменные имена grafana.local.lab (CNAME в DNS на хост monitoring.local.lab), prometeus.local.lab (CNAME в DNS на хост monitoring.local.lab) и montiring.local.lab. Чтобы создать такой сертификат, нужно использовать SAN (один сертификат на для множества доменов). Права на файлы сертификата обязательно должны принадлежать локальному неприлегированному пользователю admin из под которого запускается docker (compose). 

```bash
sudo apt install -y nginx
sudo mkdir -p /etc/ssl/monitoring
cd /etc/ssl/monitoring
sudo tee san.cnf > /dev/null <<'EOF'
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
C = KZ
ST = State
L = City
O = DevOps
OU = Monitoring
CN = monitoring.local.lab

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = monitoring.local.lab
DNS.2 = grafana.local.lab
DNS.3 = prometheus.local.lab
DNS.4 = localhost
IP.1 = 127.0.0.1
EOF

sudo openssl genrsa -out monitoring.key 4096
sudo openssl req -new -key monitoring.key -out monitoring.csr -subj "/CN=monitoring.local.lab"
sudo openssl x509 -req -in monitoring.csr -signkey monitoring.key -out monitoring.crt -days 3650 -extfile san.cnf
sudo ls /etc/ssl/monitoring/
# Получаем 2 файла  monitoring.crt и monitoring.key, которые можно использовать для всех трёх доменов.
```
Настройка самого nginx reversy proxy:
```bash
sudo tee /etc/nginx/sites-available/monitoring.conf > /dev/null << 'EOF'
# ========================
# Grafana
# ========================
server {
    listen 443 ssl;
    server_name grafana.local.lab monitoring.local.lab;

    ssl_certificate /etc/ssl/monitoring/monitoring.crt;
    ssl_certificate_key /etc/ssl/monitoring/monitoring.key;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}

# ========================
# Prometheus
# ========================
server {
    listen 443 ssl;
    server_name prometheus.local.lab;

    ssl_certificate /etc/ssl/monitoring/monitoring.crt;
    ssl_certificate_key /etc/ssl/monitoring/monitoring.key;

    location / {
        proxy_pass http://127.0.0.1:9090;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}

# ========================
# HTTP → HTTPS redirect
# ========================
server {
    listen 80;
    server_name grafana.local.lab prometheus.local.lab monitoring.local.lab;
    return 301 https://$host$request_uri;
}

EOF
```
Активация конфига и перезапуск nginx:
```bash
sudo ln -s /etc/nginx/sites-available/monitoring.conf /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```
**Доступ:**
Итого можно теперь заходить по https 
- `https://grafana.local.lab`
- `https://prometheus.local.lab`
Не шифрованный доступ 
- Prometheus: `http://prometheus.local.lab:9090` или (`http://monitoring.local.lab:9090`)
- Grafana: `http://grafana.local.lab:3000` (admin/admin) или (`http://monitoring.local.lab:3000`)


=========Возможно нужно удалить============================
Сохранение k3s конфига в ~/.kube/config
```bash
export KUBECONFIG=~/.kube/config
sudo mkdir ~/.kube 2> /dev/null
sudo k3s kubectl config view --raw > "$KUBECONFIG"
sudo chmod 600 "$KUBECONFIG"
echo export KUBECONFIG=~/.kube/config  >> ~/.profile
```
=========Возможно нужно удалить============================

---
## Часть 4: Интеграция и Pipeline
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
- Email Extension Template
- Generic Webhook Trigger (включение веб хуков)
- Eclipse Temurin installer (позволяет устанавливать разные версии Java с сайта adoptium.net)
- Blue Ocean (опционально, для красивого UI)
- Pipeline Stage View (еще один красивый UI)
- CloudBees Disk Usage Simple (для Prometheus)


После установки:  ✓  **Restart Jenkins** или пройти по ссылке http://jenkins.local.lab:8080/restart


### 11.3 Настройка Tools

**Manage Jenkins → Tools**

**JDK:**
- Name: `java17`
- ✓ Install automatically
Примечание: Также можно установить версию Version: jdk-17.0.9 , нужно выбрать - ✓ Install from adoptium.net)

**Maven:**
- Name: `maven3.6`
- ✓ Install automatically
- Version: 3.6.1

**Docker:**
- Name: `docker`
- ✓ Install automatically
- Download from docker.com

**SonarQube Scanner:**
- Name: `sonar-scanner`
- ✓ Install automatically (можно не отмечать так мы установим в ручную внизу)
- Version: Latest

**Установка Sonar cli scaner:**
```bash
wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-7.3.0.5189.zip -O /tmp/sonar-scanner-cli.zip
sudo mkdir -p /var/lib/jenkins/tools/hudson.plugins.sonar.SonarRunnerInstallation/sonar-scanner
sudo unzip /tmp/sonar-scanner-cli.zip -d /var/lib/jenkins/tools/hudson.plugins.sonar.SonarRunnerInstallation/sonar-scanner
sudo chown -R jenkins:jenkins /var/lib/jenkins/tools/
sudo chmod 755 -R /var/lib/jenkins/tools/
sudo ln -s /var/lib/jenkins/tools/hudson.plugins.sonar.SonarRunnerInstallation/sonar-scanner/sonar-scanner-7.3.0.5189/bin/sonar-scanner /usr/local/bin/sonar-scanner
```
**Новая установка Sonar cli scaner (ручная):**
```bash
wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-7.3.0.5189.zip -O /tmp/sonar-scanner-cli.zip
sudo mkdir -p /opt/sonar-scanner
sudo unzip /tmp/sonar-scanner-cli.zip -d /opt/sonar-scanner 
# Узнаем версию сканера:
ls /opt/sonar-scanner
sonar-scanner-7.3.0.5189
# Добавляем в PATH путь к сканеру:
sudo echo "export PATH=/opt/sonar-scanner/sonar-scanner-7.3.0.5189/bin:$PATH" >> /home/admin/.profile
# Применяем изминения
source /home/admin/.profile
# Проверка установки, вывод help по сканеру
sonar-scanner -h
```

### 11.4 Настройка Credentials

**Manage Jenkins → Manage Credentials → Global → Add Credentials**
Когда Jenkins запускает Pipeline из файла jenkinsfile, он ищет авторизационные данные по ID. Поэтому нужно сверить ID из Jenkinsfile с ID в веб интерфейсе - они должны совпадать.

**1. GitHub Token:**
- Kind: Username with password
- name: https://github.com/-----> NAME <---/Boardgame, у меня здесь sysops8
- Secret: `<your-github-personal-access-token>`- 
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
Справа в верхнем углу есть настройка My Account:
```
SonarQube → "My Account → Security → Generate Tokens  →  User token  → Generate
```

**4. Kubernetes Config:**
- Kind: Secret file
- File: Upload `~/.kube/config`
- ID: `k8s-kubeconfig`
- Description: Kubernetes Config
- Внутри файла поменять адрес 127.0.0.1 на k3s-master.local.lab и только потом загружать в jenkins
- Примечание: файл config можно взять с jumphost, jenkins хоста или непосредственно с k3s-master ноды поменяв внутри 127.0.0.1 на DNS имя k3s-master.local.lab 

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
- Username: `admin`
- Password: `<your-nexus-password>`
- ID: `nexus-creds`
- Description: Nexus Credentials
- Пользователя jenkins нужно создать на сервере nexus и дать ему права админа.
  
### 11.5 Настройка SonarQube Server в Jenkins

**Manage Jenkins →  System → SonarQube servers**

- ✓ Enable injection of SonarQube server configuration
- ✓ Environment variables
- ✓ Add SonarQube 
- Name: `SonarQube`
- Server URL: `http://192.168.100.30:9000` или `http://sonar.local.lab:9000`
- Server authentication token: Select `sonar-token`

### 11.6 Настройка Maven Settings

**Manage Jenkins → Managed files → Add a new Config → Global Maven settings.xml**
Настройки репозитория в settings.xml должны совпадать с github.com/username/boardgame/pom.xml, важно чтобы ID репозиториев совпадали.
То есть имя репозитория <id>nexus-releases</id> из settings.xml совпадает с именем в pom.xml который на github.com.
Заполняем:
- ID: `maven-settings`
- Name: `Maven Settings`

Server Credentials
- ServerID: `nexus`
- Credentials: `nexus-creds`

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
Примечание: После этого можно переходить к этапу **Этап 15: Запуск Pipeline**

## Этап 12: Создание Jenkins Pipeline

Мы создаем проект который будет брать настройки для разворачивания приложения в kubernetes с файла github.com/username/Boardgame/k8s_deployment.yaml. Аналогично другие настройки также лежат в файлах на github.
Рабочий pipeline должен лежать в корне вашего проекта на репозитории, у меня он лежит в на githube.com -  https://github.com/sysops8/Boardgame/Jenkinsfile
В Jenkinsfile описывается весь весь CI/CD процесс, то есть Build, Test и Deploy.
Пример файла:
```Jenkinsfile
pipeline {
    agent any

    environment {
        MYAPP = "boardgame"

        // Harbor
        HARBOR_URL = "harbor.local.lab"
        HARBOR_PROJECT = "library"
        HARBOR_CREDENTIALS = "harbor-creds"
        
        // Harbor image name
        IMAGE_NAME = 'boardgame'
        IMAGE_TAG = "${BUILD_NUMBER}"
        FULL_IMAGE_NAME = "${HARBOR_URL}/${HARBOR_PROJECT}/${IMAGE_NAME}:${IMAGE_TAG}"
        LATEST_IMAGE_NAME = "${HARBOR_URL}/${HARBOR_PROJECT}/${IMAGE_NAME}:latest"
        
        // Nexus
        NEXUS_URL = "http://nexus.local.lab:8081/repository/maven-releases/"
        NEXUS_CREDENTIALS = "nexus-creds"

        // SonarQube
        SONARQUBE_SERVER = "SonarQube"
        SONARQUBE_URL = "http://sonar.local.lab:9000"
        SONARQUBE_CREDENTIALS = "sonar-token"

        // Kubernetes
        KUBECONFIG_CREDENTIALS = "k8s-kubeconfig"

        // Email
        EMAIL_RECIPIENTS = "almastvx@gmail.com"        


    }

    stages {
        stage('Checkout') {
            steps {
                echo "Checking out source code..."
                checkout scm
            }
        }
    stage('Set Build Version') {
        steps {
            script {
                sh "mvn versions:set -DnewVersion=0.0.${env.BUILD_NUMBER}"                
            }
        }
    }
        stage('Build Docker Image') {
            steps {
                script {
                    dockerImage = docker.build("${HARBOR_URL}/${HARBOR_PROJECT}/${MYAPP}:${env.BUILD_NUMBER}")
                    
                }
            }
        }

        stage('Push Docker Image to Harbor') {
            steps {
                script {
                    docker.withRegistry("http://${HARBOR_URL}", HARBOR_CREDENTIALS) {
                        dockerImage.push()
                        dockerImage.push('latest') // optional
                    }
                }
            }
        }

        stage('Publish Artifacts to Nexus') {
            steps {
                echo "📤 Publishing Maven artifacts to Nexus..."
                configFileProvider([configFile(fileId: 'maven-settings', variable: 'MAVEN_SETTINGS')]) {
                    withCredentials([usernamePassword(credentialsId: NEXUS_CREDENTIALS, usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PSW')]) {
                        sh """
                            mvn clean deploy -s $MAVEN_SETTINGS \
                                -DaltDeploymentRepository=nexus::default::${NEXUS_URL} \
                                -Dnexus.username=${NEXUS_USER} \
                                -Dnexus.password=${NEXUS_PSW}
                        """
                    }
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv("${SONARQUBE_SERVER}") {
                    sh "mvn sonar:sonar -Dsonar.host.url=${SONARQUBE_URL}"
                }
            }
        }

        
        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: false, credentialsId: "${SONARQUBE_CREDENTIALS}"
                }
            }
        }
        
        stage('Update K8s Manifest') {
            steps {
                script {
                    echo "📝 Updating Kubernetes manifest with image: ${HARBOR_URL}/${HARBOR_PROJECT}/${MYAPP}:${env.BUILD_NUMBER}"
        
                    // Используем безопасную оболочку без Groovy-интерполяции
                    sh '''
                        IMAGE_TAG="${HARBOR_URL}/${HARBOR_PROJECT}/${MYAPP}:${BUILD_NUMBER}"
                        if [ ! -f k8s_deployment-service.yaml ]; then
                            echo "❌ File k8s_deployment-service.yaml not found!"
                            exit 1
                        fi
                        echo "Updating image to: $IMAGE_TAG"
                        sed -i "0,/image:/s|image: .*|image: $IMAGE_TAG|" k8s_deployment-service.yaml
                        #sed -i 's|newTag:.*|newTag: "'${BUILD_NUMBER}'"|g' k8s_deployment-service.yaml
                        echo "✅ Manifest updated successfully:"
                        grep "image:" k8s_deployment-service.yaml
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([file(credentialsId: KUBECONFIG_CREDENTIALS, variable: 'KUBECONFIG_FILE')]) {
                    sh """
                        export KUBECONFIG=${KUBECONFIG_FILE}
                        kubectl apply -f k8s_deployment-service.yaml
                    """
                }
            }
        }
        
        stage('Health Check') {
            steps {
                script {
                    echo "🩺 Checking application health..."
                    withCredentials([file(credentialsId: KUBECONFIG_CREDENTIALS, variable: 'KUBECONFIG_FILE')]) {
                        sh '''
                            export KUBECONFIG=${KUBECONFIG_FILE}
                            kubectl wait --for=condition=available --timeout=60s deployment/boardgame-deployment
                            kubectl get pods -o wide | grep boardgame
                            kubectl wait --for=condition=ready pod -l app=boardgame -n default --timeout=60s  
                        '''
                    }
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                withCredentials([file(credentialsId: KUBECONFIG_CREDENTIALS, variable: 'KUBECONFIG_FILE')]) {
                    sh """
                        export KUBECONFIG=${KUBECONFIG_FILE}
                        kubectl rollout status deployment/boardgame-deployment
                    """
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
                    echo "🎉 Pipeline completed successfully!"
                    echo "📧 Sending success notification..."              
                    
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
                                            <a href="https://boardgame.apps.local.lab">https://boardgame.apps.local.lab</a>
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
                        to: EMAIL_RECIPIENTS,
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
                        to: EMAIL_RECIPIENTS,
                        mimeType: 'text/html'
                    )
                }
            }
}
```


Цепочка pipeline:
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

---

## Этап 13: Установка мониторинга на Jenkins

### 13.1 Установка Node Exporter на Jenkins

```bash
ssh ubuntu@192.168.100.20
```
```bash
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
2. Item name: `boardgame`
3. Type: **Pipeline**
4. OK

**General:**
- ✓ Discard old builds
  - Max # of builds to keep: `10`
- ✓ GitHub project
  - Project url: `https://github.com/YOUR_USERNAME/boardgame/`


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
<img width="1919" height="738" alt="image" src="https://github.com/user-attachments/assets/f5f1e156-189d-4d07-b5ad-d8ba2fd0b657" />

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

<img width="1916" height="991" alt="image" src="https://github.com/user-attachments/assets/ee9e1dde-3944-46b1-96d7-71066b84bd91" />


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

Пример письма:
<img width="1919" height="874" alt="image" src="https://github.com/user-attachments/assets/e728c7cd-83a8-4904-9511-9bab0c747837" />

---
## Часть 5: Опционально настройка GitOps

Подключитесь к Jumphost серверу:
```bash
ssh admin@j192.168.100.5
# или
ssh admin@jumphost.local.lab
```
## Этап 16.1: Настройка Gitops ArgoCD

- Установка ArgoCD
- Настройка доступа
- Подготовка Git репозитория
- Создание ArgoCD Application
- Обновление Jenkins Pipeline
- Проверка работы

Удаляем старые pods в namespace default чтобы потом их создавать в production:
```bash
kubectl delete pod -l app=boardgame
```
```
pod "boardgame-deployment-5d8c66bb9-jwv9f" deleted from default namespace
pod "boardgame-deployment-5d8c66bb9-m8ptf" deleted from default namespace
```
Создаем новый namespace production:
```bash
kubectl create namespace production
```

Установка ArgoCD, делаем на Jumphost'е:
```bash
# Создание namespace
kubectl create namespace argocd
kubectl create namespace production
# Установка ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Ожидание готовности
kubectl wait --for=condition=available --timeout=300s deployment --all -n argocd

# Проверка подов
kubectl get pods -n argocd
```
Создаем argocd-service-lb.yaml:
```bash
sudo tee argocd-service-lb.yaml > /dev/null <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: argocd-server-lb
  namespace: argocd
  labels:
    app.kubernetes.io/name: argocd-server
spec:
  type: LoadBalancer
  loadBalancerIP: 192.168.100.105   # выбераем свободный IP из пула Metallb, это приявязка статического IP к argocd, чтобы не менялся при перезагзуке
  selector:
    app.kubernetes.io/name: argocd-server
  ports:
    - name: http
      port: 80
      targetPort: 8080
      protocol: TCP
    - name: https
      port: 443
      targetPort: 8080
      protocol: TCP
EOF

kubectl apply -f argocd-service-lb.yaml
# Получение LoadBalancer IP
kubectl get svc argocd-server-lb -n argocd
# Запишите EXTERNAL-IP (например, 192.168.100.105)
```
Примечание: Здесь указываем внешний IP адрес на котором будет работать Argocd, запрашиваем IP у MetalLB из его диапозона 192.168.100.100-150. Важно чтобы адрес был не занятый, у нас 100 принадлжеит Traefik и 101 у приложения Boargame, значить мы можем взять IP все что выше 102. Если указать уже занятый IP, то можно при выводе сервиса get svc -n argocd увидеть PENDING вместо IP например 192.168.100.105. То есть нельзя использовать уже занятые IP 100 и 101.

**Добавление RBAC политик**

Создание или обновление ConfigMap с необходимыми политиками:
```yaml
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-rbac-cm
  namespace: argocd
  labels:
    app.kubernetes.io/name: argocd-rbac-cm
    app.kubernetes.io/part-of: argocd
data:
  policy.csv: |
    g, admin, role:admin
    p, role:admin, applications, *, */*, allow
    p, role:admin, clusters, get, *, allow
    p, role:admin, repositories, get, *, allow
    p, role:admin, projects, get, *, allow
  policy.default: role:readonly
EOF
```
Проверка:
```bash
kubectl get configmap argocd-rbac-cm -n argocd -o yaml
```
Вывод:
```
admin@jumphost:~$ kubectl get configmap argocd-rbac-cm -n argocd -o yaml
apiVersion: v1
data:
  policy.csv: |
    g, admin, role:admin
    p, role:admin, applications, *, */*, allow
    p, role:admin, clusters, get, *, allow
    p, role:admin, repositories, get, *, allow
    p, role:admin, projects, get, *, allow
  policy.default: role:readonly
kind: ConfigMap
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"v1","data":{"policy.csv":"g, admin, role:admin\np, role:admin, applications, *, */*, allow\np, role:admin, clusters, get, *, allow\np, role:admin, repositories, get, *, allow\np, role:admin, projects, get, *, allow\n","policy.default":"role:readonly"},"kind":"ConfigMap","metadata":{"annotations":{},"labels":{"app.kubernetes.io/name":"argocd-rbac-cm","app.kubernetes.io/part-of":"argocd"},"name":"argocd-rbac-cm","namespace":"argocd"}}
  creationTimestamp: "2025-11-08T10:07:00Z"
  labels:
    app.kubernetes.io/name: argocd-rbac-cm
    app.kubernetes.io/part-of: argocd
  name: argocd-rbac-cm
  namespace: argocd
  resourceVersion: "16354"
  uid: b416cca7-191b-4815-9667-ad3ea2d0f9c6

```

Создание приложение в production namespace, раньше был в default, перенесем его туда:
```
argocd app create boardgame \
  --repo https://github.com/sysops8/boardgame-gitops.git \
  --path apps/boardgame \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace production \
  --sync-policy automated \
  --auto-prune \
  --self-heal \
  --server argocd.local.lab \
  --auth-token "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJhcmdvY2QiLCJzdWIiOiJhZG1pbjphcGlLZXkiLCJuYmYiOjE3NjI2MDgyMzMsImlhdCI6MTc2MjYwODIzMywianRpIjoiMWFmZWNmZjEtNGFlNS00MzZkLWFhOTEtYzY5OWJiOTk1OTcyIn0.OSluIoqwI6w_5wOqy8cyTUe5wp5l6Nwp0LLmAJH4YHs" \
  --grpc-web \
  --insecure
```
Здесь важные параметры:
- repo - Репозитори GitOps
- path - путь внутри репозитория GitOps к файлам развертывания
- dest - в каком NS разворачивать приложение
- sync-policy - тип синхронизации
- auth-token - токен который мы получаем через команду `argocd account generate-token --account admin`

**Добавление DNS записи**
На DNS сервере (192.168.100.53):
```bash
echo "argocd          IN      A       192.168.100.105" >> /etc/bind/db.local.lab
Обновите Serial и перезагрузите:
sudo rndc reload
```
**Получение пароля admin на Jumphost:**
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo
```
**Вход в ArgoCD UI**
Откройте браузер:
Внутренний доступ: https://argocd.local.lab или http://192.168.100.105
Внешний доступ: https://argocd.your-domain.com
Логин: admin
Пароль: (из команды выше)

**Смена пароля admin в браузере через UI: User Info → Update Password**
Или через CLI:
```bash
# Установка ArgoCD CLI на jumphost
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x /usr/local/bin/argocd
# Логин
argocd login argocd.local.lab --username admin --password <initial-password>
# Смена пароля
argocd account update-password
```
Включите возможность генерации токенов для admin
```bash
# Получите текущий ConfigMap
kubectl get configmap argocd-cm -n argocd -o yaml

# Обновите ConfigMap
kubectl patch configmap argocd-cm -n argocd --type merge -p '{"data":{"accounts.admin":"apiKey"}}'
```
### Создание токена (срок действия 1 год)
```bash
argocd account generate-token --account admin
```
или
### Сохраните этот токен!
Перейди в Jenkins: 

Создайте учетную запись для ArgoCD доступа к Gitops repo:
- Manage Jenkins → Credentials → System → Global credentials.
- Создайте запись с ID github-gitops-token.
- Тип: Username with password
- Username: Ваш логин к github gitops репозиторий, у меня здесь sysops8
- Password: github settings -> Developer Setting -> Personal Access Token -> Classic toker -> Create -> github-argocd-token

Создайте учетную запись для Jenkins чтобы он мог вызывать синхронизацию argocd в pipeline:
- Manage Jenkins → Credentials → System → Global credentials.
- Создайте запись с ID argocd-token.
- Тип: Secret text (если токен)
- Значение: твой токен ArgoCD
- ID: argocd-token (точно как в pipeline)
- Если запись отсутствует — нужно создать её.
- После этого Jenkins сможет подставлять токен в pipeline.



## Подготовка Git репозитория

### Структура репозитория

Создайте репозиторий boardgame-gitops для манифестов:
```
boardgame-gitops/
├── base/
│   ├── kustomization.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingress.yaml
└── overlays/
    ├── dev/
    │   └── kustomization.yaml
    └── production/
        └── kustomization.yaml
```

Внутри него нужно создать файлы и каталоги:
base/kustomization.yaml
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml
  - ingress.yaml

commonLabels:
  app: boardgame
  managed-by: argocd
```
base/deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: boardgame-deployment
  namespace: production
spec:
  replicas: 2
  selector:
    matchLabels:
      app: boardgame
  template:
    metadata:
      labels:
        app: boardgame
    spec:
      containers:
        - name: boardgame
          image: harbor.local.lab/library/myapp:latest  # Будет обновляться Jenkins
          imagePullPolicy: Always
          ports:
            - containerPort: 8080
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
          readinessProbe:
            httpGet:
              path: /
              port: 8080
            initialDelaySeconds: 30
            periodSeconds: 5
      imagePullSecrets:
        - name: harbor-registry-secret
```

base/service.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: boardgame-service
  namespace: production
spec:
  type: LoadBalancer
  selector:
    app: boardgame
  ports:
    - port: 80
      targetPort: 8080
      protocol: TCP
```
base/ingress.yaml
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: boardgame-ingress
  namespace: production
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
spec:
  ingressClassName: traefik
  rules:
    - host: boardgame.local.lab
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: boardgame-service
                port:
                  number: 80
```
overlays/production/kustomization.yaml
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

bases:
  - ../../base

namespace: production

replicas:
  - name: boardgame-deployment
    count: 2
```
## Создание ArgoCD Application
Подключение Git репозитория
В ArgoCD UI:
```
Settings → Repositories → Connect Repo
Выберите метод: HTTPS
Repository URL: https://github.com/YOUR_USERNAME/boardgame-gitops.git
Username: (ваш GitHub username)
Password: (Personal Access Token)
Connect
```
## Создание Application через UI
Applications → New App
Заполните поля:
```yaml
Application Name: boardgame
Project: default
Sync Policy: Manual (пока)

Source:
  Repository URL: https://github.com/sysops8/boardgame-gitops.git
  Revision: HEAD
  Path: overlays/production

Destination:
  Cluster URL: https://kubernetes.default.svc
  Namespace: production
```
Нажать CREATE

Создание Application через YAML
Создайте файл argocd-application.yaml:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: boardgame
  namespace: argocd
spec:
  project: default
  
  source:
    repoURL: https://github.com/YOUR_USERNAME/boardgame-gitops.git
    targetRevision: HEAD
    path: overlays/production
  
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
      - CreateNamespace=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```
Применение:
```bash
kubectl apply -f argocd-application.yaml
```

## Обновление Jenkins Pipeline
Вот обновленный Jenkinsfile с добавлением gitops, файл должен лежать в корне вашего Git репозитория.
Получается теперь Jenkins делаетс стадии:
- Build
- Test
- Save to container repository
- Заходить в репозиторий Gitops -> Boardgame-GitOps ->  меняет тэг версии в файле /boardgame/kustomization.yaml
- ArgoCD проверяет свой gitops репозиторий и види что сменилась версия контейнера, далее закачивает новый контейнер разворачивает в k8s


```Jenkinsfile
pipeline {
    agent any
    environment { 
        // AppName
        MY_APP = 'boardgame'
        
        // Harbor
        HARBOR_URL = "harbor.local.lab"
        HARBOR_PROJECT = "library"
        HARBOR_CREDENTIALS = "harbor-creds"

        // Nexus
        NEXUS_URL = "http://nexus.local.lab:8081/repository/maven-releases/"
        NEXUS_CREDENTIALS = "nexus-creds"

        // SonarQube
        SONARQUBE_SERVER = "SonarQube"
        SONARQUBE_URL = "http://sonar.local.lab:9000"
        SONARQUBE_CREDENTIALS = "sonar-token"

        // Kubernetes
        KUBECONFIG_CREDENTIALS = "k8s-kubeconfig"

        // Email
        EMAIL_RECIPIENTS = "almastvx@gmail.com"

        // ArgoCD
        ARGOCD_SERVER = "argocd.local.lab"
        ARGOCD_CREDENTIALS = "argocd-token"
        GITOPS_REPO = "https://github.com/sysops8/Boardgame-gitops.git"  
        GITOPS_CREDENTIALS = "github-gitops-token"
        GITOPS_KUSTOMIZATION_PATH = "apps/boardgame/kustomization.yaml"

        // Image 
        IMAGE_NAME = "${HARBOR_URL}/${HARBOR_PROJECT}/boardgame"
        IMAGE_TAG = "${env.BUILD_NUMBER}"

        // Tools
        SCANNER_HOME = tool 'sonar-scanner'
    }

    tools {
        jdk 'java17'
        maven 'maven3.6'
    }

    stages {

        stage('Checkout') {
            steps {
                echo "Checking out source code..."
                checkout scm
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

        stage('Set Build Version') {
            steps {
                script {
                    sh "mvn versions:set -DnewVersion=0.0.${env.BUILD_NUMBER}"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    dockerImage = docker.build("${HARBOR_URL}/${HARBOR_PROJECT}/${MY_APP}:${env.BUILD_NUMBER}")
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
                        ${HARBOR_URL}/${HARBOR_PROJECT}/${MY_APP}:${env.BUILD_NUMBER}
                """
            }
        }

        stage('Push Docker Image to Harbor') {
            steps {
                script {
                    docker.withRegistry("http://${HARBOR_URL}", HARBOR_CREDENTIALS) {
                        dockerImage.push()
                        dockerImage.push('latest')
                    }
                }
            }
        }

        stage('Publish Artifacts to Nexus') {
            steps {
                echo "📤 Publishing Maven artifacts to Nexus..."
                configFileProvider([configFile(fileId: 'maven-settings', variable: 'MAVEN_SETTINGS')]) {
                    withCredentials([usernamePassword(credentialsId: NEXUS_CREDENTIALS, usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PSW')]) {
                        sh """
                            mvn clean deploy -s $MAVEN_SETTINGS \
                                -DaltDeploymentRepository=nexus::default::${NEXUS_URL} \
                                -Dnexus.username=${NEXUS_USER} \
                                -Dnexus.password=${NEXUS_PSW}
                        """
                    }
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv("${SONARQUBE_SERVER}") {
                    sh """
                        ${SCANNER_HOME}/bin/sonar-scanner \
                        -Dsonar.projectName=${MY_APP} \
                        -Dsonar.projectKey=${MY_APP} \
                        -Dsonar.host.url=${SONARQUBE_URL} \
                        -Dsonar.java.binaries=target/classes
                    """
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: false, credentialsId: "${SONARQUBE_CREDENTIALS}"
                }
            }
        }

        stage('Update GitOps Repository') {
            steps {
                script {
                    echo "🚀 Updating GitOps repository with new image version..."
                    
                    withCredentials([usernamePassword(credentialsId: GITOPS_CREDENTIALS, usernameVariable: 'GIT_USER', passwordVariable: 'GIT_TOKEN')]) {
                        sh '''
                            git clone https://$GIT_USER:$GIT_TOKEN@github.com/sysops8/Boardgame-gitops.git gitops-repo
                            cd gitops-repo

                            echo "=== Updating image version ==="
                            sed -i 's|newTag:.*|newTag: "'${BUILD_NUMBER}'"|g' ${GITOPS_KUSTOMIZATION_PATH}
                            git config user.email "jenkins@local.lab"
                            git config user.name "Jenkins CI"
                            git add ${GITOPS_KUSTOMIZATION_PATH}
                            git commit -m "Deploy ${MY_APP} version '${BUILD_NUMBER}'"
                            git push origin main
                        '''
                    }
                }
            }
        }

        stage('Sync ArgoCD Application') {
            steps {
                script {
                    echo "🔄 Synchronizing ArgoCD application..."
                    withCredentials([string(credentialsId: ARGOCD_CREDENTIALS, variable: 'ARGOCD_TOKEN')]) {
                        sh '''
                            argocd app sync $MY_APP --server ${ARGOCD_SERVER} --auth-token ${ARGOCD_TOKEN} --grpc-web --insecure
                            argocd app get "$MY_APP" --server ${ARGOCD_SERVER} --auth-token ${ARGOCD_TOKEN} --grpc-web --insecure
                        '''
                    }
                }
            }
        }

        stage('Health Check') {
            steps {
                script {
                    echo "🩺 Checking application health..."
                    withCredentials([file(credentialsId: KUBECONFIG_CREDENTIALS, variable: 'KUBECONFIG_FILE')]) {
                        sh '''
                            export KUBECONFIG=${KUBECONFIG_FILE}
                            #kubectl wait --for=condition=available --timeout=60s deployment/boardgame-deployment
                            #kubectl get pods -o wide | grep boardgame
                            # Короткое ожидание готовности
                            kubectl wait --for=condition=ready \
                            pod -l app=boardgame,managed-by=argocd \
                            -n production \
                            --timeout=60s                            
                        '''
                    }
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                withCredentials([file(credentialsId: KUBECONFIG_CREDENTIALS, variable: 'KUBECONFIG_FILE')]) {                    
                    sh """
                        echo "✅ Verifying deployment in Kubernetes..."
                        #export KUBECONFIG=${KUBECONFIG_FILE}
                        #kubectl rollout status deployment/boardgame-deployment    
                        echo "Checking pods..."
                        kubectl get pods -n production -l app=boardgame -o wide
                        
                        echo "Checking deployment rollout status..."
                        kubectl rollout status deployment/boardgame-deployment -n production --timeout=300s
                        
                        echo "Checking services..."
                        kubectl get svc -n production -l app=boardgame
                        
                        echo "Checking replica status..."
                        kubectl get deployment boardgame-deployment -n production -o jsonpath='{.status.availableReplicas}/{.status.replicas} pods available'
                        echo ""
                    """
                }
            }
        }
    }

    post {
        success {
            script {
                def appUrl = "http://boardgame.local.lab"
                def argocdUrl = "https://${ARGOCD_SERVER}/applications/boardgame"
                
                echo "🎉 Pipeline completed successfully!"
                echo "📧 Sending success notification..."
                
                emailext(
                    subject: "✅ SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
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
                                    <td style="padding: 8px; border: 1px solid #ddd;"><strong>Build:</strong></td>
                                    <td style="padding: 8px; border: 1px solid #ddd;">#${env.BUILD_NUMBER}</td>
                                </tr>
                                <tr>
                                    <td style="padding: 8px; border: 1px solid #ddd;"><strong>Docker Image:</strong></td>
                                    <td style="padding: 8px; border: 1px solid #ddd;">${IMAGE_NAME}:${IMAGE_TAG}</td>
                                </tr>
                                <tr>
                                    <td style="padding: 8px; border: 1px solid #ddd;"><strong>Application:</strong></td>
                                    <td style="padding: 8px; border: 1px solid #ddd;">
                                        <a href="${appUrl}">${appUrl}</a>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="padding: 8px; border: 1px solid #ddd;"><strong>ArgoCD:</strong></td>
                                    <td style="padding: 8px; border: 1px solid #ddd;">
                                        <a href="${argocdUrl}">${argocdUrl}</a>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="padding: 8px; border: 1px solid #ddd;"><strong>Build URL:</strong></td>
                                    <td style="padding: 8px; border: 1px solid #ddd;">
                                        <a href="${env.BUILD_URL}">${env.BUILD_URL}</a>
                                    </td>
                                </tr>
                            </table>
                            <p style="margin-top: 20px;">
                                <strong>Deployed by ArgoCD via GitOps</strong><br>
                                GitOps Repo: ${GITOPS_REPO}
                            </p>
                        </body>
                        </html>
                    """,
                    to: EMAIL_RECIPIENTS,
                    mimeType: 'text/html',
                    attachmentsPattern: 'trivy-report.txt'
                )
            }
        }
        failure {
                    echo "❌ Pipeline failed!"
                    emailext(
                    subject: "❌ FAILURE: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                    body: """
                        <html>
                        <body style="font-family: Arial, sans-serif;">
                            <h2 style="color: #dc3545;">❌ Pipeline Failed!</h2>
                            <table style="border-collapse: collapse; width: 100%;">
                                <tr>
                                    <td style="padding: 8px; border: 1px solid #ddd;"><strong>Job:</strong></td>
                                    <td style="padding: 8px; border: 1px solid #ddd;">${env.JOB_NAME}</td>
                                </tr>
                                <tr>
                                    <td style="padding: 8px; border: 1px solid #ddd;"><strong>Build:</strong></td>
                                    <td style="padding: 8px; border: 1px solid #ddd;">#${env.BUILD_NUMBER}</td>
                                </tr>
                                <tr>
                                    <td style="padding: 8px; border: 1px solid #ddd;"><strong>Failed Stage:</strong></td>
                                    <td style="padding: 8px; border: 1px solid #ddd;">${env.STAGE_NAME}</td>
                                </tr>
                                <tr>
                                    <td style="padding: 8px; border: 1px solid #ddd;"><strong>Console:</strong></td>
                                    <td style="padding: 8px; border: 1px solid #ddd;">
                                        <a href="${env.BUILD_URL}console">${env.BUILD_URL}console</a>
                                    </td>
                                </tr>
                            </table>
                        </body>
                        </html>
                    """,
                    to: EMAIL_RECIPIENTS,
                    mimeType: 'text/html'
                    )
        }
        unstable {
            mail to: "${EMAIL_RECIPIENTS}",
                subject: "⚠️ UNSTABLE: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                body: "The Jenkins job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' is unstable.\nBuild URL: ${env.BUILD_URL}"
        }
        always {
            archiveArtifacts artifacts: 'trivy-*-report.html', allowEmptyArchive: true
            cleanWs()
        }
    }
}
```


---
## Часть 6: Дополнительные настройки

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
- [ ] Интеграция с Slack для уведомлений
- [ ] Добавить EFK (Elasticsearch, Fluentd, Kibana) stack
- [ ] Настроить Vault для secrets
- [ ] Добавить Istio service mesh
- [ ] Создать Ansible playbooks для автоматизации
- [ ] Добавить Terraform modules
- [ ] Интеграция с Jira

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

---

*Последнее обновление: 2025*

*Версия: 1.0.0*
                
