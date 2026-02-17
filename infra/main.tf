# =============================================================================
# main.tf — 메인 인프라 정의 파일
# =============================================================================
# Terraform의 핵심 파일로, 실제로 AWS에 만들 리소스(서버, 네트워크 등)를 정의합니다.
# `terraform apply` 명령을 실행하면 이 파일에 적힌 대로 AWS 인프라가 생성됩니다.
# =============================================================================

# -----------------------------------------------------------------------------
# terraform 블록: Terraform 자체의 설정
# -----------------------------------------------------------------------------
# - required_version: 이 코드를 실행하려면 Terraform 1.0 이상이 필요하다는 뜻
# - required_providers: 이 코드가 어떤 클라우드(AWS, GCP 등)를 사용하는지 명시
terraform {
  required_version = ">= 1.0"  # Terraform CLI 버전 1.0 이상 필수

  required_providers {
    aws = {
      source  = "hashicorp/aws"  # HashiCorp이 공식 제공하는 AWS 프로바이더 사용
      version = "~> 5.0"         # 5.x 버전대 사용 (~>는 "5.0 이상, 6.0 미만"이라는 뜻)
    }
  }
}

# -----------------------------------------------------------------------------
# provider 블록: AWS 연결 설정
# -----------------------------------------------------------------------------
# Terraform이 AWS API를 호출할 때 사용할 설정입니다.
# region: 리소스를 생성할 AWS 리전 (var.aws_region은 variables.tf에서 정의)
provider "aws" {
  region = var.aws_region  # variables.tf에서 정의한 리전 값 참조 (기본값: 서울 ap-northeast-2)
}

# =============================================================================
# data 소스: 이미 AWS에 존재하는 정보를 "조회"하는 블록 (새로 만드는 게 아님!)
# =============================================================================

# -----------------------------------------------------------------------------
# data "aws_ami": 최신 Ubuntu 22.04 AMI(서버 이미지) ID를 자동으로 찾아옴
# -----------------------------------------------------------------------------
# AMI = Amazon Machine Image, 즉 EC2 서버를 만들 때 사용할 OS 이미지입니다.
# Ubuntu 버전이 업데이트될 때마다 AMI ID가 바뀌므로, 하드코딩 대신 자동 조회합니다.
data "aws_ami" "ubuntu" {
  most_recent = true                # 여러 개가 매칭되면 가장 최신 AMI를 선택
  owners      = ["099720109477"]    # Canonical(Ubuntu 공식 제작사)의 AWS 계정 ID

  # filter: AMI 이름 패턴으로 필터링
  # "ubuntu-jammy-22.04-amd64-server-*"에서 *는 날짜/버전이 바뀌는 부분
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  # filter: 가상화 타입이 HVM인 것만 (현대 EC2 인스턴스는 모두 HVM 사용)
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# =============================================================================
# resource 블록: AWS에 실제로 "생성"할 리소스를 정의
# =============================================================================

# -----------------------------------------------------------------------------
# resource "aws_security_group": 보안 그룹 (= 가상 방화벽)
# -----------------------------------------------------------------------------
# 보안 그룹은 EC2 인스턴스에 들어오고(ingress) 나가는(egress) 네트워크 트래픽을
# 허용/차단하는 방화벽 규칙입니다.
# 예: "22번 포트(SSH)는 내 IP에서만 접속 가능" 같은 규칙을 정의합니다.
resource "aws_security_group" "n8n_poc" {
  name        = "n8n-slack-poc-sg"       # AWS 콘솔에 표시될 보안 그룹 이름
  description = "n8n + Claude Code POC"  # 보안 그룹 설명

  # --- ingress (인바운드 규칙): 외부 → EC2로 들어오는 트래픽 허용 규칙 ---

  # 규칙 1: SSH 접속 허용 (포트 22)
  # - 내 IP(var.my_ip)에서만 SSH 접속 가능하도록 제한
  # - cidr_blocks: 허용할 IP 범위 (CIDR 표기법, 예: "1.2.3.4/32"는 단일 IP)
  ingress {
    description = "SSH"
    from_port   = 22             # 시작 포트
    to_port     = 22             # 끝 포트 (같으면 단일 포트)
    protocol    = "tcp"          # TCP 프로토콜
    cidr_blocks = [var.my_ip]    # 내 IP만 허용 (variables.tf에서 정의)
  }

  # 규칙 2: n8n 웹 UI 접속 허용 (포트 5678)
  # - n8n은 기본적으로 5678 포트에서 웹 UI를 제공함
  # - 역시 내 IP에서만 접속 가능
  ingress {
    description = "n8n UI"
    from_port   = 5678
    to_port     = 5678
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]    # 내 IP만 허용
  }

  # 규칙 3: HTTPS 접속 허용 (포트 443)
  # - Slack이 webhook을 보낼 때 사용하는 포트
  # - Slack 서버의 IP를 특정할 수 없으므로 전체(0.0.0.0/0) 허용
  ingress {
    description = "HTTPS for Slack webhook"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # 모든 IP에서 접속 허용
  }

  # --- egress (아웃바운드 규칙): EC2 → 외부로 나가는 트래픽 허용 규칙 ---

  # EC2에서 외부로 나가는 모든 트래픽을 허용
  # - from_port=0, to_port=0, protocol="-1"은 "모든 포트, 모든 프로토콜"을 의미
  # - 패키지 설치, API 호출 등을 위해 아웃바운드는 전체 허용하는 것이 일반적
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"           # "-1"은 모든 프로토콜(TCP, UDP, ICMP 등 전부)
    cidr_blocks = ["0.0.0.0/0"]  # 모든 목적지 허용
  }

  # tags: AWS 리소스에 붙이는 이름표 (AWS 콘솔에서 식별/검색할 때 유용)
  tags = {
    Name = "n8n-slack-poc"
  }
}

