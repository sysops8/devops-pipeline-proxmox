# The Ultimate CI/CD Corporate DevOps Pipeline Project

> Полное руководство по развертыванию enterprise-grade CI/CD инфраструктуры в Proxmox

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
- [Детальная установка](#детальная-установка)
  - [Этап 1: Сетевая инфраструктура](#этап-1-подготовка-сетевой-инфраструктуры)
  - [Этап 2: Создание VM через Terraform](#этап-2-план-виртуальных-машин)
  - [Этап 3: Установка K3s кластера](#этап-3-установка-k3s-кластера)
  - [Этап 4: MetalLB Load Balancer](#этап-4-установка-metallb-load-balancer)
  - [Этап 5: Traefik Ingress](#этап-5-установка-traefik-ingress)
  - [Этап 6: Cloudflare Tunnel](#этап-6-настройка-внешнего-доступа-через-cloudflare-tunnel)
  - [Этап 7: Установка инструментов](#этап-7-установка-инструментов-на-vm)
  - [Этап 8: Настройка Jenkins](#этап-8-настройка-jenkins-pipeline)
  - [Этап 9: Jenkins Pipeline](#этап-9-создание-jenkins-pipeline)
  - [Этап 10: Мониторинг Jenkins](#этап-10-установка-мониторинга-на-jenkins)
  - [Этап 11: Безопасность K8s](#этап-11-настройка-безопасности-k8s)
  - [Этап 12: Запуск Pipeline](#этап-12-запуск-pipeline)
  - [Этап 13: Проверка результатов](#этап-13-проверка-результатов)
  - [Этап 14: Оптимизация](#этап-14-оптимизация-и-best-practices)
  - [Этап 15: Troubleshooting](#этап-15-troubleshooting)
  - [Этап 16: Финальная проверка](#этап-16-финальная-проверка)
- [Использование](#использование)
- [Мониторинг](#мониторинг)
- [Backup и Recovery](#backup-и-recovery)
- [FAQ](#faq)
- [Contributing](#contributing)
- [Лицензия](#лицензия)

---

## 🎯 О проекте

Это руководство представляет собой полную реализацию корпоративного CI/CD pipeline на базе **Proxmox** вместо AWS. Проект создан для закрепления навыков DevOps и демонстрации в портфолио/резюме.

### Что вы получите

- ✅ Полностью автоматизированный CI/CD pipeline
- ✅ Kubernetes кластер (K3s) с 3 нодами
- ✅ Безопасный внешний доступ через Cloudflare Tunnel
- ✅ Полный стек мониторинга (Prometheus + Grafana)
- ✅ Приватный container registry (Harbor)
- ✅ Анализ качества кода (SonarQube)
- ✅ Управление артефактами (Nexus)
- ✅ Сканирование безопасности (Trivy)
- ✅ Infrastructure as Code (Terraform)

### Отличия от оригинального проекта

| AWS | Proxmox альтернатива |
|-----|----------------------|
| VPC | Proxmox Bridge (vmbr1) |
| EC2 | Proxmox VM |
| EKS | K3s cluster |
| ELB | MetalLB + Traefik |
| Route53 | Cloudflare Tunnel |
| DockerHub Private | Harbor Registry |

---

## 🏗️ Архитектура

```
Internet
    ↓
Cloudflare Tunnel (Proxmox хост)
    ↓
┌─────────────────────────────────────────────────────┐
│         Proxmox Network (vmbr1)                     │
│         192.168.100.0/24                            │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌──────────────┐  ┌──────────────┐               │
│  │   Jenkins    │  │  SonarQube   │               │
│  │ 192.168.100  │  │ 192.168.100  │               │
│  │    .20:8080  │  │    .30:9000  │               │
│  └──────────────┘  └──────────────┘               │
│                                                     │
│  ┌──────────────┐  ┌──────────────┐               │
│  │   Nexus      │  │   Harbor     │               │
│  │ 192.168.100  │  │ 192.168.100  │               │
│  │    .31:8081  │  │    .32:443   │               │
│  └──────────────┘  └──────────────┘               │
│                                                     │
│  ┌─────────────────────────────────────┐          │
│  │      Monitoring (192.168.100.40)    │          │
│  │  Prometheus:9090  Grafana:3000      │          │
│  └─────────────────────────────────────┘          │
│                                                     │
│  ┌─────────────────────────────────────┐          │
│  │      K3s Cluster                     │          │
│  │                                       │          │
│  │  ┌─ Master (192.168.100.10)         │          │
│  │  ├─ Worker1 (192.168.100.11)        │          │
│  │  └─ Worker2 (192.168.100.12)        │          │
│  │                                       │          │
│  │  MetalLB Pool: 192.168.100.100-150  │          │
│  │  Traefik Ingress Controller         │          │
│  │  Application Pods (Boardgame)       │          │
│  └─────────────────────────────────────┘          │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### Pipeline Flow

```mermaid
graph LR
    A[Git Push] --> B[Jenkins Webhook]
    B --> C[Git Checkout]
    C --> D[Compile Maven]
    D --> E[Unit Tests]
    E --> F[SonarQube Analysis]
    F --> G[Quality Gate]
    G --> H[Trivy FS Scan]
    H --> I[Build JAR]
    I --> J[Publish to Nexus]
    J --> K[Build Docker Image]
    K --> L[Trivy Image Scan]
    L --> M[Push to Harbor]
    M --> N[Deploy to K8s]
    N --> O[Verify Deployment]
    O --> P[Email Notification]
```

---

## 💻 Требования

### Аппаратные требования

**Proxmox хост:**
- CPU: 12+ cores (Ryzen 3900 или аналог)
- RAM: 64GB
- Storage: 2TB HDD + 2TB SSD
- Network: 1Gbps

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
- Helm >= 3.12.0
- SSH client

### Сетевые требования

- Внутренняя сеть: `10.0.10.0/24` (существующая)
- Изолированная сеть: `192.168.100.0/24` (будет создана)
- Интернет доступ с серым IP
- Cloudflare аккаунт (бесплатный)

### Необходимые аккаунты

- GitHub (для репозитория)
- Cloudflare (для туннеля)
- Gmail (для email уведомлений)

---

## 🚀 Быстрый старт

```bash
# 1. Клонируйте репозиторий
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

# 4. Настройте K3s (на master node)
ssh ubuntu@192.168.100.10
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik" sh -

# 5. Установите все компоненты
./scripts/install-all.sh

# 6. Запустите Jenkins pipeline
# Jenkins → New Item → boardgame-pipeline → Build Now
```

**⏱️ Общее время установки: ~2-3 часа**

---

## 📚 Детальная установка

## Этап 1: Подготовка сетевой инфраструктуры

### 1.1 Создание изолированной сети в Proxmox

Подключитесь к Proxmox хосту:

```bash
ssh root@10.0.10.200
```

Создайте новый bridge для изолированной сети:

```bash
cat >> /etc/network/interfaces <<EOF

# DevOps Project Network
auto vmbr1
iface vmbr1 inet static
    address 192.168.100.1/24
    bridge-ports none
    bridge-stp off
    bridge-fd 0
    post-up iptables -t nat -A POSTROUTING -s 192.168.100.0/24 -o vmbr0 -j MASQUERADE
    post-down iptables -t nat -D POSTROUTING -s 192.168.100.0/24 -o vmbr0 -j MASQUERADE
EOF
```

Примените изменения:

```bash
ifreload -a
```

Включите IP forwarding:

```bash
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p
```

Проверьте созданный bridge:

```bash
ip addr show vmbr1
# Должно показать: 192.168.100.1/24
```

---

## Этап 2: План виртуальных машин

### 2.1 Спецификация VM

| Имя VM | CPU | RAM | Disk | IP | Назначение |
|--------|-----|-----|------|-----|-----------|
| k3s-master | 4 | 8GB | 50GB | 192.168.100.10 | K3s Control Plane |
| k3s-worker1 | 4 | 8GB | 50GB | 192.168.100.11 | K3s Worker Node |
| k3s-worker2 | 4 | 8GB | 50GB | 192.168.100.12 | K3s Worker Node |
| jenkins | 4 | 8GB | 60GB | 192.168.100.20 | Jenkins CI/CD |
| sonarqube | 2 | 4GB | 30GB | 192.168.100.30 | Code Quality |
| nexus | 2 | 4GB | 40GB | 192.168.100.31 | Artifact Repository |
| harbor | 2 | 4GB | 50GB | 192.168.100.32 | Container Registry |
| monitoring | 4 | 6GB | 40GB | 192.168.100.40 | Prometheus+Grafana |
| jumphost | 4 | 2GB | 10GB | 192.168.100.5 | Jumphost |

**Итого:** 24 vCPU, 46GB RAM, 360GB Storage

### 2.2 Создание Ubuntu Cloud-Init Template

На Proxmox хосте:

```bash
cd /var/lib/vz/template/iso/

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
```

### 2.3 Terraform конфигурация

Создайте директорию для Terraform:

```bash
mkdir -p ~/devops-pipeline-proxmox/terraform
cd ~/devops-pipeline-proxmox/terraform
```

Создайте файл `providers.tf`:

```hcl
terraform {
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
```

Создайте файл `variables.tf`:

```hcl
variable "proxmox_api_url" {
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
```

Создайте файл `main.tf`:

```hcl
# K3s Master Node
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
  
  ipconfig0  = "ip=192.168.100.10/24,gw=192.168.100.1"
  nameserver = "8.8.8.8"
  ciuser     = "ubuntu"
  sshkeys    = var.ssh_public_key
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
  
  ipconfig0  = "ip=192.168.100.${11 + count.index}/24,gw=192.168.100.1"
  nameserver = "8.8.8.8"
  ciuser     = "ubuntu"
  sshkeys    = var.ssh_public_key
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
  
  ipconfig0  = "ip=192.168.100.20/24,gw=192.168.100.1"
  nameserver = "8.8.8.8"
  ciuser     = "ubuntu"
  sshkeys    = var.ssh_public_key
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
  
  ipconfig0  = "ip=192.168.100.30/24,gw=192.168.100.1"
  nameserver = "8.8.8.8"
  ciuser     = "ubuntu"
  sshkeys    = var.ssh_public_key
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
  
  ipconfig0  = "ip=192.168.100.31/24,gw=192.168.100.1"
  nameserver = "8.8.8.8"
  ciuser     = "ubuntu"
  sshkeys    = var.ssh_public_key
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
  
  ipconfig0  = "ip=192.168.100.32/24,gw=192.168.100.1"
  nameserver = "8.8.8.8"
  ciuser     = "ubuntu"
  sshkeys    = var.ssh_public_key
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
  
  ipconfig0  = "ip=192.168.100.40/24,gw=192.168.100.1"
  nameserver = "8.8.8.8"
  ciuser     = "ubuntu"
  sshkeys    = var.ssh_public_key
}
```

Создайте файл `outputs.tf`:

```hcl
output "k3s_master_ip" {
  value = proxmox_vm_qemu.k3s_master.default_ipv4_address
}

output "k3s_workers_ips" {
  value = proxmox_vm_qemu.k3s_workers[*].default_ipv4_address
}

output "jenkins_ip" {
  value = proxmox_vm_qemu.jenkins.default_ipv4_address
}

output "sonarqube_ip" {
  value = proxmox_vm_qemu.sonarqube.default_ipv4_address
}

output "nexus_ip" {
  value = proxmox_vm_qemu.nexus.default_ipv4_address
}

output "harbor_ip" {
  value = proxmox_vm_qemu.harbor.default_ipv4_address
}

output "monitoring_ip" {
  value = proxmox_vm_qemu.monitoring.default_ipv4_address
}
```

Создайте файл `terraform.tfvars`:

```hcl
proxmox_api_url  = "https://10.0.10.200:8006/api2/json"
proxmox_user     = "root@pam"
proxmox_password = "YOUR_PROXMOX_PASSWORD"
ssh_public_key   = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAA... your-key-here"
target_node      = "pve"
```

### 2.4 Развертывание VM

```bash
# Инициализация Terraform
terraform init

# Проверка плана
terraform plan

# Применение конфигурации
terraform apply

# Подтвердите: yes
```

**⏱️ Время выполнения: ~10 минут**

Проверьте созданные VM:

```bash
terraform output
```

---

## Этап 3: Установка K3s кластера

### 3.1 Установка K3s Master Node

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

### 3.2 Подключение Worker Nodes

**На k3s-worker1:**

```bash
ssh ubuntu@192.168.100.11

curl -sfL https://get.k3s.io | K3S_URL=https://192.168.100.10:6443 \
  K3S_TOKEN="YOUR_TOKEN_FROM_MASTER" \
  sh -
```

**На k3s-worker2:**

```bash
ssh ubuntu@192.168.100.12

curl -sfL https://get.k3s.io | K3S_URL=https://192.168.100.10:6443 \
  K3S_TOKEN="YOUR_TOKEN_FROM_MASTER" \
  sh -
```

### 3.3 Проверка кластера

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

### 3.4 Настройка kubectl на локальной машине

На вашей Windows машине (WSL/Git Bash):

```bash
# Создайте директорию для kubeconfig
mkdir -p ~/.kube

# Скопируйте kubeconfig с master node
scp ubuntu@192.168.100.10:/etc/rancher/k3s/k3s.yaml ~/.kube/config

# Измените server URL
sed -i 's/127.0.0.1/192.168.100.10/' ~/.kube/config

# Проверка
kubectl get nodes
```

---

## Этап 4: Установка MetalLB (Load Balancer)

### 4.1 Установка MetalLB

```bash
# Применяем манифест
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml

# Ждем готовности
kubectl wait --namespace metallb-system \
  --for=condition=ready pod \
  --selector=app=metallb \
  --timeout=90s
```

### 4.2 Конфигурация IP Pool

Создайте файл `metallb-config.yaml`:

```yaml
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

## Этап 5: Установка Traefik Ingress

### 5.1 Установка Helm

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### 5.2 Установка Traefik

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

### 5.3 Проверка

```bash
kubectl get svc -n traefik

# Вы должны увидеть EXTERNAL-IP из диапазона MetalLB (например, 192.168.100.100)
```

---

## Этап 6: Настройка внешнего доступа через Cloudflare Tunnel

### 6.1 Установка cloudflared на Proxmox хосте

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

### 6.2 Конфигурация туннеля

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

### 6.3 Создание DNS записей

```bash
# Для каждого hostname создайте CNAME запись
cloudflared tunnel route dns devops-pipeline jenkins.your-domain.com
cloudflared tunnel route dns devops-pipeline sonar.your-domain.com
cloudflared tunnel route dns devops-pipeline nexus.your-domain.com
cloudflared tunnel route dns devops-pipeline harbor.your-domain.com
cloudflared tunnel route dns devops-pipeline grafana.your-domain.com
cloudflared tunnel route dns devops-pipeline "*.apps.your-domain.com"
```

### 6.4 Запуск туннеля как systemd сервиса

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

## Этап 7: Установка инструментов на VM

### 7.1 Jenkins Server (192.168.100.20)

```bash
ssh ubuntu@192.168.100.20

# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu
sudo usermod -aG docker jenkins

# Установка Java 17
sudo apt install -y openjdk-17-jdk

# Установка Jenkins
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt update
sudo apt install -y jenkins

# Запуск Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Получение initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

**Установка kubectl:**

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Копирование kubeconfig для Jenkins
sudo mkdir -p /var/lib/jenkins/.kube
sudo scp ubuntu@192.168.100.10:/home/ubuntu/.kube/config /var/lib/jenkins/.kube/config
sudo chown jenkins:jenkins /var/lib/jenkins/.kube/config
```

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

**Доступ:** `https://jenkins.your-domain.com`

### 7.2 SonarQube Server (192.168.100.30)

```bash
ssh ubuntu@192.168.100.30

# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu

# Настройка системы для SonarQube
sudo sysctl -w vm.max_map_count=524288
sudo sysctl -w fs.file-max=131072
echo "vm.max_map_count=524288" | sudo tee -a /etc/sysctl.conf
echo "fs.file-max=131072" | sudo tee -a /etc/sysctl.conf

# Запуск SonarQube
docker run -d \
  --name sonarqube \
  --restart=unless-stopped \
  -p 9000:9000 \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  -v sonarqube_data:/opt/sonarqube/data \
  -v sonarqube_extensions:/opt/sonarqube/extensions \
  -v sonarqube_logs:/opt/sonarqube/logs \
  sonarqube:lts-community
```

**Проверка:**

```bash
docker ps
docker logs -f sonarqube
```

**Доступ:** `https://sonar.your-domain.com`  
**Логин:** admin/admin (измените после первого входа)

### 7.3 Nexus Repository (192.168.100.31)

```bash
ssh ubuntu@192.168.100.31

# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Запуск Nexus
docker run -d \
  --name nexus \
  --restart=unless-stopped \
  -p 8081:8081 \
  -v nexus-data:/nexus-data \
  sonatype/nexus3

# Ожидание запуска (~2 минуты)
sleep 120

# Получение initial admin password
docker exec nexus cat /nexus-data/admin.password
```

**Доступ:** `https://nexus.your-domain.com`  
**Логин:** admin + пароль из команды выше

**Создание репозиториев:**
1. Sign in
2. Server administration (шестеренка) → Repositories → Create repository
3. Создайте: `maven-releases` (maven2 hosted)
4. Создайте: `maven-snapshots` (maven2 hosted)

### 7.4 Harbor Registry (192.168.100.32)

```bash
ssh ubuntu@192.168.100.32

# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка Docker и Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo apt install -y docker-compose

# Скачивание Harbor
cd ~
wget https://github.com/goharbor/harbor/releases/download/v2.9.0/harbor-offline-installer-v2.9.0.tgz
tar xzvf harbor-offline-installer-v2.9.0.tgz
cd harbor

# Конфигурация
cp harbor.yml.tmpl harbor.yml
```

Отредактируйте `harbor.yml`:

```bash
nano harbor.yml
```

Измените:

```yaml
hostname: harbor.your-domain.com

# Закомментируйте HTTPS для начала (настроим через Cloudflare)
# https:
#   port: 443
#   certificate: /your/certificate/path
#   private_key: /your/private/key/path

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
docker-compose ps
```

**Доступ:** `https://harbor.your-domain.com`  
**Логин:** admin/YourSecurePassword123!

**Настройка проекта:**
1. Projects → NEW PROJECT
2. Project Name: `library`
3. Access Level: Public
4. OK

### 7.5 Monitoring Server (192.168.100.40)

```bash
ssh ubuntu@192.168.100.40

# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка Docker и Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo apt install -y docker-compose

# Создание структуры директорий
mkdir -p ~/monitoring/{prometheus,grafana}
cd ~/monitoring
```

**Создайте `docker-compose.yml`:**

```yaml
version: '3.8'

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
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($|/)'
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
```

**Создайте `prometheus/prometheus.yml`:**

```yaml
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
        bearer_token_file: /etc/prometheus/k3s-token
    scheme: https
    tls_config:
      insecure_skip_verify: true
    bearer_token_file: /etc/prometheus/k3s-token
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
        bearer_token_file: /etc/prometheus/k3s-token
    scheme: https
    tls_config:
      insecure_skip_verify: true
    bearer_token_file: /etc/prometheus/k3s-token

  # Kubernetes Pods
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
        api_server: https://192.168.100.10:6443
        tls_config:
          insecure_skip_verify: true
        bearer_token_file: /etc/prometheus/k3s-token
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
        replacement: $1:$2
        target_label: __address__
```

**Создайте `prometheus/alerts.yml`:**

```yaml
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
          description: "Memory usage is {{ $value | humanize }}%"

      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
          description: "CPU usage is {{ $value | humanize }}%"

      - alert: DiskSpaceLow
        expr: (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100 < 15
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Low disk space on {{ $labels.instance }}"
          description: "Disk space is {{ $value | humanize }}%"

      - alert: PodCrashLooping
        expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Pod {{ $labels.pod }} is crash looping"
          description: "Pod is restarting frequently in namespace {{ $labels.namespace }}"
```

**Создайте `blackbox/blackbox.yml`:**

```yaml
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
```

**Получение K3s token для Prometheus:**

```bash
# На k3s-master
ssh ubuntu@192.168.100.10
kubectl -n kube-system get secret $(kubectl -n kube-system get sa default -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.token}' | base64 -d

# Скопируйте токен
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
- Prometheus: `https://grafana.your-domain.com` (будет через Grafana)
- Grafana: `https://grafana.your-domain.com` (admin/admin)

---

## Этап 8: Настройка Jenkins Pipeline

### 8.1 Первоначальная настройка Jenkins

Откройте `https://jenkins.your-domain.com`

1. Введите initial admin password (из команды ранее)
2. Install suggested plugins
3. Create First Admin User
4. Save and Continue

### 8.2 Установка плагинов

**Manage Jenkins → Manage Plugins → Available**

Установите следующие плагины:

- Docker Pipeline
- Kubernetes CLI
- SonarQube Scanner
- Config File Provider
- Maven Integration
- Pipeline Maven Integration
- Prometheus metrics
- Email Extension Plugin
- Blue Ocean (опционально, для красивого UI)

После установки: **Restart Jenkins**

### 8.3 Настройка Tools

**Manage Jenkins → Global Tool Configuration**

**JDK:**
- Name: `jdk-17`
- ✓ Install automatically
- Version: OpenJDK 17

**Maven:**
- Name: `maven-3`
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

### 8.4 Настройка Credentials

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
SonarQube → Administration → Security → Users → Administrator → Tokens → Generate
```

**4. Kubernetes Config:**
- Kind: Secret file
- File: Upload `~/.kube/config`
- ID: `k8s-kubeconfig`
- Description: Kubernetes Config

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

### 8.5 Настройка SonarQube Server

**Manage Jenkins → Configure System → SonarQube servers**

- ✓ Enable injection of SonarQube server configuration
- Name: `sonar`
- Server URL: `http://192.168.100.30:9000`
- Server authentication token: Select `sonar-token`

### 8.6 Настройка Maven Settings

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
      <id>maven-releases</id>
      <username>admin</username>
      <password>YOUR_NEXUS_PASSWORD</password>
    </server>
    <server>
      <id>maven-snapshots</id>
      <username>admin</username>
      <password>YOUR_NEXUS_PASSWORD</password>
    </server>
  </servers>
</settings>
```

Submit

### 8.7 Настройка Email

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

## Этап 9: Создание Jenkins Pipeline

### 9.1 Подготовка репозитория

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
  namespace: default
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
        image: harbor.your-domain.com/library/boardgame:latest
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
  namespace: default
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
  namespace: default
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: traefik
  rules:
  - host: boardgame.apps.your-domain.com
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
    - boardgame.apps.your-domain.com
    secretName: boardgame-tls
```

### 9.3 Обновление pom.xml

Добавьте в `pom.xml` секцию `distributionManagement`:

```xml
<distributionManagement>
    <repository>
        <id>maven-releases</id>
        <name>Maven Releases Repository</name>
        <url>http://192.168.100.31:8081/repository/maven-releases/</url>
    </repository>
    <snapshotRepository>
        <id>maven-snapshots</id>
        <name>Maven Snapshots Repository</name>
        <url>http://192.168.100.31:8081/repository/maven-snapshots/</url>
    </snapshotRepository>
</distributionManagement>
```

### 9.4 Создание Jenkinsfile

Создайте файл `Jenkinsfile`:

```groovy
pipeline {
    agent any
    
    tools {
        jdk 'jdk-17'
        maven 'maven-3'
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

### 9.5 Коммит и пуш изменений

```bash
git add .
git commit -m "Add CI/CD pipeline configuration"
git push origin main
```

---

## Этап 10: Установка мониторинга на Jenkins

### 10.1 Установка Node Exporter на Jenkins

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

### 10.2 Настройка Jenkins Prometheus Plugin

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

### 10.3 Настройка Grafana дашбордов

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

## Этап 11: Настройка безопасности K8s

### 11.1 Установка Kubeaudit

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

### 11.2 Создание RBAC для Jenkins

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

### 11.3 Создание kubeconfig для Jenkins

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

### 11.4 Network Policies (опционально)

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

## Этап 12: Запуск Pipeline

### 12.1 Создание Pipeline Job в Jenkins

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

### 12.2 Настройка GitHub Webhook (опционально)

В вашем GitHub репозитории:

1. Settings → Webhooks → Add webhook
2. Payload URL: `https://jenkins.your-domain.com/github-webhook/`
3. Content type: `application/json`
4. Which events: **Just the push event**
5. ✓ Active
6. Add webhook

### 12.3 Первый запуск Pipeline

В Jenkins:

1. Откройте `boardgame-pipeline`
2. **Build Now**
3. Смотрите прогресс в Console Output

**⏱️ Ожидаемое время: 10-15 минут**

### 12.4 Мониторинг выполнения

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

---

## Этап 13: Проверка результатов

### 13.1 Проверка Kubernetes Deployment

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

### 13.2 Доступ к приложению

**Через Ingress (рекомендуется):**
```
https://boardgame.apps.your-domain.com
```

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

### 13.3 Тестирование приложения

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

### 13.4 Проверка артефактов

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

### 13.6 Проверка Email уведомлений

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

## Этап 14: Оптимизация и Best Practices

### 14.1 Horizontal Pod Autoscaler (HPA)

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

### 14.2 Persistent Volumes для данных

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

### 14.3 ConfigMap для конфигурации

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

### 14.4 Resource Quotas для namespace

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

### 14.5 Pod Disruption Budget

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

## Этап 15: Troubleshooting

### 15.1 Распространенные проблемы и решения

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
ssh ubuntu@192.168.100.10 "sudo k3s etcd-snapshot save --name backup-${DATE}"
scp ubuntu@192.168.100.10:/var/lib/rancher/k3s/server/db/snapshots/* ${BACKUP_DIR}/k3s-snapshots/

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

**Автор:** Ваше Имя  
**Email:** your.email@example.com  
**GitHub:** [@yourusername](https://github.com/yourusername)  
**LinkedIn:** [Your LinkedIn](https://linkedin.com/in/yourprofile)

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

**⭐ Если этот проект помог вам, поставьте звезду на GitHub!**

**🚀 Удачи с вашим DevOps путешествием!**

---

*Последнее обновление: 2024*

*Версия: 1.0.0*
                
