variables:
	ifndef RESOURCE_GROUP
	  $(error "Environment variable RESOURCE_GROUP is not set")
	endif

	ifndef CLUSTER_NAME
	  $(error "Environment variable CLUSTER_NAME is not set")
	endif

	ifndef TENANT_ID
	  $(error "Environment variable TENANT_ID is not set")
	endif

deploy:
	@echo '=> Deploying platform...'
	@az deployment sub create --name 'Microsoft.Bicep.Resources' --location 'Norway East' --template-file './region.bicep'

validate:
	@echo '=> Validating platform...'
	@az deployment sub what-if --name 'Microsoft.Bicep.Resources' --location 'Norway East' --template-file './region.bicep'

bootstrap: variables
	@echo '=> Bootstrapping platform...'
	@az aks command invoke --name $(CLUSTER_NAME) --resource-group $(RESOURCE_GROUP) --command './bootstrap.sh $(TENANT_ID)' --file ./scripts/bootstrap.sh

destroy:
	@echo '=> Destroying platform...'
	@cat ../config/platform.json | jq -r '.endpoints.resourceGroup' | xargs -rtL1 az group delete --yes --name
	@cat ../config/platform.json | jq -r '.clusters[].resourceGroup' | xargs -rtL1 az group delete --yes --name
	@cat ../config/platform.json | jq -r '.services.resourceGroup' | xargs -rtL1 az group delete --yes --name
	@cat ../config/platform.json | jq -r '.zones.resourceGroup' | xargs -rtL1 az group delete --yes --name
	@-make purge

purge:
	@echo '=> Purging vaults...'
	@az keyvault list-deleted --query '[].name' -o tsv | xargs -rtL1 az keyvault purge --name
