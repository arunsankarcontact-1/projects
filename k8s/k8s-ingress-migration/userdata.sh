#!/bin/bash
set -e

# -----------------------------
# VARIABLES
# -----------------------------
POD_CIDR="10.244.0.0/16"

# -----------------------------
# SYSTEM UPDATE
# -----------------------------
apt-get update -y
apt-get upgrade -y

# -----------------------------
# DISABLE SWAP (required)
# -----------------------------
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# -----------------------------
# LOAD KERNEL MODULES
# -----------------------------
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

# -----------------------------
# INSTALL CONTAINERD
# -----------------------------
apt-get install -y containerd

mkdir -p /etc/containerd

# IMPORTANT: Use default config (CRI enabled)
containerd config default | tee /etc/containerd/config.toml

# FIX: Enable SystemdCgroup (required for kubelet)
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# FIX: Ensure CRI is NOT disabled
sed -i 's/disabled_plugins = \["cri"\]/#disabled_plugins = \["cri"\]/' /etc/containerd/config.toml

systemctl restart containerd
systemctl enable containerd

# -----------------------------
# INSTALL KUBERNETES
# -----------------------------
apt-get install -y apt-transport-https ca-certificates curl gpg

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' \
  | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update -y

apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

systemctl enable kubelet

# -----------------------------
# INITIALIZE CLUSTER
# -----------------------------
kubeadm init --pod-network-cidr=${POD_CIDR} > /root/kubeinit.log

# -----------------------------
# CONFIGURE KUBECTL FOR ROOT
# -----------------------------
mkdir -p /root/.kube
cp /etc/kubernetes/admin.conf /root/.kube/config
chown root:root /root/.kube/config

PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

cp /etc/kubernetes/admin.conf /home/ubuntu/kubeconfig
sed -i "s#server: https://.*:6443#server: https://${PUBLIC_IP}:6443#g" /home/ubuntu/kubeconfig
chown ubuntu:ubuntu /home/ubuntu/kubeconfig
chmod 600 /home/ubuntu/kubeconfig

# -----------------------------
# WAIT FOR API SERVER
# -----------------------------
export KUBECONFIG=/etc/kubernetes/admin.conf

echo "Waiting for API server..."
until kubectl get nodes; do
  sleep 5
done

# -----------------------------
# INSTALL FLANNEL
# -----------------------------
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

# -----------------------------
# REMOVE CONTROL PLANE TAINT
# -----------------------------
kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true

# -----------------------------
# FINAL STATUS
# -----------------------------
kubectl get nodes > /root/node-status.txt
kubectl get pods -A > /root/pods-status.txt

echo "Kubernetes setup completed!" > /root/status.txt
