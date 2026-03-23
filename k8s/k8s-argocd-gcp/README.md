# GCP Kubernetes Minimal Cluster with Argo CD & HAProxy Ingress

This repository demonstrates a minimal **Kubernetes cluster setup on Google Cloud Platform (GCP)** using **Terraform**, including:

- Two VM nodes (master + worker)
- Kubernetes 1.29 with **containerd**
- Flannel CNI for networking
- HAProxy ingress controller via Helm
- Argo CD deployment for GitOps
- Basic guestbook application deployment via Argo CD

This setup is intended for **learning, testing, and demo purposes**.

---

## Prerequisites

1. **GCP Account** with billing enabled
2. **gcloud CLI** installed and authenticated:
```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project <PROJECT_ID>
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-b
```

Terraform v1.6+ installed
kubectl v1.29+ installed
Helm v3+ installed

# Architecture

```bash
+---------------------+         +---------------------+
| GCP VM (Master)     |         | GCP VM (Worker)     |
|---------------------|         |---------------------|
| Kubernetes Master   | <-----> | Kubernetes Node     |
| kubeadm + containerd|         | kubelet + containerd|
| Flannel CNI         |         |                     |
+---------------------+         +---------------------+
          |
          v
   HAProxy Ingress (NodePort: 30082/30445)
          |
          v
   Argo CD (GitOps deployment)
          |
          v
   Guestbook UI Application
```
# Repo structure

```bash
.
├─ README.md
├─ firewall.tf
├─ instances.tf
├─ network.tf
├─ outputs.tf
├─ provider.tf
├─ variables.tf
├─ userdata-master.sh
├─ userdata-worker.sh
├─ terraform.tfstate
├─ terraform.tfstate.backup
├─ vmplan
├─ ingress
│  ├─ guestbook-ingress.yaml
│  ├─ values-argocd.yaml
│  ├─ values-haproxy-ingress.yaml
│  └─ values-haproxy.yaml
└─ screenshots
   ├─ argo-kustomize-ui-app.png
   ├─ guestbook-min.png
   └─ guestbook-ui-log.png
```

# Kubernetes Node Setup

Master (userdata-master.sh):

Installs containerd
Installs kubeadm, kubelet, kubectl
Initializes cluster with Flannel
Generates join script for worker

Worker (userdata-worker.sh):

Installs containerd and Kubernetes components
Waits for master join script over HTTP
Joins the cluster automatically

Verify cluster:

```bash
kubectl get nodes
kubectl get pods -A
```

# HAProxy Ingress Installation

Install via Helm:

```bash
helm repo add haproxytech https://haproxytech.github.io/helm-charts
helm repo update

helm install haproxy-ingress haproxytech/kubernetes-ingress \
  -f values-haproxy.yaml
```

Verify:

```bash
kubectl get pods -l app=haproxy-ingress
kubectl get ingressclass
```

# Argo CD Installation

Install via Helm:

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

helm install argocd argo/argo-cd -n argocd --create-namespace \
  --set server.service.type=NodePort \
  --set server.service.nodePort=30880
```

Access Argo CD UI:

```bash
kubectl get svc -n argocd
```

# Guestbook Application Deployment
Prepare Kustomize base manifests for guestbook app.
Deploy via Argo CD UI or CLI:

```bash
argocd app create guestbook-ui \
  --repo  https://github.com/argoproj/argocd-example-apps \
  --path kustomize-guestbook \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default
argocd app sync guestbook-ui
```

Verify ingress:

```bash
kubectl get ingress
kubectl describe ingress guestbook-ui-ingress

```
Accessible via HAProxy NodePort: http://<NODE_IP>:30082.


Delete Argo CD applications:

```bash
argocd app delete guestbook-ui --cascade

```

# Conclusion

This repository demonstrates a lightweight, production-grade Kubernetes environment in GCP using:

Terraform for infrastructure provisioning
Containerd runtime with Kubernetes 1.29
Flannel CNI networking
HAProxy ingress controller for HTTP routing
Argo CD for GitOps-based application deployment

It provides a reusable template for experimenting with multi-node clusters, ingress controllers, and GitOps workflows in a cloud-native environment.
