MAKEFILES_VERSION=7.6.0
VERSION=3.52.0-1

.DEFAULT_GOAL:=dogu-release

include build/make/variables.mk
include build/make/self-update.mk
include build/make/release.mk