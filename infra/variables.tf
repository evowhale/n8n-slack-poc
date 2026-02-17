variable "aws_region" {
  description = "AWS 리전"
  default     = "ap-northeast-2" # 서울
}

variable "instance_type" {
  description = "EC2 인스턴스 타입"
  default     = "t3.large" # 2 vCPU, 8GB RAM
}

variable "key_name" {
  description = "SSH 접속용 키 페어 이름 (AWS에 미리 등록된 키)"
  type        = string
}

variable "my_ip" {
  description = "내 공인 IP (SSH/n8n 접속 허용용, CIDR 형식: x.x.x.x/32)"
  type        = string
}

variable "volume_size" {
  description = "EBS 볼륨 크기 (GB)"
  default     = 30
}
