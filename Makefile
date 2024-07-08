PKG_ID := $(shell yq -r '.id' manifest.yaml)
PKG_VERSION := $(shell yq -r '.version' manifest.yaml)
TS_FILES := $(shell find ./ -name \*.ts)
ASSET_PATHS := $(shell find ./assets/compat/*)

# delete the target of a rule if it has changed and its recipe exits with a nonzero exit status
.DELETE_ON_ERROR:

all: verify

debug-id:
	@echo "ID:" $(shell yq e '.id' manifest.yaml)

debug-version:
	@echo "Version:" $(shell yq e '.version' manifest.yaml)

verify: $(PKG_ID).s9pk
	@start-sdk verify s9pk $(PKG_ID).s9pk
	@echo " Done!"
	@echo "   Filesize: $(shell du -h $(PKG_ID).s9pk) is ready"

install: $(PKG_ID).s9pk
	start-cli package install $(PKG_ID).s9pk

clean:
	rm -rf docker-images
	rm -f image.tar
	rm -f $(PKG_ID).s9pk
	rm -f scripts/*.js

scripts/embassy.js: $(TS_FILES)
	deno bundle scripts/embassy.ts scripts/embassy.js

docker-images/x86_64.tar: Dockerfile docker_entrypoint.sh assets/utils/*
	mkdir -p docker-images
	docker buildx build --tag start9/$(PKG_ID)/main:$(PKG_VERSION) --platform=linux/amd64 --build-arg PLATFORM=amd64 -o type=docker,dest=docker-images/x86_64.tar .

# docker-images/aarch64.tar: Dockerfile docker_entrypoint.sh assets/utils/*
# 	mkdir -p docker-images
# 	docker buildx build --tag start9/$(PKG_ID)/main:$(PKG_VERSION) --platform=linux/arm64 --build-arg PLATFORM=arm64 -o type=docker,dest=docker-images/aarch64.tar .

# $(PKG_ID).s9pk: manifest.yaml instructions.md LICENSE icon.png scripts/embassy.js docker-images/aarch64.tar docker-images/x86_64.tar $(ASSET_PATHS)
# 	start-sdk pack
$(PKG_ID).s9pk: manifest.yaml instructions.md LICENSE icon.png scripts/embassy.js docker-images/x86_64.tar $(ASSET_PATHS)
	start-sdk pack
