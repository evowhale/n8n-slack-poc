#!/bin/bash
# =============================================================================
# user-data.sh — EC2 초기화 스크립트
# =============================================================================
# EC2 인스턴스가 처음 부팅될 때 자동으로 실행되는 스크립트입니다.
# main.tf의 user_data 속성에서 이 파일을 참조하여 EC2에 전달합니다.
#
# 이 스크립트가 하는 일:
#   1. 기본 패키지 설치 (git, curl 등)
#   2. 타임존을 서울로 설정
#   3. Docker 설치
#   4. n8n을 Docker Compose로 구성
#   5. Node.js 설치 (nvm 사용)
#   6. Claude Code CLI 설치
#   7. 프로젝트 소스코드 클론
#   8. SSH 비밀번호 인증 활성화
#
# 주의: 이 스크립트는 root 권한으로 실행됩니다.
# 실행 로그 확인: sudo cat /var/log/cloud-init-output.log
# =============================================================================

# set 옵션 설명:
#   -e: 명령이 하나라도 실패하면 스크립트 즉시 중단
#   -u: 정의되지 않은 변수를 사용하면 에러 발생
#   -x: 실행되는 모든 명령을 로그에 출력 (디버깅용)
#   -o pipefail: 파이프(|) 중간에 실패해도 에러로 처리
set -euxo pipefail

# =========================
# 1. 기본 패키지 설치
# =========================
apt-get update                          # 패키지 목록 최신화
apt-get upgrade -y                      # 설치된 패키지 전체 업그레이드 (-y: 자동 yes)
apt-get install -y git curl unzip jq    # 필요한 유틸리티 설치
                                        #   git: 소스코드 클론용
                                        #   curl: URL에서 파일 다운로드용
                                        #   unzip: 압축 해제용
                                        #   jq: JSON 파싱 도구 (스크립트에서 JSON 처리용)

# =========================
# 2. 타임존 설정
# =========================
timedatectl set-timezone Asia/Seoul     # 서버 시간을 한국 시간(KST)으로 설정

# =========================
# 3. Docker 설치
# =========================
curl -fsSL https://get.docker.com | sh  # Docker 공식 설치 스크립트 다운로드 후 실행
                                        #   -f: HTTP 에러 시 실패 처리
                                        #   -s: 진행 상황 숨김 (silent)
                                        #   -S: 에러 시에는 메시지 표시
                                        #   -L: 리다이렉트 따라감
usermod -aG docker ubuntu               # ubuntu 사용자를 docker 그룹에 추가
                                        # → sudo 없이도 docker 명령 사용 가능

# =========================
# 4. Docker Compose로 n8n 구성
# =========================
# n8n을 Docker 컨테이너로 실행하기 위한 설정 파일을 생성합니다.

mkdir -p /home/ubuntu/n8n               # n8n 설정 파일을 저장할 디렉토리 생성

# docker-compose.yml 파일 생성
# 'COMPOSE'로 감싸면 변수 치환 없이 그대로 파일에 씀 (heredoc 문법)
cat > /home/ubuntu/n8n/docker-compose.yml << 'COMPOSE'
version: '3.8'                          # Docker Compose 파일 형식 버전
services:
  n8n:
    image: docker.n8n.io/n8nio/n8n      # n8n 공식 Docker 이미지
    restart: always                     # 컨테이너가 죽으면 자동 재시작
    ports:
      - "5678:5678"                     # 호스트의 5678 포트 → 컨테이너의 5678 포트로 매핑
    environment:                        # 환경변수 설정
      - WEBHOOK_URL=${WEBHOOK_URL:-http://localhost:5678/}  # webhook URL (기본값: localhost)
      - N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}            # 인증 정보 암호화 키
      - GENERIC_TIMEZONE=Asia/Seoul     # n8n 내부 타임존
      - TZ=Asia/Seoul                   # 컨테이너 시스템 타임존
      - N8N_SECURE_COOKIE=false         # HTTP 환경에서 쿠키 사용 허용 (HTTPS 아닐 때 필요)
    volumes:
      - n8n_data:/home/node/.n8n        # n8n 데이터를 Docker 볼륨에 영구 저장
                                        # 컨테이너를 재시작해도 워크플로우/인증 정보가 유지됨
    extra_hosts:
      - "host.docker.internal:host-gateway"  # 컨테이너에서 호스트 머신에 접근 가능하게 설정
                                              # n8n에서 같은 서버의 다른 서비스 호출 시 필요
