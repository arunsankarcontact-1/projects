#!/bin/bash
set -e

POD_CIDR="10.244.0.0/16"

# -----------------------------
# BASE SETUP (UNCHANGED)
# -----------------------------
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

# -----------------------------
# CONTAINERD (UNCHANGED)
# -----------------------------
apt-get install -y containerd
mkdir -p /etc/containerd

containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sed -i 's/disabled_plugins = \["cri"\]/#disabled_plugins = \["cri"\]/' /etc/containerd/config.toml

systemctl restart containerd
systemctl enable containerd

# -----------------------------
# KUBERNETES (UNCHANGED)
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
# INIT CLUSTER (UPDATED)
# -----------------------------
kubeadm init \
  --pod-network-cidr=${POD_CIDR} \
  --apiserver-advertise-address=$(hostname -i) \
  > /root/kubeinit.log

# -----------------------------
# KUBECONFIG (UNCHANGED)
# -----------------------------
mkdir -p /root/.kube
cp /etc/kubernetes/admin.conf /root/.kube/config

PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

cp /etc/kubernetes/admin.conf /home/ubuntu/kubeconfig
sed -i "s#server: https://.*:6443#server: https://${PUBLIC_IP}:6443#g" /home/ubuntu/kubeconfig
chown ubuntu:ubuntu /home/ubuntu/kubeconfig
chmod 600 /home/ubuntu/kubeconfig

export KUBECONFIG=/etc/kubernetes/admin.conf

# -----------------------------
# WAIT FOR API
# -----------------------------
until kubectl get nodes; do sleep 5; done

# -----------------------------
# INSTALL FLANNEL (UNCHANGED)
# -----------------------------
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

# -----------------------------
# ALLOW SCHEDULING ON MASTER
# -----------------------------
kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true

# -----------------------------
# GENERATE JOIN COMMAND
# -----------------------------
mkdir -p /var/lib/kubeadm
kubeadm token create --print-join-command > /var/lib/kubeadm/join.sh
chmod +x /var/lib/kubeadm/join.sh

# Serve join script over HTTP
apt-get install -y python3
cd /var/lib/kubeadm
nohup python3 -m http.server 8080 &

# -----------------------------
# FINAL STATUS
# -----------------------------
kubectl get nodes > /root/node-status.txt
kubectl get pods -A > /root/pods-status.txt

echo "Master setup completed!" > /root/status.txt
