#!/bin/bash
set -e

POD_CIDR="10.244.0.0/16"

apt-get update -y
apt-get upgrade -y

swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

modprobe overlay
modprobe br_netfilter

cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

# containerd
apt-get install -y containerd
mkdir -p /etc/containerd

containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sed -i 's/disabled_plugins = \["cri"\]/#disabled_plugins = \["cri"\]/' /etc/containerd/config.toml

systemctl restart containerd
systemctl enable containerd

# Kubernetes
apt-get install -y apt-transport-https ca-certificates curl gpg

mkdir -p /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' \
  | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update -y
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

systemctl enable kubelet

# INIT
kubeadm init \
  --pod-network-cidr=${POD_CIDR} \
  --apiserver-advertise-address=$(hostname -I | awk '{print $1}') \
  > /root/kubeinit.log

mkdir -p /root/.kube
cp /etc/kubernetes/admin.conf /root/.kube/config

# GCP METADATA FIX
PUBLIC_IP=$(curl -H "Metadata-Flavor: Google" \
http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)

cp /etc/kubernetes/admin.conf /home/ubuntu/kubeconfig
sed -i "s#server: https://.*:6443#server: https://${PUBLIC_IP}:6443#g" /home/ubuntu/kubeconfig
chown ubuntu:ubuntu /home/ubuntu/kubeconfig
chmod 600 /home/ubuntu/kubeconfig

export KUBECONFIG=/etc/kubernetes/admin.conf

until kubectl get nodes; do sleep 5; done

kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true

mkdir -p /var/lib/kubeadm
kubeadm token create --print-join-command > /var/lib/kubeadm/join.sh
chmod +x /var/lib/kubeadm/join.sh

apt-get install -y python3
cd /var/lib/kubeadm
nohup python3 -m http.server 8080 &

kubectl get nodes > /root/node-status.txt
kubectl get pods -A > /root/pods-status.txt
