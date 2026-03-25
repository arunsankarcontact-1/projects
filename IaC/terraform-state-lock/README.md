# Terraform GCP Remote State & Locking (Focus Guide)

##  Overview

This project demonstrates **Terraform remote state management and locking using GCS**.

Focus areas:

* Remote state storage in GCS
* State locking mechanism
* Preventing concurrent Terraform execution
* Verifying and troubleshooting locks

---

##  Architecture (Relevant to Locking)

* Terraform CLI
* Google Cloud Storage (GCS) backend
* Lock file mechanism (`.tflock`)

---

##  Project Structure

```
.
├── README.md
├── bucket/
│   ├── main.tf
│   └── variables.tf
└── function/
    ├── backend.tf
    ├── function.zip
    ├── iam.tf
    ├── main.tf
    ├── outputs.tf
    └── variables.tf
```

---

##  Remote Backend Configuration

Example backend configuration:

```hcl
terraform {
  backend "gcs" {
    bucket  = "tfstate-maintainer"
    prefix  = "cloud-function-state"
  }
}
```

---

# Terraform State Locking (Core Concept)

Terraform uses **state locking** to prevent multiple users or processes from modifying the same infrastructure at the same time.

---

##  How Locking Works (GCS Backend)

When you run:

```bash
terraform apply
```

Terraform performs:

1. Checks if a lock file exists
2. Creates a lock file in GCS:

```
gs://<bucket>/<prefix>/default.tflock
```

3. Stores metadata inside the lock:

```json
{
  "ID": "1774436357518058",
  "Operation": "OperationTypeApply",
  "Who": "user@machine",
  "Version": "1.x.x",
  "Created": "timestamp"
}
```

4. Blocks any other Terraform execution
5. Releases the lock after completion

---

##  Lock File Location

```bash
gsutil ls gs://tfstate-maintainer/cloud-function-state/
```

Expected:

```
default.tflock
terraform.tfstate
```

---

##  Verifying State Locking

### Step 1: Start Terraform Apply

Terminal 1:

```bash
terraform apply
```

---

### Step 2: Run Another Apply

Terminal 2:

```bash
terraform apply
```

---

##  Expected Output

```
Error acquiring the state lock
```

This confirms:

* Lock is active
* Concurrent execution is blocked

---

##  Example Lock Error

```
Error 412: conditionNotMet
```

Meaning:

* Lock file already exists
* Terraform refused to overwrite it

---

## Unlocking State (Stale Lock)

If a process crashes or is interrupted, lock may persist.

### Step 1: Use force unlock

```bash
terraform force-unlock <LOCK_ID>
```

---

### Step 2: Retry

```bash
terraform apply
```

---

## Manual Cleanup (Last Resort)

```bash
gsutil rm gs://tfstate-maintainer/cloud-function-state/default.tflock
```

Use only if `force-unlock` fails.

---

## What NOT to Do

```bash
terraform apply -lock=false
```

Reason:

* Bypasses locking
* Can corrupt state
* Not safe in multi-user environments

---

##  Internal Mechanism (Deep Insight)

GCS locking uses:

* Object generation numbers
* Precondition checks (`ifGenerationMatch`)

If lock exists:

```
Error 412: conditionNotMet
```

This ensures atomic lock acquisition.

---

## Comparison Across Clouds

| Cloud | Locking Mechanism |
| ----- | ----------------- |
| AWS   | DynamoDB          |
| Azure | Blob Lease        |
| GCP   | GCS Object Lock   |

---

##  Summary

* Terraform creates `.tflock` file during execution
* Prevents concurrent modifications
* Ensures state consistency
* Requires manual unlock if interrupted

