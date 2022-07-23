variables:
	@echo "=> Checking environment variables..."
	@if [[ -z "$(RESOURCE_GROUP)" || -z "$(CLUSTER_NAME)" || -z "$(TENANT_ID)" ]]; then \
		echo "Missing required environment variables"; \
		exit 1; \
	fi

deploy:
	@echo '=> Deploying platform...'
	@az deployment sub create --name 'Microsoft.Bicep.Resources' --location 'Norway East' --template-file './region.bicep'

validate:
	@echo '=> Validating platform...'
	@az deployment sub what-if --name 'Microsoft.Bicep.Resources' --location 'Norway East' --template-file './region.bicep'

connection:
	@echo '=> Checking coonection...'

deploy-autoscaler:
	@helm repo add kedacore https://kedacore.github.io/charts
	@helm repo update
	@kubectl create namespace keda
	@helm install keda kedacore/keda --namespace keda

destroy-identity:



destroy-autoscaler:



bootstrap:
	@echo '=> Bootstrapping platform...'
	@shell ./scripts/bootstrap.sh

destroy:
	@echo '=> Destroying platform...'
	@cat ../config/platform.local.json | jq -r '.endpoints.resourceGroup' | xargs -rtL1 az group delete --yes --name
	@cat ../config/platform.local.json | jq -r '.clusters[].resourceGroup' | xargs -rtL1 az group delete --yes --name
	@cat ../config/platform.local.json | jq -r '.services.resourceGroup' | xargs -rtL1 az group delete --yes --name
	@cat ../config/platform.local.json | jq -r '.zones.resourceGroup' | xargs -rtL1 az group delete --yes --name
	@-make purge

purge:
	@echo '=> Purging vaults...'
	@az keyvault list-deleted --query '[].name' -o tsv | xargs -rtL1 az keyvault purge --name
