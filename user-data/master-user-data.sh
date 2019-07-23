#!/bin/bash -v

curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet kubeadm kubectl kubernetes-cni
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

mkdir -p /etc/systemd/system/docker.service.d

systemctl daemon-reload
systemctl restart docker

# https://medium.com/@kosta709/kubernetes-by-kubeadm-config-yamls-94e2ee11244

cat > /etc/kubernetes/kubeadm-config.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1beta1
kind: InitConfiguration
bootstrapTokens:
- token: "${bootstrapToken}"
  description: "default kubeadm bootstrap token"
  ttl: 24h0m0s
localAPIEndpoint:
  advertiseAddress: `curl http://169.254.169.254/latest/meta-data/local-ipv4`
  bindPort: 6443
---
apiVersion: kubeadm.k8s.io/v1beta1
kind: ClusterConfiguration
controlPlaneEndpoint: ${internalDNS}:6443
apiServer:
  certSANs:
  - ${internalDNS}
  - ${externalDNS}
networking:
  podSubnet: 10.244.0.0/16
apiServerExtraArgs:
  cloud-provider: aws
controllerManagerExtraArgs:
  cloud-provider: aws
EOF

kubeadm init --config=/etc/kubernetes/kubeadm-config.yaml

mkdir ~/.kube
cp /etc/kubernetes/admin.conf ~/.kube/config

export KUBECONFIG=~/.kube/config
kubectl apply -f https://docs.projectcalico.org/v3.8/manifests/calico.yaml
