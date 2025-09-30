#!/bin/bash

echo "Jaeger Tracing Demo"
echo "==================="

# Verificar se a aplicação está rodando
if ! kubectl get pods -n observability -l app=sample-nodejs-app --no-headers | grep -q "Running"; then
    echo "[ERROR] Node.js application not running!"
    echo "Run: ./demo-nodejs-app.sh first"
    exit 1
fi

echo "[INFO] Gerando traces na aplicação..."

# Port-forward para aplicação (em background)
kubectl port-forward -n observability svc/sample-nodejs-app-service 3001:3000 > /dev/null 2>&1 &
APP_PF_PID=$!

# Port-forward para Jaeger UI (em background)
kubectl port-forward -n observability svc/jaeger-query 16686:80 > /dev/null 2>&1 &
JAEGER_PF_PID=$!

sleep 3

echo "[INFO] Fazendo requisições para gerar traces..."

# Gerar traces com diferentes endpoints
for i in {1..5}; do
    echo "  → Requisição $i"
    curl -s http://localhost:3001/ > /dev/null
    curl -s http://localhost:3001/health > /dev/null
    curl -s http://localhost:3001/load > /dev/null
    curl -s http://localhost:3001/info > /dev/null
    sleep 1
done

echo ""
echo "[INFO] Verificando traces no Jaeger..."

# Aguardar um pouco para os traces serem processados
sleep 5

# Verificar serviços disponíveis
echo "Serviços disponíveis:"
curl -s "http://localhost:16686/api/services" | jq -r '.data[]'

echo ""
echo "Número de traces encontrados:"
TRACE_COUNT=$(curl -s "http://localhost:16686/api/traces?service=nodejs-observability-demo&limit=50" | jq '.data | length')
echo "$TRACE_COUNT traces"

echo ""
echo "================================"
echo "[INFO] Jaeger UI está acessível em:"
echo "  🔍 http://localhost:16686"
echo ""
echo "[INFO] Como visualizar os traces:"
echo "  1. Abra http://localhost:16686 no navegador"
echo "  2. Selecione o serviço: nodejs-observability-demo"
echo "  3. Clique em 'Find Traces' para ver todos os traces"
echo "  4. Clique em qualquer trace para ver detalhes"
echo ""
echo "[INFO] Tipos de traces disponíveis:"
echo "  • GET / - Requisições principais"
echo "  • GET /health - Health checks"
echo "  • GET /load - Operações com processamento pesado (com spans filhos)"
echo "  • GET /info - Informações da aplicação"
echo ""
echo "[WARN] Use Ctrl+C para parar os port-forwards quando terminar"
echo ""
echo "Pressione Enter para parar os port-forwards..."
read

# Limpar port-forwards
kill $APP_PF_PID $JAEGER_PF_PID 2>/dev/null
echo "[INFO] Port-forwards encerrados"