variables:
	@echo "=> Checking environment variables..."
	@if [[ -z "$(NAMESPACE)" || -z "$(RUNTIME_NAME)" || -z "$(REGISTRY_NAME)" ]]; then \
		$(error "Missing required environment variables"); \
	fi

login: variables
	@echo '=> Authenticating session...'
	@az acr login --name $(REGISTRY_NAME)

deploy: variables
	@echo "=> Deploying runtime..."
	@kubectl create namespace $(NAMESPACE)
	@func kubernetes deploy --name $(RUNTIME_NAME) --image-name runtime/$(RUNTIME_NAME) --registry $(REGISTRY_NAME).azurecr.io/runtime --min-replicas 1 --namespace $(NAMESPACE) --write-config
	@kubectl create serviceaccount $(RUNTIME_NAME)-host -n $(NAMESPACE)
	@kubectl create clusterrolebinding $(RUNTIME_NAME) --clusterrole=cluster-admin --serviceaccount=$(NAMESPACE):$(RUNTIME_NAME)-host

destroy: variable
	@echo "=> Destroying runtime..."
	@kubectl delete clusterrolebinding $(RUNTIME_NAME) --ignore-not-found=true
	@kubectl delete serviceaccount $(RUNTIME_NAME)-host -n $(NAMESPACE) --ignore-not-found=true
	@func kubernetes delete --name $(RUNTIME_NAME) --image-name runtime/$(RUNTIME_NAME) --registry $(REGISTRY_NAME).azurecr.io/runtime --namespace $(NAMESPACE)
	@kubectl delete namespace $(NAMESPACE)
