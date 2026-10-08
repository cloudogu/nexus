# renovate: datasource=github-tags depName=cloudogu/makefiles extractVersion=^v(?<version>.*)$
MAKEFILES_VERSION=10.11.1
VERSION=3.86.2-7

.DEFAULT_GOAL:=dogu-release

include build/make/variables.mk
include build/make/self-update.mk
include build/make/release.mk
include build/make/prerelease.mk
include build/make/k8s-dogu.mk
include build/make/bats.mk

# -----------------------------------------------------------------------------
# TEMPORARY DoguV3 dev helper (#205)
#
# Builds + pushes the nexus image to the configured registry and (re)installs the
# Helm chart under k8s/helm into the configured cluster. Developer convenience for
# local testing only — the proper component build integration (k8s-component.mk etc.)
# is a separate story and intentionally NOT wired here.
#
#   make nexus-v3-install     # build + push image, then helm upgrade --install
#   make nexus-v3-uninstall   # helm uninstall
#
# Reuses existing infrastructure: image-import (build/tag/push) and the resolved
# IMAGE_DEV / BINARY_HELM / NAMESPACE / KUBE_CONTEXT_NAME from k8s.mk.
# -----------------------------------------------------------------------------

NEXUS_V3_RELEASE      ?= nexus
NEXUS_V3_HELM_SOURCE  ?= k8s/helm

# The chart composes the image as "<registry>/<repository>:<tag>", so the dev pull ref (IMAGE_DEV) must be split
NEXUS_V3_IMAGE_REPOSITORY = $(patsubst $(CES_REGISTRY_HOST)/%,%,$(IMAGE_DEV))

.PHONY: nexus-v3-install
nexus-v3-install: IMAGE = $(IMAGE_DEV_VERSION)
nexus-v3-install: image-import $(BINARY_HELM) ## DoguV3 dev: build+push the image and helm upgrade/install the chart.
	@echo "Installing DoguV3 release '$(NEXUS_V3_RELEASE)' into namespace '$(NAMESPACE)' (context '$(KUBE_CONTEXT_NAME)')..."
	@echo "  image: $(CES_REGISTRY_HOST)/$(NEXUS_V3_IMAGE_REPOSITORY):$(VERSION)"
	@$(BINARY_HELM) upgrade --install $(NEXUS_V3_RELEASE) $(NEXUS_V3_HELM_SOURCE) \
		--kube-context="$(KUBE_CONTEXT_NAME)" \
		--namespace $(NAMESPACE) \
		--set-string fullnameOverride=$(NEXUS_V3_RELEASE) \
		--set-string nexus.image.registry="$(CES_REGISTRY_HOST)" \
		--set-string nexus.image.repository="$(NEXUS_V3_IMAGE_REPOSITORY)" \
		--set-string nexus.image.tag="$(VERSION)" \
		--set-string nexus.imagePullPolicy=Always
	@echo "Done. Watch rollout: kubectl -n $(NAMESPACE) get pods -w"

.PHONY: nexus-v3-uninstall
nexus-v3-uninstall: $(BINARY_HELM) ## DoguV3 dev: uninstall the chart (keeps PVCs).
	@$(BINARY_HELM) --kube-context="$(KUBE_CONTEXT_NAME)" uninstall $(NEXUS_V3_RELEASE) --namespace $(NAMESPACE) || true
	@echo "Note: PVCs are retained. Delete them manually to reset data:"
	@echo "  kubectl -n $(NAMESPACE) delete pvc -l app.kubernetes.io/name=nexus"

# -----------------------------------------------------------------------------
# TEMPORARY DoguV3 publish helper
#
# Builds the nexus image and the Helm chart under k8s/helm and pushes both to an OCI registry.
# The packaged chart references exactly the pushed image (values.yaml and chart-patch-tpl.yaml are patched).
#
#   make nexus-v3-publish         # image + chart
#   make nexus-v3-publish-image   # image only
#   make nexus-v3-publish-chart   # chart only (references the image ref below)
#
# dev version for image tag and chart: $(VERSION)-dev.<unix-timestamp>
#   make nexus-v3-publish STAGE=development                                #
#
# Resulting artifacts (with defaults):
#   image: staging-registry.cloudogu.com/testing/dogu/v3/images/nexus:$(VERSION)
#   chart: oci://staging-registry.cloudogu.com/testing/dogu/v3/charts/nexus --version $(VERSION)
#
# -----------------------------------------------------------------------------

NEXUS_V3_PUBLISH_REGISTRY         ?= staging-registry.cloudogu.com
NEXUS_V3_PUBLISH_IMAGE_REPOSITORY ?= testing/dogu/v3/images/nexus
# OCI namespace for the chart; helm appends the chart name ("nexus") itself
NEXUS_V3_PUBLISH_CHART_NAMESPACE  ?= testing/dogu/v3/charts

