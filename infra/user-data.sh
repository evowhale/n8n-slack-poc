#!/bin/bash
set -euxo pipefail

# --- 기본 패키지 ---
apt-get update
apt-get upgrade -y
apt-get install -y git curl unzip jq

# --- 타임존 ---
timedatectl set-timezone Asia/Seoul

# --- Docker ---
curl -fsSL https://get.docker.com | sh
usermod -aG docker ubuntu

# --- Docker Compose로 n8n 준비 ---
mkdir -p /home/ubuntu/n8n
cat > /home/ubuntu/n8n/docker-compose.yml << 'COMPOSE'
version: '3.8'
services:
  n8n:
    image: docker.n8n.io/n8nio/n8n
    restart: always
    ports:
      - "5678:5678"
    environment:
      - WEBHOOK_URL=${WEBHOOK_URL:-http://localhost:5678/}
      - N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}
      - GENERIC_TIMEZONE=Asia/Seoul
      - TZ=Asia/Seoul
      - N8N_SECURE_COOKIE=false
    volumes:
      - n8n_data:/home/node/.n8n
    extra_hosts:
      - "host.docker.internal:host-gateway"
volumes:
  n8n_data:
COMPOSE

cat > /home/ubuntu/n8n/.env << ENV
N8N_ENCRYPTION_KEY=$(openssl rand -hex 32)
WEBHOOK_URL=http://localhost:5678/
ENV

chown -R ubuntu:ubuntu /home/ubuntu/n8n

# --- Node.js (nvm) ---
su - ubuntu -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash'
su - ubuntu -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && nvm install --lts'

# --- Claude Code ---
su - ubuntu -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && npm install -g @anthropic-ai/claude-code'

# --- 코드베이스 클론 ---
su - ubuntu -c 'mkdir -p ~/clap && cd ~/clap && git clone https://github.com/evowhale/n8n-slack-poc.git'
su - ubuntu -c 'chmod +x ~/clap/n8n-slack-poc/scripts/claude-slack-runner.sh'

# --- SSH 비밀번호 인증 활성화 (n8n Docker → Host 통신용) ---
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#\?KbdInteractiveAuthentication.*/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd

# --- 완료 마커 ---
echo "$(date): user-data setup complete" > /home/ubuntu/setup-complete.txt
chown ubuntu:ubuntu /home/ubuntu/setup-complete.txt
