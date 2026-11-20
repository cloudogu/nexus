# renovate: datasource=github-tags depName=cloudogu/makefiles extractVersion=^v(?<version>.*)$
MAKEFILES_VERSION=11.2.1
VERSION=3.98.2-0

.DEFAULT_GOAL:=dogu-release

include build/make/variables.mk
include build/make/self-update.mk
include build/make/release.mk
include build/make/prerelease.mk
include build/make/k8s-dogu.mk
include build/make/bats.mk
