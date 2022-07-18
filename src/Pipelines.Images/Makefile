ifndef RESOURCE_GROUP
	$(error "RESOURCE_GROUP is not set")
endif

ifndef CLUSTER_NAME
	$(error "CLUSTER_NAME is not set")
endif

ifndef REGISTRY_NAME
	$(error "REGISTRY_NAME is not set")
endif

ifndef IMAGE_NAME
	$(error "IMAGE_NAME is not set")
endif

build:
	@echo "Building platform images..."
	@-make build-linux
	@-make build-windows

build-linux:
	@echo "Building linux image..."

build-windows:
	@echo "Building windows image..."

push:
	@echo "Pushing platform images..."
	@-make push-linux
	@-make push-windows

push-linux:
	@echo "Pushing linux image..."

push-windows:
	@echo "Pushing windows image..."
