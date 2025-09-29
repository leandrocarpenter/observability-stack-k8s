# Observability Stack no Kubernetes Local

Este projeto demonstra como configurar uma stack completa de observabilidade em um cluster Kubernetes local usando Kind, incluindo Prometheus, Grafana, Jaeger e outras ferramentas essenciais.

## 🛠️ Tecnologias Utilizadas

- **Kind** - Kubernetes local
- **Prometheus** - Coleta de métricas
- **Grafana** - Visualização de dados
- **Jaeger** - Distributed tracing
- **Alertmanager** - Gerenciamento de alertas
- **Node Exporter** - Métricas do sistema
- **Helm** - Gerenciamento de pacotes Kubernetes

## 📋 Pré-requisitos

- Docker
- Kind
- kubectl
- Helm

## 🚀 Instalação dos Pré-requisitos

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

## 🔧 Como usar

### 1. Criar o cluster Kubernetes local
```bash
# Criar cluster com configuração personalizada
kind create cluster --config=kind-config.yaml --name=observability

# Verificar se o cluster está funcionando
kubectl cluster-info --context kind-observability
```

### 2. Instalar a stack de observabilidade
```bash
# Executar script de instalação
./setup-observability.sh
```

### 3. Acessar as aplicações

- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090  
- **Jaeger**: http://localhost:16686
- **Alertmanager**: http://localhost:9093

### 4. Limpar ambiente
```bash
# Remover cluster
kind delete cluster --name=observability
```

## 📊 Dashboards Inclusos

- **Kubernetes Cluster Overview**
- **Node Exporter Full**
- **Prometheus Stats**
- **Jaeger Tracing**

## 🔍 Monitoramento

O projeto inclui:
- ✅ Métricas de sistema (CPU, memória, disco, rede)
- ✅ Métricas de aplicação
- ✅ Distributed tracing
- ✅ Alertas configurados
- ✅ Logs centralizados

## 🤝 Contribuindo

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)  
5. Abra um Pull Request

## 📝 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

⭐️ **Se este projeto foi útil para você, considere dar uma estrela!**