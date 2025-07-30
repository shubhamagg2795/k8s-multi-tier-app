Kubernetes Multi-Tier Architecture - NAGP 2025 Assignment

# Kubernetes Multi-Tier Architecture Assignment

**NAGP 2025 Technology Band III Batch - Workshop on Kubernetes & DevOps**

## 📋 Project Overview

Multi-tier architecture on Kubernetes with:
- **API Tier**: Node.js REST API (4 pods, rolling updates)
- **Database Tier**: PostgreSQL (1 pod, persistent storage)
- **External Access**: Nginx Ingress

## 🔗 Links

- **Repository**: https://github.com/your-username/k8s-multi-tier-app
- **Docker Hub**: https://hub.docker.com/r/shubhamdocker413/k8s-api-tier
- **API URL**: http://api.local/api/users

## 🚀 Quick Deployment

```bash
# Deploy
chmod +x deploy.sh
./deploy.sh deploy

# Access via port-forward
kubectl port-forward svc/api-service 8080:80 -n multi-tier-app

# Or via ingress
echo "$(minikube ip) api.local" >> /etc/hosts
```

## 📊 API Endpoints

- `GET http://localhost:8080/` - API info
- `GET http://localhost:8080/health` - Health check
- `GET http://localhost:8080/api/users` - Get all users
- `GET http://localhost:8080/api/users/:id` - Get user by ID
- `POST http://localhost:8080/api/users` - Create user

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
curl http://localhost:8080/api/users

# Test pod regeneration
kubectl delete pod $(kubectl get pods -l app=api-tier -n multi-tier-app -o jsonpath='{.items[0].metadata.name}') -n multi-tier-app

# Test data persistence
kubectl delete pod postgres-0 -n multi-tier-app
# Wait for restart, then verify data still exists
curl http://localhost:8080/api/users
```

## 📁 Structure

```
├── api/                 # Node.js application
│   ├── server.js
│   ├── package.json
│   └── Dockerfile
├── k8s/                 # Kubernetes manifests
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── ingress.yaml
│   ├── database/
│   └── api/
├── deploy.sh            # Deployment script
└── README.md
```

## ✅ Requirements Met

- [x] API tier: 4 pods, rolling updates, external access
- [x] Database tier: 1 pod, persistent storage, internal only
- [x] ConfigMap for database configuration
- [x] Secret for database password
- [x] Service-based communication
- [x] Docker image on Docker Hub
- [x] 10 users in database

## 🧹 Cleanup

```bash
./deploy.sh cleanup
```

---

**NAGP 2025 Student** | **Kubernetes & DevOps Assignment**