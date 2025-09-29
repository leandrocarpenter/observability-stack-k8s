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

## Usage Guide

### 1. Create Local Kubernetes Cluster
```bash
# Criar cluster com configuração personalizada
kind create cluster --config=kind-config.yaml --name=observability

# Verificar se o cluster está funcionando
kubectl cluster-info --context kind-observability
```

### 2. Deploy Observability Stack
```bash
# Execute installation script
./setup-observability.sh
```

### 3. Access Applications

- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **Jaeger**: http://localhost:16686
- **Alertmanager**: http://localhost:9093

### 4. Cleanup Environment
```bash
# Remove cluster
kind delete cluster --name=observability
```

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