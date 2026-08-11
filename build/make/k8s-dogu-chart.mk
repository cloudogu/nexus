# pre-overwrite variables in k8s-helm-common.mk

# HELM_ARTIFACT_ID contains the name of the dogu. It will be used for building helm charts or templating dogu CRs
HELM_ARTIFACT_ID=$(ARTIFACT_ID)
# IMAGE_IMPORT_TARGET contains pre-helm apply make targets, specifically one that imports all things OCI into a local system.
IMAGE_IMPORT_TARGET=image-import

ifeq (${K8S_HELM_COMMON_MK_INCLUDE_MARKER}, )
# note: Some variables may be imported indirectly from k8s.mk
	include ${BUILD_DIR}/make/k8s-helm-common.mk
endif

DOGU_V3_PRE_APPLY_TARGETS?=
DOGU_V3_POST_GENERATE_TARGETS?=
K8S_RESOURCE_DOGU_V3?="${K8S_RESOURCE_TEMP_FOLDER}/doguv3-${DOGU_V3_ARTIFACT_ID}-${VERSION}.yaml"
K8S_RESOURCE_DOGU_V3_CR_TEMPLATE_YAML?=${BUILD_DIR}/make/k8s-dogu.tpl

##@ K8s - Dogu v3 dev targets

.PHONY: dogu-v3-generate
dogu-v3-generate: ${K8S_RESOURCE_DOGU_V3} ${DOGU_V3_POST_GENERATE_TARGETS} ## Generate the dogu-v3 yaml resource.

${K8S_RESOURCE_DOGU_V3}: ${K8S_RESOURCE_DOGU_V3_CR_TEMPLATE_YAML} ${K8S_RESOURCE_TEMP_FOLDER}
	@echo "Generating temporary K8s dogu-v3 resource: $@"
	@if [[ ${STAGE} == "development" ]]; then \
		sed "s|NAMESPACE|$(HELM_ARTIFACT_NAMESPACE)|g" "${K8S_RESOURCE_DOGU_V3_CR_TEMPLATE_YAML}" | sed "s|NAME|$(DOGU_V3_ARTIFACT_ID)|g"  | sed "s|VERSION|$(DOGU_V3_DEV_VERSION)|g" > "$@"; \
	else \
		sed "s|NAMESPACE|$(HELM_ARTIFACT_NAMESPACE)|g" "${K8S_RESOURCE_DOGU_V3_CR_TEMPLATE_YAML}" | sed "s|NAME|$(DOGU_V3_ARTIFACT_ID)|g"  | sed "s|VERSION|$(VERSION)|g" > "$@"; \
	fi

.PHONY: dogu-v3-apply
dogu-v3-apply: check-k8s-namespace-env-var ${DOGU_V3_PRE_APPLY_TARGETS} ${IMAGE_IMPORT_TARGET} helm-generate helm-chart-import dogu-v3-generate ## Applies the component yaml resource to the actual defined context.
	@kubectl apply -f "${K8S_RESOURCE_DOGU_V3}" --namespace="${NAMESPACE}" --context="${KUBE_CONTEXT_NAME}"
	@echo "Done."

.PHONY: dogu-v3-delete
dogu-v3-delete: check-k8s-namespace-env-var dogu-v3-generate $(K8S_POST_GENERATE_TARGETS) ## Deletes the component yaml resource from the actual defined context.
	@kubectl delete -f "${K8S_RESOURCE_DOGU_V3}" --namespace="${NAMESPACE}" --context="${KUBE_CONTEXT_NAME}" || true
	@echo "Done."

.PHONY: dogu-v3-reinstall
dogu-v3-reinstall: dogu-v3-delete  dogu-v3-apply ## Reinstalls the dogu-v3 yaml resource from the actual defined context.
