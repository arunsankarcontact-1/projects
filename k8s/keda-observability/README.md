# KEDA Autoscaling Test Project (with Observability)

##  Overview

This project demonstrates **event-driven autoscaling in Kubernetes** using:

* **KEDA** for scaling based on external metrics (Redis queue)
* **Redis** as a message queue
* **Worker pods** to process jobs
* **Prometheus + Grafana** for monitoring and visualization

---

#  Architecture

```text
        +-------------------+
        |   Producer        |
        | (LPUSH jobs)      |
        +---------+---------+
                  |
                  v
        +-------------------+
        |   Redis Queue     |
        |   (myqueue)       |
        +---------+---------+
                  |
        +---------v---------+
        |     KEDA          |
        | monitors queue    |
        +---------+---------+
                  |
                  v
        +-------------------+
        |       HPA         |
        +---------+---------+
                  |
                  v
        +-------------------+
        | Worker Pods       |
        | (consume queue)   |
        +-------------------+

                  |
                  v
        +-------------------+
        | Prometheus        |
        | (scrapes metrics) |
        +---------+---------+
                  |
                  v
        +-------------------+
        | Grafana Dashboard |
        | (visualization)   |
        +-------------------+
```

---

#  Project Structure

```bash
keda-test-project/
│
├── README.md
├── architecture/
│   └── diagram.png
│
├── k8s/
│   ├── redis.yaml
│   ├── worker.yaml
│   ├── scaledobject.yaml
│   ├── service.yaml
│   └── keda-servicemonitor.yaml
│
├── monitoring/
│   ├── grafana-dashboard.json
│
└── load/
    └── generate_messages.sh
```

---

# Components

##  Core

* Kubernetes Deployment (**worker**)
* Redis queue (**myqueue**)
* KEDA ScaledObject

##  Observability

* Prometheus (metrics collection)
* Grafana (visualization dashboards)

##  Security / Access

* KEDA ServiceAccount + RBAC

---

# KEDA ServiceAccount (RBAC)

KEDA requires permissions to:

* Read deployments
* Manage HPA resources
* Watch external metrics

Example:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: keda-operator
  namespace: keda
```

 When installed via Helm, this is automatically created.
 Custom RBAC is only needed for restricted clusters.

---

#  Metrics & Observability

## Install Prometheus + Grafana

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

helm install monitoring prometheus-community/kube-prometheus-stack
```

---

## Key Metrics Used

### KEDA Metrics

```promql
keda_scaler_metrics_value
keda_scaled_objects_errors_total
keda_scaled_metrics_latency_seconds
```

---

###  Kubernetes Metrics

```promql
kube_deployment_status_replicas
kube_deployment_spec_replicas
kube_hpa_status_current_replicas
```

---

##  Recommended Grafana Panels

| Panel        | Query                                       |
| ------------ | ------------------------------------------- |
| Queue Length | `keda_scaler_metrics_value`                 |
| Desired Pods | `kube_deployment_spec_replicas`             |
| Current Pods | `kube_deployment_status_replicas`           |
| Ready Pods   | `kube_deployment_status_replicas_available` |
| HPA          | `kube_hpa_status_current_replicas`          |

---

## Important Notes (from testing)

* Use **aggregation**:

```promql
sum(kube_deployment_status_replicas{namespace="default"})
```

* Avoid:

```promql
instant = true
```

* Use:

```promql
max_over_time(metric[1m])
```

to capture scaling spikes

---

#  Setup

---

## Install KEDA

```bash
helm repo add kedacore https://kedacore.github.io/charts

helm install keda kedacore/keda \
  --namespace keda \
  --create-namespace
```

---

## Install Metrics Server

```bash
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/

helm install metrics-server metrics-server/metrics-server \
  -n kube-system \
  --set args="{--kubelet-insecure-tls,--kubelet-preferred-address-types=InternalIP}"
```

---

## Deploy Redis

```bash
kubectl apply -f k8s/redis.yaml
```

---

## Deploy Worker

```bash
kubectl apply -f k8s/worker.yaml
```

---

## Apply ScaledObject

```bash
kubectl apply -f k8s/scaledobject.yaml
```

---

#  Testing

---

## Generate Load

```bash
bash load/generate_messages.sh
```

OR:

```bash
kubectl exec deploy/redis -- sh -c '
seq 1 50 | xargs -I {} redis-cli LPUSH myqueue job-{}
'
```

---

## Watch Scaling

```bash
kubectl get hpa -w
kubectl get pods -w
```

---

# Validate Metrics

---

## Check queue size

```bash
kubectl exec deploy/redis -- redis-cli LLEN myqueue
```

---

## Prometheus query

```promql
keda_scaler_metrics_value
```

---

## Pod scaling

```promql
sum(kube_deployment_status_replicas{namespace="default"})
```

---

#  Expected Behavior

* Queue increases → KEDA triggers scaling
* HPA increases replicas
* Worker pods consume queue
* Queue drops → scale down to zero

---

#  Test Scenarios

* Burst load (50–100 jobs)
* Sustained load
* Idle cooldown
* Rapid scale up/down

---

# Common Issues

---

##  Metrics show 0–1 only

Cause:

* Prometheus scrape interval
* Using `replicas_available`

Fix:

```promql
kube_deployment_status_replicas
```

---

##  Missing deployment label

Fix:

```promql
sum by (deployment) (kube_deployment_status_replicas)
```

---

##  KEDA cannot connect to Redis

Check:

```bash
kubectl get svc redis
```

---

#  Key Learnings

* KEDA reacts **faster than Prometheus can scrape**
* Always use:

```promql
max_over_time()
```

for scaling visibility

* Deployment metrics ≠ Pod metrics

---

#  References

* https://keda.sh
* https://prometheus.io
* https://grafana.com

---

#  Summary

This project demonstrates:

* Event-driven autoscaling using KEDA
* Queue-based workload processing
* Full observability using Prometheus + Grafana

