#
# Makefile
#

.PHONY: help build
.DEFAULT_GOAL := help


help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

# ----------------------------------------------------------------------------------------------------------------

install: ## Installs all dependencies
	curl -L https://www.svrunit.com/downloads/svrunit.zip --output svrunit.zip
	unzip -o svrunit.zip
	rm -f svrunit.zip

generate: ## Generates all artifacts for this image. You can use the local PHAR with: make generate phar=1
ifndef phar
	docker run -v ${PWD}:/opt/project orcabuilder/orca:latest
else
	curl -O https://www.svrunit.com/downloads/svrunit.zip --output svrunit.zip
	unzip -o svrunit.zip
	rm -f svrunit.zip
	php orca.phar --directory=.
endif

clear: ## Clears all dangling images
	docker images -aq -f 'dangling=true' | xargs docker rmi
	docker volume ls -q -f 'dangling=true' | xargs docker volume rm

# ----------------------------------------------------------------------------------------------------------------

verify: ## Verify the configuration of the provided tag [image=play tag=6.1.6]
ifndef tag
	$(warning Provide the required image tag using "make verify image=play tag=6.1.6")
	@exit 1;
else
	@php ./build/pipeline/verify-config.php $(image) $(tag)
endif

build: ## Builds the provided tag [image=play tag=6.1.6]
ifndef tag
	$(warning Provide the required image tag using "make build image=play tag=6.1.6")
	@exit 1;
else
	@cd ./dist/images/$(image)/$(tag) && DOCKER_BUILDKIT=1 docker build -t dockware/$(image):$(tag) .
endif

build-and-push-multiarch: ## Builds and pushes the provided tag [image=play tag=6.1.6]
ifndef tag
	$(warning Provide the required image tag using "make build image=play tag=6.1.6")
	@exit 1;
else
	docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
	docker buildx rm multiarch | true;
	docker buildx create --name multiarch --driver docker-container --use
	docker buildx inspect --bootstrap
	@cd ./dist/images/$(image)/$(tag) && DOCKER_BUILDKIT=1 docker buildx build --platform linux/amd64,linux/arm64 -t dockware/$(image):$(tag) --push .
	docker buildx rm multiarch
endif

test: ## Runs all SVRUnit Test Suites for the provided image and tag
	php svrunit.phar --configuration=./tests/svrunit/suites/$(image)/$(tag).xml --stop-on-error --report-junit --report-html
