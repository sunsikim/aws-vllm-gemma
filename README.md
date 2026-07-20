# aws-vllm-gemma

Terraform으로 EC2에 vLLM OpenAI-compatible Gemma 4 서버를 수동 개입 없이 띄우는 방법

## 아키텍처

- **네트워크**: 새 VPC + public subnet 1개, IGW.
- **Security Group**: 인바운드는 vLLM 포트(기본 8000)만 `0.0.0.0/0`에 개방(인증 없음), 아웃바운드는 전체 허용. SSH는 열지 않고 SSM으로만 접속.
- **IAM role**: `AmazonSSMManagedInstanceCore`(SSM 접속용) + S3 모델 버킷의 지정 prefix에 대한 `GetObject`/`ListBucket` 인라인 정책.
- **EC2**: 고정 AMI(Deep Learning Base AMI with Single CUDA, Amazon Linux 2023), `g7e.2xlarge`. 루트 볼륨은 30GB gp3(암호화), IMDSv2 강제.
- **user-data** (`terraform/user_data.sh.tpl`, 최초 부팅 1회 실행):
  1. instance store NVMe(`/dev/nvme1n1`, 1.9TB)를 xfs로 포맷해 `/mnt/docker-data`에 마운트하고, 기존 docker 설정을 유지한 채 `data-root`만 그쪽으로 옮김.
  2. `mount-s3`([Mountpoint for S3](https://aws.amazon.com/ko/blogs/korea/mountpoint-for-amazon-s3-generally-available-and-ready-for-production-workloads/))를 설치해 `s3://<bucket>/<prefix>/google/` 아래를 `/mnt/models`에 읽기 전용으로 마운트.
  3. `docker-compose.yml`을 그대로 박아 넣고 `vllm/vllm-openai:v0.25.1` 이미지를 Docker Hub에서 직접 pull해 `docker compose up -d` (ECR 미러링 없음).

## 사전 준비

- Terraform >= 1.5
- VPC/EC2/IAM 리소스를 생성할 수 있는 AWS 자격증명(프로필)
- 모델 파일이 이미 업로드된 S3 버킷/prefix (huggingface 스냅샷 그대로)

## 사용법

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

주요 변수(`terraform/variables.tf`):

| 변수 | 기본값 | 설명 |
|---|---|---|
| `aws_region` | `ap-northeast-2` | 배포 리전 |
| `model_bucket_name` | `blank-llm-batch` | 모델 S3 버킷 |
| `model_bucket_prefix` | `models` | IAM 정책 스코프 prefix |
| `ami_id` | `ami-0f68bfb7fe05d3c2c` | 고정 DLAMI |
| `instance_type` | `g7e.2xlarge` | GPU 인스턴스 타입 |
| `root_volume_size` | `30` | 루트 EBS 크기(GiB) |

apply가 끝나면 `vllm_endpoint` output으로 접속 URL이 나옵니다.

## 테스트

```bash
curl -sS http://<instance_public_ip>:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "google/gemma-4-26B-A4B-it",
    "messages": [{"role": "user", "content": "YOUR_PROMPT_HERE"}]
  }' | jq .
```

## 정리

```bash
terraform destroy
```

## 알려진 제약

- 8000번 포트는 인증 없이 공개되어 있어 **연습용으로만** 사용할 것. 운영에 쓰려면 소스 IP 제한 또는 `--api-key` 적용 필요.
- instance store는 stop 시 데이터가 사라지고 user-data는 최초 부팅에만 실행되므로, 이 프로젝트는 **stop/start 없이 매번 apply/destroy로 재생성**하는 걸 전제로 함.
- `docker-compose.yml`과 mount-s3 prefix(`models/google/`)는 `google/gemma-4-26B-A4B-it` 모델에 맞춰 하드코딩되어 있음. 다른 모델로 바꾸려면 `terraform/user_data.sh.tpl`을 직접 수정해야 함.
