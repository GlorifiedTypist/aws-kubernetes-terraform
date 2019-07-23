#!/bin/bash -v

curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet kubeadm kubectl kubernetes-cni nfs-common
curl -sSL https://get.docker.com/ | sh

cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

cat <<EOF | sudo tee /etc/default/kubelet
KUBELET_EXTRA_ARGS=--cloud-provider=aws
EOF

mkdir -p /etc/systemd/system/docker.service.d

systemctl daemon-reload
systemctl start docker

for i in {1..50}; do kubeadm join --discovery-token-unsafe-skip-ca-verification --token=${bootstrap_token} ${masterIP}:6443 && break || sleep 15; done