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

# Local development setup script for Bank of Anthos
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
    log_info "Checking prerequisites for local development..."
    
    # Check if Docker is installed and running
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker Desktop or Docker Engine."
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        log_error "Docker is not running. Please start Docker Desktop or Docker daemon."
        exit 1
    fi
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed. Please install kubectl."
        exit 1
    fi
    
    # Check if Skaffold is installed
    if ! command -v skaffold &> /dev/null; then
        log_error "Skaffold is not installed. Please install Skaffold from https://skaffold.dev/docs/install/"
        exit 1
    fi
    
    # Check Skaffold version
    SKAFFOLD_VERSION=$(skaffold version --output=json | grep -o '"version":"[^"]*' | cut -d'"' -f4 | cut -d'v' -f2)
    REQUIRED_VERSION="2.9.0"
    if ! printf '%s\n%s\n' "$REQUIRED_VERSION" "$SKAFFOLD_VERSION" | sort -V -C; then
        log_warning "Skaffold version $SKAFFOLD_VERSION is older than recommended $REQUIRED_VERSION. Please update Skaffold."
    fi
    
    log_success "Prerequisites check passed!"
}

check_kubernetes_context() {
    log_info "Checking Kubernetes context..."
    
    # Get current context
    CURRENT_CONTEXT=$(kubectl config current-context 2>/dev/null || echo "none")
    
    if [[ "$CURRENT_CONTEXT" == "none" ]]; then
        log_error "No Kubernetes context found. Please configure kubectl to connect to a cluster."
        log_info "For local development, you can use:"
        log_info "  - Docker Desktop (enable Kubernetes in settings)"
        log_info "  - minikube (run 'minikube start')"
        log_info "  - kind (run 'kind create cluster')"
        exit 1
    fi
    
    log_info "Using Kubernetes context: $CURRENT_CONTEXT"
    
    # Test connection
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster. Please check your connection."
        exit 1
    fi
    
    log_success "Kubernetes connection verified!"
}

setup_development_environment() {
    log_info "Setting up development environment..."
    
    # Check if we're in the bank-of-anthos directory
    if [[ ! -f "skaffold.yaml" ]]; then
        log_error "skaffold.yaml not found. Please run this script from the bank-of-anthos root directory."
        exit 1
    fi
    
    # Create any necessary local directories
    mkdir -p .local
    
    log_success "Development environment ready!"
}

start_development() {
    log_info "Starting Skaffold development environment..."
    log_info "This will build and deploy all services with hot reloading enabled."
    log_warning "Press Ctrl+C to stop the development environment."
    echo
    
    # Start Skaffold in development mode
    if [[ -n "${PROJECT_ID:-}" ]]; then
        log_info "Using custom container registry: gcr.io/$PROJECT_ID"
        exec skaffold dev --default-repo="gcr.io/$PROJECT_ID"
    else
        log_info "Using local development setup"
        exec skaffold dev
    fi
}

print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -p, --project PROJECT_ID    Use custom container registry (gcr.io/PROJECT_ID)"
    echo "  -h, --help                  Show this help message"
    echo
    echo "Environment variables:"
    echo "  PROJECT_ID                  Google Cloud project ID for custom registry"
    echo
    echo "Examples:"
    echo "  $0                          # Local development"
    echo "  $0 --project my-project     # Use custom registry"
    echo
    echo "This script will start a local development environment using Skaffold."
    echo "All services will be built and deployed with hot reloading enabled."
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--project)
            PROJECT_ID="$2"
            shift 2
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
    echo "🏦 Bank of Anthos - Local Development Setup"
    echo "============================================"
    echo
    
    check_prerequisites
    check_kubernetes_context
    setup_development_environment
    
    echo
    log_info "🚀 Ready to start development!"
    echo
    log_info "Once running, you can access the application at:"
    log_info "  kubectl port-forward service/frontend 8080:80"
    log_info "  Then visit: http://localhost:8080"
    echo
    
    read -p "Start development environment now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        start_development
    else
        log_info "To start later, run: skaffold dev"
        log_success "Setup complete!"
    fi
}

# Run main function
main "$@"