# -----------------------------------------------------------------------------
# resource "aws_instance": EC2 인스턴스 (= 가상 서버)
# -----------------------------------------------------------------------------
# 실제로 실행되는 서버입니다. Ubuntu OS 위에서 n8n, Claude Code 등이 동작합니다.
resource "aws_instance" "n8n_poc" {
  ami                    = data.aws_ami.ubuntu.id              # 위에서 조회한 최신 Ubuntu AMI 사용
  instance_type          = var.instance_type                   # 인스턴스 사양 (기본: t3.large = 2vCPU, 8GB RAM)
  key_name               = var.key_name                        # SSH 접속에 사용할 키 페어 이름 (AWS에 미리 등록 필요)
  vpc_security_group_ids = [aws_security_group.n8n_poc.id]     # 위에서 만든 보안 그룹 연결

  # root_block_device: EC2에 연결되는 디스크(EBS 볼륨) 설정
  root_block_device {
    volume_size = var.volume_size  # 디스크 크기 (기본: 30GB)
    volume_type = "gp3"           # 볼륨 타입 (gp3 = 범용 SSD, 가성비 좋음)
  }

  # user_data: EC2가 처음 부팅될 때 자동으로 실행되는 초기화 스크립트
  # templatefile: 변수를 치환하여 전달 (github_token, git_repo_url)
  user_data = templatefile("${path.module}/user-data.sh", {
    github_token  = var.github_token
    git_repo_url  = var.git_repo_url
  })

  tags = {
    Name = "n8n-slack-poc"
  }
}

# -----------------------------------------------------------------------------
# resource "aws_eip": Elastic IP (= 고정 공인 IP)
# -----------------------------------------------------------------------------
# EC2 인스턴스를 껐다 켜면 공인 IP가 바뀌는데,
# Elastic IP를 연결하면 항상 같은 IP로 접속할 수 있습니다.
# Slack webhook URL 등에 고정 IP가 필요하기 때문에 사용합니다.
resource "aws_eip" "n8n_poc" {
  instance = aws_instance.n8n_poc.id  # 위에서 만든 EC2 인스턴스에 연결
  domain   = "vpc"                    # VPC 내에서 사용 (현대 AWS에서는 항상 "vpc")

  tags = {
    Name = "n8n-slack-poc"
  }
}