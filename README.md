# Kubernetes Observability Stack

Complete observability stack implementation for local Kubernetes environments using Kind. This project provides a comprehensive monitoring, tracing, and alerting solution with industry-standard tools.

## Technology Stack

- **Kind** - Local Kubernetes cluster management
- **Prometheus** - Metrics collection and time-series database
- **Grafana** - Data visualization and dashboard platform
- **Jaeger** - Distributed tracing system
- **Alertmanager** - Alert handling and notification routing
- **Node Exporter** - System and hardware metrics collection
- **Helm** - Kubernetes package management

## Prerequisites

- Docker Engine
- Kind (Kubernetes in Docker)
- kubectl CLI
- Helm package manager

## Prerequisites Installation

### Instalando Kind
```bash
# Linux
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Verificar instalação
kind --version
```

### Instalando kubectl
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/kubectl

# Verificar instalação
kubectl version --client
```

### Instalando Helm
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verificar instalação
helm version
```

## 🚀 One-Command Setup

### Complete Stack with Auto-Demo
```bash
# Create cluster, install everything, and demo tracing automatically
./setup-observability.sh
```

**That's it!** 🎉 This single command will:
- ✅ Create Kind cluster with custom configuration
- ✅ Install complete observability stack (Prometheus, Grafana, Jaeger)
- ✅ Deploy Node.js demo application with distributed tracing
- ✅ Generate sample traces automatically
- ✅ Start all port-forwards for immediate access

### Access Everything (Ready After Setup)

- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **Jaeger**: http://localhost:16686 **← Traces already active!**
- **Demo App**: http://localhost:3001
- **Alertmanager**: http://localhost:9093

### Generate More Traces (Optional)

```bash
# Generate additional traces for testing
./generate-traces.sh
```

### Alternative Methods
```bash
# Comprehensive status check
./status-check.sh

# Or using Make
make status
```

### 6. Cleanup Environment

```bash
# Remove cluster
kind delete cluster --name=observability
```

## Performance Optimizations

The setup script includes several optimizations:

- **Repository caching** - Skips Helm repo updates if repositories exist
- **Installation checking** - Skips installation if services are already running
- **Reduced timeouts** - Faster failure detection (300s vs 600s)
- **Memory storage** - Jaeger uses memory instead of Cassandra for faster startup
- **Atomic operations** - Automatic rollback on installation failures

Use `FORCE_UPDATE=true` environment variable to force repository updates when needed.

## Included Dashboards

- **Kubernetes Cluster Overview**
- **Node Exporter System Metrics**
- **Prometheus Internal Stats**
- **Jaeger Tracing Analysis**

## Monitoring Coverage

This implementation provides:
- System metrics (CPU, memory, disk, network)
- Application performance metrics
- Distributed tracing capabilities
- Configurable alerting rules
- Centralized log aggregation

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.