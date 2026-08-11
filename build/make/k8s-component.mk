COMPONENT_ARTIFACT_ID?=$(ARTIFACT_ID)
COMPONENT_BUILD_VERSION := $(shell date +%s)
COMPONENT_DEV_VERSION?=${VERSION}-dev.${COMPONENT_BUILD_VERSION}

# IMAGE_IMPORT_TARGET contains pre-helm apply make targets, specifically one that imports all things OCI into a local system.
IMAGE_IMPORT_TARGET=image-import

ifeq (${K8S_HELM_COMMON_MK_INCLUDE_MARKER}, )
	include ${BUILD_DIR}/make/k8s-helm-common.mk
endif

COMPONENT_POST_GENERATE_TARGETS?=
COMPONENT_PRE_APPLY_TARGETS ?=
K8S_RESOURCE_COMPONENT ?= "${K8S_RESOURCE_TEMP_FOLDER}/component-${COMPONENT_ARTIFACT_ID}-${VERSION}.yaml"
K8S_RESOURCE_COMPONENT_CR_TEMPLATE_YAML ?= $(BUILD_DIR)/make/k8s-component.tpl

##@ K8s - Component dev targets

.PHONY: component-generate
component-generate: ${K8S_RESOURCE_COMPONENT_CR_TEMPLATE_YAML} ${COMPONENT_POST_GENERATE_TARGETS} ## Generate the component yaml resource.

${K8S_RESOURCE_COMPONENT_CR_TEMPLATE_YAML}: ${K8S_RESOURCE_TEMP_FOLDER}
	@echo "Generating temporary K8s component resource: ${K8S_RESOURCE_COMPONENT}"
	@if [[ ${STAGE} == "development" ]]; then \
		sed "s|NAMESPACE|$(HELM_ARTIFACT_NAMESPACE)|g" "${K8S_RESOURCE_COMPONENT_CR_TEMPLATE_YAML}" | sed "s|NAME|$(COMPONENT_ARTIFACT_ID)|g"  | sed "s|VERSION|$(COMPONENT_DEV_VERSION)|g" > "${K8S_RESOURCE_COMPONENT}"; \
	else \
		sed "s|NAMESPACE|$(HELM_ARTIFACT_NAMESPACE)|g" "${K8S_RESOURCE_COMPONENT_CR_TEMPLATE_YAML}" | sed "s|NAME|$(COMPONENT_ARTIFACT_ID)|g"  | sed "s|VERSION|$(VERSION)|g" > "${K8S_RESOURCE_COMPONENT}"; \
	fi

.PHONY: component-apply
component-apply: isProduction check-k8s-namespace-env-var ${COMPONENT_PRE_APPLY_TARGETS} ${IMAGE_IMPORT_TARGET} helm-generate helm-chart-import component-generate ## Applies the component yaml resource to the actual defined context.
	@kubectl apply -f "${K8S_RESOURCE_COMPONENT}" --namespace="${NAMESPACE}" --context="${KUBE_CONTEXT_NAME}"
	@echo "Done."

.PHONY: component-delete
component-delete: check-k8s-namespace-env-var component-generate $(K8S_POST_GENERATE_TARGETS) ## Deletes the component yaml resource from the actual defined context.
	@kubectl delete -f "${K8S_RESOURCE_COMPONENT}" --namespace="${NAMESPACE}" --context="${KUBE_CONTEXT_NAME}" || true
	@echo "Done."

.PHONY: component-reinstall
component-reinstall: component-delete  component-apply ## Reinstalls the component yaml resource from the actual defined context.
