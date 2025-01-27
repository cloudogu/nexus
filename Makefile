MAKEFILES_VERSION=9.5.2
VERSION=3.75.0-2

.DEFAULT_GOAL:=dogu-release

include build/make/variables.mk
include build/make/self-update.mk
include build/make/release.mk
include build/make/prerelease.mk
include build/make/k8s-dogu.mk