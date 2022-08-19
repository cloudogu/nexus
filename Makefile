MAKEFILES_VERSION=6.0.3
VERSION=3.40.1-2

.DEFAULT_GOAL:=dogu-release

include build/make/variables.mk
include build/make/self-update.mk
include build/make/release.mk