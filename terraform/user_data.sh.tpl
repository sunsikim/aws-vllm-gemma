#!/bin/bash
set -eux -o pipefail

exec > >(tee /var/log/user-data.log) 2>&1

dnf install -y jq

# --- instance store: format & mount, use it as docker's data-root ---
DOCKER_DATA_DEVICE=/dev/nvme1n1
DOCKER_DATA_MOUNT=/mnt/docker-data

if ! blkid "$DOCKER_DATA_DEVICE" >/dev/null 2>&1; then
  mkfs.xfs "$DOCKER_DATA_DEVICE"
fi

mkdir -p "$DOCKER_DATA_MOUNT"
DEVICE_UUID=$(blkid -s UUID -o value "$DOCKER_DATA_DEVICE")
if ! grep -q "$DEVICE_UUID" /etc/fstab; then
  echo "UUID=$DEVICE_UUID $DOCKER_DATA_MOUNT xfs defaults,nofail 0 2" >> /etc/fstab
fi
mount -a

mkdir -p "$DOCKER_DATA_MOUNT/docker"

systemctl stop docker 2>/dev/null || true

DAEMON_JSON=/etc/docker/daemon.json
if [ -f "$DAEMON_JSON" ]; then
  jq --arg root "$DOCKER_DATA_MOUNT/docker" '. + {"data-root": $root}' "$DAEMON_JSON" > /tmp/daemon.json
  mv /tmp/daemon.json "$DAEMON_JSON"
else
  printf '{"data-root": "%s"}\n' "$DOCKER_DATA_MOUNT/docker" > "$DAEMON_JSON"
fi

systemctl daemon-reload
systemctl enable docker
systemctl restart docker

for i in $(seq 1 30); do
  if docker info >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

if ! docker compose version >/dev/null 2>&1; then
  mkdir -p /usr/local/lib/docker/cli-plugins
  curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
    -o /usr/local/lib/docker/cli-plugins/docker-compose
  chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
fi

# --- mount-s3: expose the model directory at /mnt/models ---
dnf install -y https://s3.amazonaws.com/mountpoint-s3-release/latest/x86_64/mount-s3.rpm

MODEL_MOUNT=/mnt/models
mkdir -p "$MODEL_MOUNT"
mount-s3 ${model_bucket_name} "$MODEL_MOUNT" \
  --prefix ${model_bucket_prefix}/google/ \
  --read-only \
  --allow-other

for i in $(seq 1 30); do
  if mountpoint -q "$MODEL_MOUNT"; then
    break
  fi
  sleep 2
done

# --- vLLM via docker compose ---
mkdir -p /opt/vllm
cat >/opt/vllm/docker-compose.yml <<'COMPOSE_EOF'
${docker_compose_yaml}
COMPOSE_EOF

cd /opt/vllm
docker compose up -d
