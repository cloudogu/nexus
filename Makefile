MAKEFILES_VERSION=8.7.3
VERSION=3.59.0-1

.DEFAULT_GOAL:=dogu-release

include build/make/variables.mk
include build/make/self-update.mk
include build/make/release.mk
include build/make/k8s-dogu.mk