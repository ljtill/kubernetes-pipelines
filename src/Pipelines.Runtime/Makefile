ifndef NAMESPACE
  $(error "NAMESPACE is not set")
endif

ifndef RUNTIME_NAME
  $(error "RUNTIME_NAME is not set")
endif

ifndef REGISTRY_NAME
  $(error "REGISTRY_NAME is not set")
endif

login:
	@echo '=> Authenticating session...'
	@az acr login --name $(REGISTRY_NAME)

deploy:
	@echo "=> Deploying runtime..."
	@kubectl create namespace $(NAMESPACE)
	@func kubernetes deploy --name $(RUNTIME_NAME) --image-name runtime/$(RUNTIME_NAME) --registry $(REGISTRY_NAME).azurecr.io/runtime --min-replicas 1 --namespace $(NAMESPACE) --write-config
	@kubectl create serviceaccount $(RUNTIME_NAME)-host -n $(NAMESPACE)
	@kubectl create clusterrolebinding $(RUNTIME_NAME) --clusterrole=cluster-admin --serviceaccount=$(NAMESPACE):$(RUNTIME_NAME)-host

destroy:
	@echo "=> Destroying runtime..."
	@kubectl delete clusterrolebinding $(RUNTIME_NAME) --ignore-not-found=true
	@kubectl delete serviceaccount $(RUNTIME_NAME)-host -n $(NAMESPACE) --ignore-not-found=true
	@func kubernetes delete --name $(RUNTIME_NAME) --image-name runtime/$(RUNTIME_NAME) --registry $(REGISTRY_NAME).azurecr.io/runtime --namespace $(NAMESPACE)
	@kubectl delete namespace $(NAMESPACE)
