.PHONY: help create-cluster delete-cluster setup cleanup status logs

# Variáveis
CLUSTER_NAME = observability
NAMESPACE = observability

# Colors for output formatting
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m # No Color

help: ## Show available commands
	@echo "$(GREEN)Observability Stack - Available Commands:$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""

create-cluster: ## Create Kind cluster with observability configuration
	@echo "$(GREEN)Creating Kind cluster...$(NC)"
	kind create cluster --config=kind-config.yaml --name=$(CLUSTER_NAME)
	@echo "$(GREEN)Cluster created successfully$(NC)"

delete-cluster: ## Delete Kind cluster
	@echo "$(RED)Deleting Kind cluster...$(NC)"
	kind delete cluster --name=$(CLUSTER_NAME)
	@echo "$(RED)Cluster deleted$(NC)"

setup: ## Install complete observability stack
	@echo "$(GREEN)Installing observability stack...$(NC)"
	chmod +x setup-observability.sh
	./setup-observability.sh

cleanup: ## Clean observability stack resources
	@echo "$(YELLOW)Cleaning up resources...$(NC)"
	chmod +x cleanup.sh
	./cleanup.sh

status: ## Check comprehensive status
	@echo "$(GREEN)Running comprehensive status check...$(NC)"
	chmod +x status-check.sh
	./status-check.sh

quick-status: ## Quick pod and service status
	@echo "$(GREEN)Pod Status:$(NC)"
	kubectl get pods -n $(NAMESPACE)
	@echo ""
	@echo "$(GREEN)Services:$(NC)"
	kubectl get svc -n $(NAMESPACE)

logs: ## Show Prometheus logs
	@echo "$(GREEN)Prometheus Logs:$(NC)"
	kubectl logs -n $(NAMESPACE) -l app.kubernetes.io/name=prometheus --tail=50

grafana-logs: ## Show Grafana logs
	@echo "$(GREEN)Grafana Logs:$(NC)"
	kubectl logs -n $(NAMESPACE) -l app.kubernetes.io/name=grafana --tail=50

jaeger-logs: ## Show Jaeger logs
	@echo "$(GREEN)Jaeger Logs:$(NC)"
	kubectl logs -n $(NAMESPACE) -l app.kubernetes.io/name=jaeger --tail=50

port-forward: ## Set up port-forward for local access (alternative method)
	@echo "$(GREEN)Setting up port-forward...$(NC)"
	@echo "$(YELLOW)Grafana will be accessible at http://localhost:3000$(NC)"
	@echo "$(YELLOW)Prometheus will be accessible at http://localhost:9090$(NC)"
	@echo "$(YELLOW)Press Ctrl+C to stop$(NC)"
	kubectl port-forward -n $(NAMESPACE) svc/prometheus-stack-grafana 3000:80 &
	kubectl port-forward -n $(NAMESPACE) svc/prometheus-stack-kube-prom-prometheus 9090:9090 &
	wait

install-tools: ## Install required tools (Kind, kubectl, Helm)
	@echo "$(GREEN)Installing tools...$(NC)"
	@echo "$(YELLOW)Installing Kind...$(NC)"
	curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
	chmod +x ./kind
	sudo mv ./kind /usr/local/bin/kind
	@echo "$(YELLOW)Installing kubectl...$(NC)"
	curl -LO "https://dl.k8s.io/release/$$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
	chmod +x kubectl
	sudo mv kubectl /usr/local/bin/kubectl
	@echo "$(YELLOW)Installing Helm...$(NC)"
	curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
	@echo "$(GREEN)All tools have been installed$(NC)"

all: create-cluster setup ## Create cluster and install everything at once

demo: ## Run complete demo (create cluster + install stack)
	@echo "$(GREEN)Starting complete demo...$(NC)"
	$(MAKE) create-cluster
	sleep 10
	$(MAKE) setup
	@echo ""
	@echo "$(GREEN)Demo ready$(NC)"
	@echo "$(YELLOW)Access:$(NC)"
	@echo "  • Grafana: http://localhost:3000 (admin/admin)"
	@echo "  • Prometheus: http://localhost:9090"
	@echo "  • Jaeger: http://localhost:16686"
	@echo ""

fast-setup: ## Fast setup (skip repo updates if possible)
	@echo "$(GREEN)Running optimized setup...$(NC)"
	chmod +x setup-observability.sh
	./setup-observability.sh

force-setup: ## Force setup with repository updates
	@echo "$(GREEN)Running setup with forced updates...$(NC)"
	chmod +x setup-observability.sh
	FORCE_UPDATE=true ./setup-observability.sh

generate-traces: ## Generate additional traces for testing
	@echo "$(GREEN)Generating additional traces...$(NC)"
	chmod +x generate-traces.sh
	./generate-traces.sh

demo: ## Complete demo (cluster + stack + auto-tracing)
	@echo "$(GREEN)Starting complete demo with auto-tracing...$(NC)"
	$(MAKE) create-cluster
	sleep 10
	$(MAKE) setup
	@echo ""
	@echo "$(GREEN)Demo ready with active traces!$(NC)"
	@echo "$(YELLOW)Access:$(NC)"
	@echo "  • Grafana: http://localhost:3000 (admin/admin)"
	@echo "  • Prometheus: http://localhost:9090"
	@echo "  • Jaeger: http://localhost:16686 ← Traces active!"
	@echo "  • Demo App: http://localhost:3001"
	@echo ""