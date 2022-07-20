variables:
	@echo "=> Checking environment variables..."
	@if [[ -z "$(RESOURCE_GROUP)" || -z "$(CLUSTER_NAME)" || -z "$(REGISTRY_NAME)" || -z "$(IMAGE_NAME)" ]]; then \
		$(error "Missing required environment variables"); \
	fi

build:
	@echo "=> Building platform images..."
	@-make build-linux
	@-make build-windows

build-linux:
	@echo "==> Building linux image..."

build-windows:
	@echo "==> Building windows image..."

push:
	@echo "=> Pushing platform images..."
	@-make push-linux
	@-make push-windows

push-linux:
	@echo "==> Pushing linux image..."

push-windows:
	@echo "==> Pushing windows image..."
