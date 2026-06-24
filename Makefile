# renovate: datasource=github-tags depName=cloudogu/makefiles extractVersion=^v(?<version>.*)$
MAKEFILES_VERSION=10.6.0
VERSION=3.86.2-6

.DEFAULT_GOAL:=dogu-release

include build/make/variables.mk
include build/make/self-update.mk
include build/make/release.mk
include build/make/prerelease.mk
include build/make/k8s-dogu.mk
include build/make/bats.mk
