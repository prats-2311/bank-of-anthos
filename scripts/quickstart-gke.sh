#!/bin/bash

# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Quick start script for deploying Bank of Anthos to GKE
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
REGION="us-central1"
CLUSTER_NAME="bank-of-anthos"
MACHINE_TYPE="e2-standard-4"
NUM_NODES="4"
USE_AUTOPILOT="true"

# Functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if gcloud is installed
    if ! command -v gcloud &> /dev/null; then
        log_error "gcloud CLI is not installed. Please install the Google Cloud SDK."
        exit 1
    fi
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed. Please install kubectl."
        exit 1
    fi
    
    # Check if user is authenticated
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        log_error "No active gcloud authentication found. Please run 'gcloud auth login'."
        exit 1
    fi
    
    log_success "Prerequisites check passed!"
}

get_project_id() {
    if [[ -z "${PROJECT_ID:-}" ]]; then
        PROJECT_ID=$(gcloud config get-value project 2>/dev/null || echo "")
        if [[ -z "$PROJECT_ID" ]]; then
            log_error "No Google Cloud project set. Please set PROJECT_ID environment variable or run 'gcloud config set project YOUR_PROJECT_ID'"
            exit 1
        fi
    fi
    log_info "Using project: $PROJECT_ID"
}

enable_apis() {
    log_info "Enabling required APIs..."
    gcloud services enable container.googleapis.com --project="$PROJECT_ID"
    log_success "APIs enabled!"
}

create_cluster() {
    log_info "Creating GKE cluster '$CLUSTER_NAME' in region '$REGION'..."
    
    if [[ "$USE_AUTOPILOT" == "true" ]]; then
        log_info "Creating Autopilot cluster (recommended)..."
        gcloud container clusters create-auto "$CLUSTER_NAME" \
            --project="$PROJECT_ID" \
            --region="$REGION"
    else
        log_info "Creating standard cluster..."
        gcloud container clusters create "$CLUSTER_NAME" \
            --machine-type="$MACHINE_TYPE" \
            --num-nodes="$NUM_NODES" \
            --project="$PROJECT_ID" \
            --zone="$REGION-a"
    fi
    
    log_success "Cluster created!"
}

get_credentials() {
    log_info "Getting cluster credentials..."
    gcloud container clusters get-credentials "$CLUSTER_NAME" \
        --project="$PROJECT_ID" \
        --region="$REGION"
    log_success "Credentials configured!"
}

clone_repository() {
    if [[ ! -d "bank-of-anthos" ]]; then
        log_info "Cloning Bank of Anthos repository..."
        git clone https://github.com/GoogleCloudPlatform/bank-of-anthos
        log_success "Repository cloned!"
    else
        log_info "Repository already exists, using existing copy..."
    fi
}

deploy_application() {
    log_info "Deploying Bank of Anthos application..."
    cd bank-of-anthos
    
    # Deploy JWT secret
    kubectl apply -f ./extras/jwt/jwt-secret.yaml
    
    # Deploy application manifests
    kubectl apply -f ./kubernetes-manifests/
    
    log_success "Application deployed!"
}

wait_for_deployment() {
    log_info "Waiting for pods to be ready... (this may take a few minutes)"
    
    # Wait for all pods to be running
    kubectl wait --for=condition=Ready pod --all --timeout=600s
    
    log_success "All pods are ready!"
}

show_access_info() {
    log_info "Getting frontend service information..."
    
    # Wait for external IP to be assigned
    log_info "Waiting for external IP to be assigned..."
    for i in {1..30}; do
        EXTERNAL_IP=$(kubectl get service frontend -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
        if [[ -n "$EXTERNAL_IP" ]] && [[ "$EXTERNAL_IP" != "<pending>" ]]; then
            break
        fi
        sleep 10
        echo -n "."
    done
    echo
    
    if [[ -n "$EXTERNAL_IP" ]] && [[ "$EXTERNAL_IP" != "<pending>" ]]; then
        log_success "🎉 Bank of Anthos is ready!"
        echo
        echo "📱 Access the application at: http://$EXTERNAL_IP"
        echo
        echo "👤 Demo users:"
        echo "   Username: testuser  Password: password"
        echo "   Username: alice     Password: password"
        echo "   Username: bob       Password: password"
        echo
    else
        log_warning "External IP not yet assigned. You can check the status with:"
        echo "   kubectl get service frontend"
    fi
}

show_cleanup_info() {
    echo
    log_info "📋 To clean up resources when done:"
    echo "   gcloud container clusters delete $CLUSTER_NAME --project=$PROJECT_ID --region=$REGION"
    echo
    log_info "📚 For more installation options, see INSTALL.md"
}

print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -p, --project PROJECT_ID    Google Cloud project ID"
    echo "  -r, --region REGION         GCP region (default: us-central1)"
    echo "  -c, --cluster CLUSTER_NAME  Cluster name (default: bank-of-anthos)"
    echo "  -s, --standard              Use standard cluster instead of Autopilot"
    echo "  -h, --help                  Show this help message"
    echo
    echo "Environment variables:"
    echo "  PROJECT_ID                  Google Cloud project ID"
    echo
    echo "Example:"
    echo "  $0 --project my-project --region us-west1"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--project)
            PROJECT_ID="$2"
            shift 2
            ;;
        -r|--region)
            REGION="$2"
            shift 2
            ;;
        -c|--cluster)
            CLUSTER_NAME="$2"
            shift 2
            ;;
        -s|--standard)
            USE_AUTOPILOT="false"
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

# Main execution
main() {
    echo "🏦 Bank of Anthos - Quick Start Deployment Script"
    echo "=================================================="
    echo
    
    check_prerequisites
    get_project_id
    enable_apis
    create_cluster
    get_credentials
    clone_repository
    deploy_application
    wait_for_deployment
    show_access_info
    show_cleanup_info
    
    log_success "🎉 Deployment completed successfully!"
}

# Run main function
main "$@"