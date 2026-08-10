# renovate: datasource=github-tags depName=cloudogu/makefiles extractVersion=^v(?<version>.*)$
MAKEFILES_VERSION=10.10.0
VERSION=3.86.2-7

.DEFAULT_GOAL:=dogu-release


IMAGE_IMPORT_TARGET=image-import

include build/make/variables.mk
include build/make/self-update.mk
include build/make/release.mk
include build/make/prerelease.mk
include build/make/k8s-dogu.mk
include build/make/k8s-dogu-chart.mk
include build/make/bats.mk
include build/make/clean.mk

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