volumes:
  n8n_data:                             # Docker 볼륨 정의 (데이터 영구 저장용)
COMPOSE

# .env 파일 생성 (docker-compose에서 참조하는 환경변수)
cat > /home/ubuntu/n8n/.env << ENV
N8N_ENCRYPTION_KEY=$(openssl rand -hex 32)  # 랜덤 64자 16진수 문자열 생성 (암호화 키)
WEBHOOK_URL=http://localhost:5678/          # webhook 기본 URL
ENV

chown -R ubuntu:ubuntu /home/ubuntu/n8n     # 파일 소유자를 ubuntu 사용자로 변경
                                            # (이 스크립트는 root로 실행되므로 권한 변경 필요)

# =========================
# 5. Node.js 설치 (nvm 사용)
# =========================
# nvm = Node Version Manager, Node.js 버전을 쉽게 관리하는 도구
# Claude Code CLI가 Node.js를 필요로 하기 때문에 설치합니다.
# su - ubuntu -c '...' : ubuntu 사용자로 전환해서 명령 실행
su - ubuntu -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash'
                                            # nvm 설치 스크립트 다운로드 및 실행
su - ubuntu -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && nvm install --lts'
                                            # nvm을 로드한 뒤 Node.js LTS(장기지원) 버전 설치

# =========================
# 6. Claude Code CLI 설치
# =========================
# Claude Code = Anthropic의 CLI 도구로, 터미널에서 Claude AI와 대화하며 코딩 가능
su - ubuntu -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && npm install -g @anthropic-ai/claude-code'
                                            # npm으로 Claude Code를 전역(-g) 설치

# =========================
# 7. 프로젝트 소스코드 클론
# =========================
# Terraform templatefile()에서 전달받은 변수 사용
# github_token이 있으면 private repo clone 가능, 없으면 public만
%{ if github_token != "" ~}
su - ubuntu -c 'mkdir -p ~/clap && cd ~/clap && git clone https://${github_token}@${replace(git_repo_url, "https://", "")}'
%{ else ~}
su - ubuntu -c 'mkdir -p ~/clap && cd ~/clap && git clone ${git_repo_url}'
%{ endif ~}
                                            # 클론된 레포에서 스크립트 실행 권한 부여
REPO_NAME=$(basename "${git_repo_url}" .git)
su - ubuntu -c "chmod +x ~/clap/$REPO_NAME/scripts/claude-slack-runner.sh 2>/dev/null || true"

# =========================
# 8. 코드 자동 동기화 (cron)
# =========================
# 5분마다 git pull로 최신 코드를 반영합니다.
# 개발자가 push하면 최대 5분 후에 EC2에도 반영됩니다.
REPO_NAME=$(basename "${git_repo_url}" .git)
cat > /home/ubuntu/sync-repo.sh << 'SYNC'
#!/bin/bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
cd ~/clap/$(ls ~/clap/) && git pull --ff-only 2>&1 | logger -t repo-sync
SYNC
chmod +x /home/ubuntu/sync-repo.sh
chown ubuntu:ubuntu /home/ubuntu/sync-repo.sh

# crontab에 5분마다 실행 등록
su - ubuntu -c '(crontab -l 2>/dev/null; echo "*/5 * * * * /home/ubuntu/sync-repo.sh") | crontab -'

# =========================
# 9. SSH 비밀번호 인증 활성화
# =========================
# n8n Docker 컨테이너에서 호스트(EC2)로 SSH 접속할 때 비밀번호 인증이 필요합니다.
# (Docker 내부에는 SSH 키가 없으므로)
# sed -i: 파일을 직접 수정 (in-place)
# 's/패턴/대체/' : 패턴을 찾아서 대체
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
                                            # PasswordAuthentication을 yes로 변경
sed -i 's/^#\?KbdInteractiveAuthentication.*/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config
                                            # KbdInteractiveAuthentication을 yes로 변경
systemctl restart sshd                      # SSH 데몬 재시작하여 설정 적용

# =========================
# 9. 완료 마커 파일 생성
# =========================
# 이 파일이 존재하면 초기화가 정상 완료되었다는 의미입니다.
# 확인 방법: cat /home/ubuntu/setup-complete.txt
echo "$(date): user-data setup complete" > /home/ubuntu/setup-complete.txt
chown ubuntu:ubuntu /home/ubuntu/setup-complete.txt