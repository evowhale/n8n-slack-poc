# =============================================================================
# variables.tf — 변수 정의 파일
# =============================================================================
# Terraform에서 사용할 변수(= 설정값)를 정의합니다.
# 하드코딩 대신 변수를 쓰면, 환경(개발/운영)마다 값만 바꿔서 재사용할 수 있습니다.
#
# 변수 값을 지정하는 방법 (우선순위 순):
#   1. terraform.tfvars 파일에 작성 (가장 일반적)
#   2. 실행 시 -var 옵션: terraform apply -var="key_name=my-key"
#   3. 환경변수: export TF_VAR_key_name="my-key"
#   4. default 값 사용 (default가 없으면 실행 시 직접 입력해야 함)
# =============================================================================

# -----------------------------------------------------------------------------
# aws_region: AWS 리전 (= 데이터센터 위치)
# -----------------------------------------------------------------------------
# 서울 리전(ap-northeast-2)이 기본값입니다.
# 한국에서 접속할 때 가장 빠르고, 한국 사용자 대상 서비스에 적합합니다.
variable "aws_region" {
  description = "AWS 리전"              # 변수 설명 (terraform plan 등에서 표시됨)
  default     = "ap-northeast-2"        # 기본값: 서울 리전
}

# -----------------------------------------------------------------------------
# instance_type: EC2 인스턴스 사양
# -----------------------------------------------------------------------------
# EC2 인스턴스의 CPU/메모리 사양을 결정합니다.
# t3.large = 2 vCPU + 8GB RAM으로, n8n + Docker를 돌리기에 충분합니다.
# 비용을 줄이려면 t3.medium(2 vCPU, 4GB)으로 낮출 수도 있습니다.
variable "instance_type" {
  description = "EC2 인스턴스 타입"
  default     = "t3.large"              # 기본값: 2 vCPU, 8GB RAM
}

# -----------------------------------------------------------------------------
# key_name: SSH 키 페어 이름
# -----------------------------------------------------------------------------
# EC2에 SSH로 접속하려면 키 페어가 필요합니다.
# AWS 콘솔 > EC2 > 키 페어에서 미리 생성해두어야 합니다.
# default가 없으므로, terraform.tfvars에 반드시 값을 지정해야 합니다.
variable "key_name" {
  description = "SSH 접속용 키 페어 이름 (AWS에 미리 등록된 키)"
  type        = string                  # 문자열 타입 (type을 지정하면 잘못된 값 입력을 방지)
  # default 없음 → terraform apply 시 반드시 값을 입력해야 함
}

# -----------------------------------------------------------------------------
# my_ip: 내 공인 IP 주소
# -----------------------------------------------------------------------------
# 보안 그룹에서 SSH와 n8n UI 접속을 내 IP로만 제한하기 위해 사용합니다.
# CIDR 형식으로 입력해야 합니다 (예: "123.45.67.89/32")
# /32는 "이 IP 하나만"이라는 뜻입니다.
# 내 IP 확인: https://checkip.amazonaws.com
variable "my_ip" {
  description = "내 공인 IP (SSH/n8n 접속 허용용, CIDR 형식: x.x.x.x/32)"
  type        = string
  # default 없음 → terraform apply 시 반드시 값을 입력해야 함
}

# -----------------------------------------------------------------------------
# volume_size: EC2 디스크(EBS) 크기
# -----------------------------------------------------------------------------
# EC2에 연결되는 SSD 디스크의 용량(GB)입니다.
# Docker 이미지, n8n 데이터 등을 저장하므로 30GB 정도면 POC에 충분합니다.
variable "volume_size" {
  description = "EBS 볼륨 크기 (GB)"
  default     = 30                      # 기본값: 30GB
}

# -----------------------------------------------------------------------------
# github_token: GitHub Personal Access Token (PAT)
# -----------------------------------------------------------------------------
# private repo를 clone하려면 인증이 필요합니다.
# GitHub > Settings > Developer settings > Personal access tokens > Generate new token
# "repo" 권한 체크 후 생성한 토큰을 입력하세요.
# 빈 문자열이면 public repo만 clone 가능합니다.
variable "github_token" {
  description = "GitHub PAT (private repo clone용, 빈 문자열이면 public만 가능)"
  type        = string
  default     = ""
  sensitive   = true  # terraform output이나 로그에 노출되지 않음
}

# -----------------------------------------------------------------------------
# git_repo_url: clone할 Git 레포 URL
# -----------------------------------------------------------------------------
# 기본값은 POC 테스트용 public repo입니다.
# private repo를 쓰려면 github_token과 함께 변경하세요.
variable "git_repo_url" {
  description = "clone할 Git 레포 URL (예: https://github.com/org/repo.git)"
  type        = string
  default     = "https://github.com/evowhale/n8n-slack-poc.git"
}