# Image tag and chart version. ":=" evaluates the timestamp once, so both are identical.
ifndef NEXUS_V3_PUBLISH_VERSION
ifeq ($(STAGE),development)
NEXUS_V3_PUBLISH_VERSION := $(VERSION)-dev.$(shell date +%s)
else
NEXUS_V3_PUBLISH_VERSION := $(VERSION)
endif
endif

NEXUS_V3_PUBLISH_IMAGE = $(NEXUS_V3_PUBLISH_REGISTRY)/$(NEXUS_V3_PUBLISH_IMAGE_REPOSITORY):$(NEXUS_V3_PUBLISH_VERSION)
NEXUS_V3_PUBLISH_DIR = $(TARGET_DIR)/nexus-v3-publish
NEXUS_V3_PUBLISH_CHART_DIR = $(NEXUS_V3_PUBLISH_DIR)/nexus

.PHONY: nexus-v3-publish
nexus-v3-publish: nexus-v3-publish-image nexus-v3-publish-chart ## DoguV3: build+push image and chart to NEXUS_V3_PUBLISH_REGISTRY.

.PHONY: nexus-v3-publish-image
nexus-v3-publish-image: ## DoguV3: build+push the nexus image to NEXUS_V3_PUBLISH_REGISTRY.
	@echo "Building and pushing image $(NEXUS_V3_PUBLISH_IMAGE)..."
	@DOCKER_BUILDKIT=1 docker build . -t $(NEXUS_V3_PUBLISH_IMAGE)
	@docker push $(NEXUS_V3_PUBLISH_IMAGE)

.PHONY: nexus-v3-publish-chart
nexus-v3-publish-chart: $(BINARY_HELM) $(BINARY_YQ) ## DoguV3: package the chart (pinned to the published image) and push it.
	@echo "Packaging chart nexus:$(NEXUS_V3_PUBLISH_VERSION) with image $(NEXUS_V3_PUBLISH_IMAGE)..."
	@rm -rf $(NEXUS_V3_PUBLISH_DIR)
	@mkdir -p $(NEXUS_V3_PUBLISH_DIR)
	@cp -r $(NEXUS_V3_HELM_SOURCE) $(NEXUS_V3_PUBLISH_CHART_DIR)
	@REGISTRY="$(NEXUS_V3_PUBLISH_REGISTRY)" REPOSITORY="$(NEXUS_V3_PUBLISH_IMAGE_REPOSITORY)" TAG="$(NEXUS_V3_PUBLISH_VERSION)" \
		$(BINARY_YQ) -i '.nexus.image.registry = strenv(REGISTRY) | .nexus.image.repository = strenv(REPOSITORY) | .nexus.image.tag = strenv(TAG)' \
		$(NEXUS_V3_PUBLISH_CHART_DIR)/values.yaml
	@IMAGE="$(NEXUS_V3_PUBLISH_IMAGE)" \
		$(BINARY_YQ) -i '.values.images.nexus = strenv(IMAGE)' $(NEXUS_V3_PUBLISH_CHART_DIR)/chart-patch-tpl.yaml
	@CHART_VERSION="$(NEXUS_V3_PUBLISH_VERSION)" \
		$(BINARY_YQ) -i '.version = strenv(CHART_VERSION)' $(NEXUS_V3_PUBLISH_CHART_DIR)/Chart.yaml
	@$(BINARY_HELM) lint $(NEXUS_V3_PUBLISH_CHART_DIR)
	@$(BINARY_HELM) package $(NEXUS_V3_PUBLISH_CHART_DIR) -d $(NEXUS_V3_PUBLISH_DIR)
	@echo "Pushing chart to oci://$(NEXUS_V3_PUBLISH_REGISTRY)/$(NEXUS_V3_PUBLISH_CHART_NAMESPACE)..."
	@$(BINARY_HELM) push $(NEXUS_V3_PUBLISH_DIR)/nexus-$(NEXUS_V3_PUBLISH_VERSION).tgz \
		oci://$(NEXUS_V3_PUBLISH_REGISTRY)/$(NEXUS_V3_PUBLISH_CHART_NAMESPACE)
	@echo "Done."
	@echo "  image: $(NEXUS_V3_PUBLISH_IMAGE)"
	@echo "  chart: oci://$(NEXUS_V3_PUBLISH_REGISTRY)/$(NEXUS_V3_PUBLISH_CHART_NAMESPACE)/nexus --version $(NEXUS_V3_PUBLISH_VERSION)"
