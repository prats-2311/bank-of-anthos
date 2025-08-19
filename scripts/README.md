# Scripts Directory

This directory contains helpful scripts for deploying and managing Bank of Anthos.

## Available Scripts

### `quickstart-gke.sh`
One-command deployment script for Google Kubernetes Engine (GKE).

**Usage:**
```bash
./scripts/quickstart-gke.sh [OPTIONS]
```

**Features:**
- Creates GKE cluster (Autopilot by default)
- Deploys Bank of Anthos application
- Provides access information
- Includes cleanup instructions

**Options:**
- `-p, --project PROJECT_ID` - Google Cloud project ID
- `-r, --region REGION` - GCP region (default: us-central1)
- `-c, --cluster CLUSTER_NAME` - Cluster name (default: bank-of-anthos)
- `-s, --standard` - Use standard cluster instead of Autopilot
- `-h, --help` - Show help message

**Example:**
```bash
./scripts/quickstart-gke.sh --project my-project --region us-west1
```

### `dev-setup.sh`
Local development environment setup script using Skaffold.

**Usage:**
```bash
./scripts/dev-setup.sh [OPTIONS]
```

**Features:**
- Checks prerequisites (Docker, kubectl, Skaffold)
- Validates Kubernetes connection
- Starts Skaffold development mode with hot reloading

**Options:**
- `-p, --project PROJECT_ID` - Use custom container registry
- `-h, --help` - Show help message

**Example:**
```bash
# Local development
./scripts/dev-setup.sh

# With custom registry
./scripts/dev-setup.sh --project my-project
```

## Prerequisites

### For GKE Scripts
- [Google Cloud SDK (gcloud)](https://cloud.google.com/sdk/install)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

### For Development Scripts
- [Docker](https://www.docker.com/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [Skaffold 2.9+](https://skaffold.dev/docs/install/)

## Make Targets

You can also use the provided Make targets:

```bash
make install-help    # Show installation options
make quickstart      # Run quickstart-gke.sh
make dev-setup       # Run dev-setup.sh
```

## More Information

For comprehensive installation instructions covering all deployment methods, see [INSTALL.md](../INSTALL.md).