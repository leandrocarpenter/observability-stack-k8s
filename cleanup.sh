#!/bin/bash

set -e

echo "🧹 Limpando Stack de Observabilidade..."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Perguntar confirmação
read -p "Tem certeza que deseja remover toda a stack de observabilidade? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operação cancelada."
    exit 0
fi

# Remover releases Helm
log "Removendo releases Helm..."
helm uninstall prometheus-stack -n observability || warn "Prometheus stack não encontrado"
helm uninstall jaeger -n observability || warn "Jaeger não encontrado"

# Remover aplicações de exemplo
log "Removendo aplicações de exemplo..."
kubectl delete -f examples/ || warn "Nenhuma aplicação de exemplo encontrada"

# Remover namespace (isso remove todos os recursos)
log "Removendo namespace 'observability'..."
kubectl delete namespace observability || warn "Namespace não encontrado"

echo ""
log "✅ Limpeza concluída!"
echo ""
echo -e "${YELLOW}💡 Para remover completamente o cluster Kind:${NC}"
echo "   kind delete cluster --name=observability"
echo ""