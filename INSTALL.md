# Bank of Anthos Installation Guide

This guide provides comprehensive instructions for installing and deploying the Bank of Anthos application across different environments and platforms.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Quick Start Options](#quick-start-options)
4. [Installation Methods](#installation-methods)
   - [1. Google Kubernetes Engine (GKE) - Recommended](#1-google-kubernetes-engine-gke---recommended)
   - [2. Local Development with Skaffold](#2-local-development-with-skaffold)
   - [3. Other Kubernetes Clusters](#3-other-kubernetes-clusters)
   - [4. Docker Compose (Local Development)](#4-docker-compose-local-development)
   - [5. VM Deployment (Monolith)](#5-vm-deployment-monolith)
5. [Advanced Deployment Options](#advanced-deployment-options)
6. [Verification](#verification)
7. [Troubleshooting](#troubleshooting)
8. [Clean Up](#clean-up)

## Overview

Bank of Anthos is a sample HTTP-based web application that simulates a bank's payment processing network. It consists of multiple microservices and can be deployed in various ways depending on your use case:

- **Production/Demo**: Deploy to Google Kubernetes Engine (GKE) or other Kubernetes clusters
- **Development**: Use Skaffold for local development with hot reloading
- **Testing**: Use Docker Compose for lightweight local testing
- **Legacy Migration Demo**: Deploy the monolith version to a VM

## Prerequisites

### Required Tools

Choose the tools based on your installation method:

#### For All Kubernetes Deployments
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) - Kubernetes command-line tool
- [Git](https://git-scm.com/downloads) - To clone the repository

#### For GKE Deployments
- [Google Cloud SDK (gcloud)](https://cloud.google.com/sdk/install)
- [Google Cloud Project](https://cloud.google.com/resource-manager/docs/creating-managing-projects#creating_a_project) with billing enabled

#### For Local Development
- [Docker Engine or Docker Desktop](https://www.docker.com/)
- [Skaffold 2.9+](https://skaffold.dev/docs/install/) (latest version recommended)

#### For Java Development (if modifying services)
- [OpenJDK 21+](https://openjdk.java.net/projects/jdk/21/)
- [Maven 3.9+](https://downloads.apache.org/maven/maven-3/)

#### For Python Development (if modifying services)
- [Python 3.12+](https://www.python.org/downloads/)
- [pip-tools](https://pypi.org/project/pip-tools/)

### System Requirements

- **Memory**: 8GB RAM minimum (16GB recommended for local development)
- **CPU**: 4 cores minimum
- **Disk**: 10GB free space
- **Network**: Internet connection for downloading images and dependencies

## Quick Start Options

### 🚀 Interactive Tutorial (Fastest)
For the quickest start, use the interactive Cloud Shell tutorial:

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://ssh.cloud.google.com/cloudshell/editor?show=ide&cloudshell_git_repo=https://github.com/GoogleCloudPlatform/bank-of-anthos&cloudshell_workspace=.&cloudshell_tutorial=extras/cloudshell/tutorial.md)

### 🔧 One-Command GKE Deployment
If you have `gcloud` configured:
```bash
curl -sSL https://raw.githubusercontent.com/prats-2311/bank-of-anthos/main/scripts/quickstart-gke.sh | bash
```

## Installation Methods

### 1. Google Kubernetes Engine (GKE) - Recommended

This is the recommended method for production deployments and demos.

#### Step 1: Set up your environment

```bash
# Clone the repository
git clone https://github.com/GoogleCloudPlatform/bank-of-anthos
cd bank-of-anthos/

# Set your project ID and region
export PROJECT_ID=<YOUR_PROJECT_ID>
export REGION=us-central1
export CLUSTER_NAME=bank-of-anthos
```

#### Step 2: Enable required APIs

```bash
gcloud services enable container.googleapis.com \
  --project=${PROJECT_ID}
```

#### Step 3: Create GKE cluster

```bash
# Create an Autopilot cluster (recommended)
gcloud container clusters create-auto ${CLUSTER_NAME} \
  --project=${PROJECT_ID} \
  --region=${REGION}

# Alternative: Create a standard cluster
# gcloud container clusters create ${CLUSTER_NAME} \
#   --machine-type=e2-standard-4 \
#   --num-nodes=4 \
#   --project=${PROJECT_ID} \
#   --zone=${REGION}-a
```

#### Step 4: Get cluster credentials

```bash
gcloud container clusters get-credentials ${CLUSTER_NAME} \
  --project=${PROJECT_ID} \
  --region=${REGION}
```

#### Step 5: Deploy the application

```bash
# Deploy JWT secret and application
kubectl apply -f ./extras/jwt/jwt-secret.yaml
kubectl apply -f ./kubernetes-manifests/
```

#### Step 6: Wait for deployment to complete

```bash
# Check pod status
kubectl get pods

# Wait for all pods to be running
kubectl wait --for=condition=Ready pod --all --timeout=300s
```

#### Step 7: Access the application

```bash
# Get the external IP
kubectl get service frontend

# Access the application at http://EXTERNAL_IP
```

### 2. Local Development with Skaffold

Perfect for development with hot reloading and debugging capabilities.

#### Step 1: Install prerequisites

Ensure you have Docker, Skaffold, and kubectl installed and configured.

#### Step 2: Clone and configure

```bash
git clone https://github.com/GoogleCloudPlatform/bank-of-anthos
cd bank-of-anthos/

# If using a remote cluster, configure your container registry
export PROJECT_ID=<YOUR_PROJECT_ID>
```

#### Step 3: Start development environment

```bash
# For local Kubernetes (Docker Desktop, minikube, etc.)
skaffold dev

# For remote cluster with custom registry
skaffold dev --default-repo=gcr.io/${PROJECT_ID}
```

This will:
- Build all container images
- Deploy to your configured Kubernetes cluster
- Watch for file changes and automatically rebuild/redeploy
- Stream logs from all services

#### Step 4: Access the application

```bash
kubectl get service frontend
# Access via the service IP/port or use port-forwarding
kubectl port-forward service/frontend 8080:80
# Then visit http://localhost:8080
```

### 3. Other Kubernetes Clusters

Deploy to any Kubernetes cluster (EKS, AKS, OpenShift, etc.).

#### Step 1: Configure cluster access

Ensure your `kubectl` is configured to access your cluster:

```bash
kubectl cluster-info
```

#### Step 2: Handle Google Cloud Operations (Optional)

Bank of Anthos exports metrics to Google Cloud Operations by default. For non-GKE clusters:

**Option A: Disable telemetry (simplest)**
```bash
# Download and modify the manifests to disable telemetry
curl -O https://raw.githubusercontent.com/GoogleCloudPlatform/bank-of-anthos/main/kubernetes-manifests/config.yaml
# Edit the config.yaml file and set:
# ENABLE_METRICS: "false"
# ENABLE_TRACING: "false"
```

**Option B: Configure GCP credentials**
```bash
# Create a service account in your GCP project with roles:
# - Monitoring Metric Writer
# - Cloud Trace Agent  
# - Logs Writer

# Create Kubernetes secret with the service account key
kubectl create secret generic gcp-credentials \
  --from-file=key.json=path/to/your/service-account-key.json
```

#### Step 3: Deploy the application

```bash
git clone https://github.com/GoogleCloudPlatform/bank-of-anthos
cd bank-of-anthos/

kubectl apply -f ./extras/jwt/jwt-secret.yaml
kubectl apply -f ./kubernetes-manifests/
```

### 4. Docker Compose (Local Development)

⚠️ **Note**: Docker Compose deployment is not officially maintained but can be useful for quick local testing.

#### Step 1: Create Docker Compose file

```bash
git clone https://github.com/GoogleCloudPlatform/bank-of-anthos
cd bank-of-anthos/

# Create a basic docker-compose.yml (you'll need to create this based on the Kubernetes manifests)
# This requires manual conversion from Kubernetes YAML to Docker Compose format
```

### 5. VM Deployment (Monolith)

Deploy the Java monolith version to a virtual machine for legacy migration demonstrations.

#### Step 1: Prepare VM environment

This is designed for Google Compute Engine, but can be adapted for other VM platforms:

```bash
# Create a Compute Engine instance
gcloud compute instances create bank-of-anthos-monolith \
  --image-family=ubuntu-2004-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=e2-standard-4 \
  --project=${PROJECT_ID} \
  --zone=${REGION}-a \
  --tags=monolith
```

#### Step 2: Install the monolith

```bash
# SSH into the instance
gcloud compute ssh bank-of-anthos-monolith \
  --project=${PROJECT_ID} \
  --zone=${REGION}-a

# Run the installation script
curl -sSL https://raw.githubusercontent.com/prats-2311/bank-of-anthos/main/src/ledgermonolith/init/install-script.sh | sudo bash
```

See the [ledgermonolith README](/src/ledgermonolith/README.md) for detailed instructions.

## Advanced Deployment Options

### With Workload Identity (GKE)
For enhanced security on GKE:
- Follow the [Workload Identity guide](/docs/workload-identity.md)

### With Cloud SQL
Replace in-cluster databases with managed Cloud SQL:
- See [Cloud SQL instructions](/extras/cloudsql/)

### With Istio Service Mesh
Add service mesh capabilities:
- See [Istio configuration](/extras/istio/)

### With Anthos Service Mesh
For production service mesh with observability:
- Requires Workload Identity
- See [ASM documentation](/extras/asm-multicluster/)

### Multi-cluster Deployment
Deploy across multiple regions:
- See [Multi-cluster instructions](/extras/cloudsql-multicluster/)

## Verification

### Check Application Health

```bash
# Verify all pods are running
kubectl get pods

# Check service endpoints
kubectl get services

# View application logs
kubectl logs -l app=frontend
```

### Access the Application

1. **Get the frontend service IP:**
   ```bash
   kubectl get service frontend
   ```

2. **Access the web interface** at `http://EXTERNAL_IP`

3. **Test with demo users:**
   - Username: `testuser` Password: `password`
   - Username: `alice` Password: `password`
   - Username: `bob` Password: `password`

### Load Testing

The application includes a load generator:

```bash
# Check load generator logs
kubectl logs -l app=loadgenerator

# Scale load generator for more traffic
kubectl scale deployment loadgenerator --replicas=3
```

## Troubleshooting

### Common Issues

#### Pods stuck in Pending state
```bash
# Check node resources
kubectl describe nodes

# Check pod events
kubectl describe pod <pod-name>
```

#### Services not accessible
```bash
# Check service configuration
kubectl describe service frontend

# Verify endpoints
kubectl get endpoints frontend

# Check firewall rules (GKE)
gcloud compute firewall-rules list --filter="name~gke-"
```

#### Out of resources
```bash
# Scale down non-essential services
kubectl scale deployment loadgenerator --replicas=0

# Check resource requests
kubectl describe pod <pod-name> | grep -A5 -B5 resources
```

#### Images not pulling
```bash
# Check image pull secrets
kubectl get secrets

# Verify image repositories are accessible
kubectl describe pod <pod-name> | grep -A10 Events
```

### Getting Help

- Check the [troubleshooting guide](/docs/troubleshooting.md)
- Review [GitHub Issues](https://github.com/GoogleCloudPlatform/bank-of-anthos/issues)
- For development issues, see the [development guide](/docs/development.md)

## Clean Up

### Delete GKE Cluster
```bash
gcloud container clusters delete ${CLUSTER_NAME} \
  --project=${PROJECT_ID} \
  --region=${REGION}
```

### Delete from other Kubernetes clusters
```bash
kubectl delete -f ./kubernetes-manifests/
kubectl delete -f ./extras/jwt/jwt-secret.yaml
```

### Stop Skaffold development
```bash
# Press Ctrl+C in the terminal running `skaffold dev`
# Or run:
skaffold delete
```

---

## Next Steps

- **Customize the application**: See the [development guide](/docs/development.md)
- **Set up CI/CD**: Follow the [CI/CD pipeline guide](/docs/ci-cd-pipeline.md)
- **Add monitoring**: Configure [observability features](/extras/prometheus/)
- **Secure the application**: Implement [Workload Identity](/docs/workload-identity.md)

For more deployment options and advanced configurations, explore the [extras directory](/extras/).