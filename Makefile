.PHONY: help create-cluster delete-cluster setup cleanup status logs

# Variáveis
CLUSTER_NAME = observability
NAMESPACE = observability

# Cores para output
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m # No Color

help: ## Mostrar esta mensagem de ajuda
	@echo "$(GREEN)Observability Stack - Comandos Disponíveis:$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""

create-cluster: ## Criar cluster Kind com configuração de observabilidade
	@echo "$(GREEN)Criando cluster Kind...$(NC)"
	kind create cluster --config=kind-config.yaml --name=$(CLUSTER_NAME)
	@echo "$(GREEN)Cluster criado com sucesso!$(NC)"

delete-cluster: ## Deletar cluster Kind
	@echo "$(RED)Deletando cluster Kind...$(NC)"
	kind delete cluster --name=$(CLUSTER_NAME)
	@echo "$(RED)Cluster deletado!$(NC)"

setup: ## Instalar stack de observabilidade completa
	@echo "$(GREEN)Instalando stack de observabilidade...$(NC)"
	chmod +x setup-observability.sh
	./setup-observability.sh

cleanup: ## Limpar recursos da stack de observabilidade
	@echo "$(YELLOW)Limpando recursos...$(NC)"
	chmod +x cleanup.sh
	./cleanup.sh

status: ## Verificar status dos pods
	@echo "$(GREEN)Status dos pods:$(NC)"
	kubectl get pods -n $(NAMESPACE)
	@echo ""
	@echo "$(GREEN)Services:$(NC)"
	kubectl get svc -n $(NAMESPACE)

logs: ## Mostrar logs do Prometheus
	@echo "$(GREEN)Logs do Prometheus:$(NC)"
	kubectl logs -n $(NAMESPACE) -l app.kubernetes.io/name=prometheus --tail=50

grafana-logs: ## Mostrar logs do Grafana
	@echo "$(GREEN)Logs do Grafana:$(NC)"
	kubectl logs -n $(NAMESPACE) -l app.kubernetes.io/name=grafana --tail=50

jaeger-logs: ## Mostrar logs do Jaeger
	@echo "$(GREEN)Logs do Jaeger:$(NC)"
	kubectl logs -n $(NAMESPACE) -l app.kubernetes.io/name=jaeger --tail=50

port-forward: ## Fazer port-forward para acessar aplicações localmente (alternativa)
	@echo "$(GREEN)Configurando port-forward...$(NC)"
	@echo "$(YELLOW)Grafana será acessível em http://localhost:3000$(NC)"
	@echo "$(YELLOW)Prometheus será acessível em http://localhost:9090$(NC)"
	@echo "$(YELLOW)Pressione Ctrl+C para parar$(NC)"
	kubectl port-forward -n $(NAMESPACE) svc/prometheus-stack-grafana 3000:80 &
	kubectl port-forward -n $(NAMESPACE) svc/prometheus-stack-kube-prom-prometheus 9090:9090 &
	wait

install-tools: ## Instalar ferramentas necessárias (Kind, kubectl, Helm)
	@echo "$(GREEN)Instalando ferramentas...$(NC)"
	@echo "$(YELLOW)Instalando Kind...$(NC)"
	curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
	chmod +x ./kind
	sudo mv ./kind /usr/local/bin/kind
	@echo "$(YELLOW)Instalando kubectl...$(NC)"
	curl -LO "https://dl.k8s.io/release/$$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
	chmod +x kubectl
	sudo mv kubectl /usr/local/bin/kubectl
	@echo "$(YELLOW)Instalando Helm...$(NC)"
	curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
	@echo "$(GREEN)Todas as ferramentas foram instaladas!$(NC)"

all: create-cluster setup ## Criar cluster e instalar tudo de uma vez

demo: ## Executar demo completo (criar cluster + instalar stack)
	@echo "$(GREEN)🚀 Iniciando demo completo...$(NC)"
	$(MAKE) create-cluster
	sleep 10
	$(MAKE) setup
	@echo ""
	@echo "$(GREEN)🎉 Demo pronto!$(NC)"
	@echo "$(YELLOW)Acesse:$(NC)"
	@echo "  • Grafana: http://localhost:3000 (admin/admin)"
	@echo "  • Prometheus: http://localhost:9090"
	@echo "  • Jaeger: http://localhost:16686"
	@echo ""