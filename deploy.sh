#!/bin/bash

# Kubernetes Multi-Tier Application Deployment Script
# NAGP 2025 Assignment

set -e

# Configuration
NAMESPACE="multi-tier-app"
DOCKER_IMAGE="shubhamdocker413/k8s-api-tier:latest"  # UPDATE THIS

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl not found. Please install kubectl."
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        log_error "docker not found. Please install Docker."
        exit 1
    fi
    
    # Check if kubectl can connect to cluster
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster. Please check your kubectl configuration."
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Build and push Docker image
build_and_push() {
    log_info "Building Docker image..."
    
    if [ ! -f "api/Dockerfile" ]; then
        log_error "Dockerfile not found in api/ directory"
        exit 1
    fi
    
    docker build -t $DOCKER_IMAGE ./api
    
    log_info "Pushing Docker image to registry..."
    docker push $DOCKER_IMAGE
    
    log_success "Docker image built and pushed successfully"
}

# Deploy to Kubernetes
deploy_to_k8s() {
    log_info "Deploying to Kubernetes..."
    
    # Create namespace
    log_info "Creating namespace..."
    kubectl apply -f k8s/namespace.yaml
    
    # Deploy ConfigMap and Secret
    log_info "Deploying ConfigMap and Secret..."
    kubectl apply -f k8s/configmap.yaml
    kubectl apply -f k8s/secret.yaml
    
    # Deploy database components
    log_info "Deploying database components..."
    kubectl apply -f k8s/database/
    
    # Wait for database to be ready
    log_info "Waiting for database to be ready..."
    kubectl wait --for=condition=ready pod -l app=postgres -n $NAMESPACE --timeout=300s
    
    # Deploy API components
    log_info "Deploying API components..."
    kubectl apply -f k8s/api/
    
    # Wait for API deployment to be ready
    log_info "Waiting for API deployment to be ready..."
    kubectl wait --for=condition=available deployment/api-deployment -n $NAMESPACE --timeout=300s
    
    # Deploy Ingress
    log_info "Deploying Ingress..."
    kubectl apply -f k8s/ingress.yaml
    
    log_success "Deployment completed successfully"
}

# Verify deployment
verify_deployment() {
    log_info "Verifying deployment..."
    
    echo ""
    log_info "Checking pods status:"
    kubectl get pods -n $NAMESPACE
    
    echo ""
    log_info "Checking services:"
    kubectl get svc -n $NAMESPACE
    
    echo ""
    log_info "Checking ingress:"
    kubectl get ingress -n $NAMESPACE
    
    echo ""
    log_info "Checking persistent volumes:"
    kubectl get pv,pvc -n $NAMESPACE
}

# Test deployment
test_deployment() {
    log_info "Running deployment tests..."
    
    # Test 1: API functionality
    log_info "Test 1: Testing API endpoints..."
    kubectl port-forward svc/api-service 8080:80 -n $NAMESPACE &
    PF_PID=$!
    sleep 5
    
    if curl -s http://localhost:8080/health | grep -q "healthy"; then
        log_success "Health endpoint test passed"
    else
        log_error "Health endpoint test failed"
    fi
    
    if curl -s http://localhost:8080/api/users | grep -q "success"; then
        log_success "Users API test passed"
    else
        log_error "Users API test failed"
    fi
    
    kill $PF_PID 2>/dev/null || true
    
    # Test 2: Pod regeneration
    log_info "Test 2: Testing pod regeneration..."
    kubectl delete pod -l app=api-tier -n $NAMESPACE
    sleep 10
    kubectl wait --for=condition=ready pod -l app=api-tier -n $NAMESPACE --timeout=60s
    log_success "API pod regeneration test passed"
    
    # Test 3: Database persistence
    log_info "Test 3: Testing database persistence..."
    kubectl delete pod -l app=postgres -n $NAMESPACE
    sleep 15
    kubectl wait --for=condition=ready pod -l app=postgres -n $NAMESPACE --timeout=120s
    
    DB_POD=$(kubectl get pods -n $NAMESPACE -l app=postgres -o jsonpath='{.items[0].metadata.name}')
    USER_COUNT=$(kubectl exec -n $NAMESPACE $DB_POD -- psql -U appuser -d appdb -t -c "SELECT COUNT(*) FROM users;" | tr -d ' \n')
    if [ "$USER_COUNT" -ge "10" ]; then
        log_success "Database persistence test passed (found $USER_COUNT users)"
    else
        log_error "Database persistence test failed (found $USER_COUNT users)"
    fi
    
    log_success "All tests completed"
}

# Show access information
show_access_info() {
    echo ""
    log_info "=============================================="
    log_info "Deployment Summary"
    log_info "=============================================="
    echo ""
    
    log_info "Application URLs:"
    echo "  - Main API: http://api.local/"
    echo "  - Users API: http://api.local/api/users"
    echo "  - Health Check: http://api.local/health"
    echo ""
    
    log_info "To access the application:"
    echo "  1. Add to /etc/hosts (Linux/Mac):"
    echo "     \$(minikube ip) api.local"
    echo "  2. Or use port-forward:"
    echo "     kubectl port-forward svc/api-service 8080:80 -n $NAMESPACE"
    echo "     Then access: http://localhost:8080"
    echo ""
    
    log_success "Deployment completed successfully!"
}

# Cleanup function
cleanup() {
    log_warning "Cleaning up deployment..."
    kubectl delete namespace $NAMESPACE --ignore-not-found=true
    log_success "Cleanup completed"
}

# Main execution
main() {
    case "${1:-deploy}" in
        "build")
            check_prerequisites
            build_and_push
            ;;
        "deploy")
            check_prerequisites
            deploy_to_k8s
            verify_deployment
            show_access_info
            ;;
        "test")
            test_deployment
            ;;
        "cleanup")
            cleanup
            ;;
        "help")
            echo "Usage: $0 [build|deploy|test|cleanup|help]"
            echo ""
            echo "Commands:"
            echo "  build   - Build and push Docker image"
            echo "  deploy  - Deploy application to Kubernetes (default)"
            echo "  test    - Run deployment tests"
            echo "  cleanup - Remove all deployed resources"
            echo "  help    - Show this help message"
            ;;
        *)
            log_error "Unknown command: $1"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Execute main function with all arguments
main "$@"