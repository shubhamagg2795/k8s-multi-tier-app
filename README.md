# Kubernetes Multi-Tier Architecture Assignment

**NAGP 2025 Technology Band III Batch - Workshop on Kubernetes & DevOps**

## 📋 Project Overview

Multi-tier architecture on **Google Kubernetes Engine (GKE)** with:
- **API Tier**: Node.js REST API (4 pods, rolling updates)
- **Database Tier**: PostgreSQL (1 pod, Google Cloud persistent storage)
- **External Access**: Google Cloud LoadBalancer (IP: `34.58.217.53`)

## 🔗 Links

- **Repository**: https://github.com/shubhamagg2795/k8s-multi-tier-app
- **Docker Hub**: https://hub.docker.com/r/shubhamdocker413/k8s-api-tier
- **Live API**: http://34.58.217.53 (with Host header)

## 🚀 Quick Deployment

```bash
# Deploy to GKE
./deploy.sh deploy

# Or access via port-forward
kubectl port-forward svc/api-service 8080:80 -n multi-tier-app
```

## 📊 API Endpoints

**Base URL**: `34.58.217.53` (requires Host header)

```bash
# API info
curl -H "Host: api.local" http://34.58.217.53/

# Health check  
curl -H "Host: api.local" http://34.58.217.53/health

# Get all users
curl -H "Host: api.local" http://34.58.217.53/api/users

# Get user by ID
curl -H "Host: api.local" http://34.58.217.53/api/users/1

# Create user
curl -X POST -H "Host: api.local" -H "Content-Type: application/json" \
  http://34.58.217.53/api/users \
  -d '{"name":"Demo User","email":"demo@test.com","department":"Testing"}'
```

**Alternative (Port Forward):**
```bash
curl http://localhost:8080/api/users
```

## 🗄️ Database Access

```bash
# CLI access
kubectl exec -it postgres-0 -n multi-tier-app -- psql -U appuser -d appdb

# GUI access (pgAdmin/DBeaver)
kubectl port-forward postgres-0 5432:5432 -n multi-tier-app
# Connect: localhost:5432, appdb, appuser, apppass
```

## 🧪 Testing

```bash
# Test API
curl -H "Host: api.local" http://34.58.217.53/api/users

# Test pod regeneration
kubectl delete pod $(kubectl get pods -l app=api-tier -n multi-tier-app -o jsonpath='{.items[0].metadata.name}') -n multi-tier-app

# Test data persistence
kubectl delete pod postgres-0 -n multi-tier-app
```

## 📁 Structure

```
├── api/                 # Node.js application
├── k8s/                 # Kubernetes manifests  
├── deploy.sh            # Deployment script
└── README.md
```

## ✅ Requirements Met

- [x] **GKE Deployment**: 2-node Google Cloud cluster
- [x] **API tier**: 4 pods, rolling updates, Google Cloud LoadBalancer
- [x] **Database tier**: 1 pod, Google Cloud persistent storage, internal only
- [x] **ConfigMap & Secret**: External configuration and secure passwords
- [x] **Service communication**: No direct pod IPs
- [x] **Docker Hub**: Published container image
- [x] **Data persistence**: 10 users, survives pod restarts

## 🧹 Cleanup

```bash
./deploy.sh cleanup
```

---
**Deployed on Google Kubernetes Engine**
