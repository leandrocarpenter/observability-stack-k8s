#!/bin/bash

set -e

echo "🚀 Configurando Stack de Observabilidade no Kubernetes..."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log colorido
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar se o cluster Kind está rodando
if ! kubectl cluster-info --context kind-observability &> /dev/null; then
    error "Cluster Kind 'observability' não encontrado!"
    echo "Execute: kind create cluster --config=kind-config.yaml --name=observability"
    exit 1
fi

log "Cluster Kind encontrado ✅"

# Adicionar repositórios Helm
log "Adicionando repositórios Helm..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm repo update

# Criar namespace para observabilidade
log "Criando namespace 'observability'..."
kubectl create namespace observability --dry-run=client -o yaml | kubectl apply -f -

# Instalar Prometheus Stack (inclui Prometheus, Grafana, Alertmanager)
log "Instalando Prometheus Stack..."
helm upgrade --install prometheus-stack prometheus-community/kube-prometheus-stack \
    --namespace observability \
    --set prometheus.service.type=NodePort \
    --set prometheus.service.nodePort=30900 \
    --set grafana.service.type=NodePort \
    --set grafana.service.nodePort=30300 \
    --set alertmanager.service.type=NodePort \
    --set alertmanager.service.nodePort=30903 \
    --set grafana.adminPassword=admin \
    --wait --timeout=600s

# Instalar Jaeger
log "Instalando Jaeger..."
helm upgrade --install jaeger jaegertracing/jaeger \
    --namespace observability \
    --set query.service.type=NodePort \
    --set query.service.nodePort=31686 \
    --wait --timeout=300s

# Aguardar todos os pods ficarem prontos
log "Aguardando todos os pods ficarem prontos..."
kubectl wait --for=condition=ready pod --all -n observability --timeout=600s

# Aplicar dashboards customizados
log "Aplicando dashboards customizados..."
kubectl apply -f dashboards/ -n observability || warn "Nenhum dashboard customizado encontrado"

# Aplicar aplicação de exemplo para demonstração
log "Instalando aplicação de exemplo..."
kubectl apply -f examples/ || warn "Nenhuma aplicação de exemplo encontrada"

echo ""
log "🎉 Stack de Observabilidade instalada com sucesso!"
echo ""
echo -e "${BLUE}📊 Acesse as aplicações:${NC}"
echo -e "  • Grafana:      ${GREEN}http://localhost:3000${NC} (admin/admin)"
echo -e "  • Prometheus:   ${GREEN}http://localhost:9090${NC}"
echo -e "  • Jaeger:       ${GREEN}http://localhost:16686${NC}"
echo -e "  • Alertmanager: ${GREEN}http://localhost:9093${NC}"
echo ""
echo -e "${YELLOW}💡 Dicas:${NC}"
echo "  • Use 'kubectl get pods -n observability' para verificar o status"
echo "  • Use 'kubectl logs -f -n observability <pod-name>' para ver logs"
echo "  • Use './cleanup.sh' para remover tudo"
echo ""