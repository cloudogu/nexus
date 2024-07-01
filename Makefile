MAKEFILES_VERSION=9.1.0
VERSION=3.68.1-1

.DEFAULT_GOAL:=dogu-release

include build/make/variables.mk
include build/make/self-update.mk
include build/make/release.mk
include build/make/k8s-dogu.mk