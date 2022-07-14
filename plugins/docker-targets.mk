##########################################
# Creates a new component {comp}.{target}
# that builds a specific docker target
#
# Args:
# $1 = component name
# $2 = docker context
# $3 = dockerfile
# $4 = target
#
define target-factor
DOCKER_COMPONENTS += $1
$1_DOCKER_CONTEXT := $2
$1_DOCKER_FILE := $3
$1_DOCKER_BUILD_ARGS := --target $4
endef

##########################################
# Find the potential targets present in a 
# composant's dockerfile and store them
# in the variable {comp}_DOCKER_TARGETS
# Then factors the targets' image rules 
#
# Args:
# $1 path to a Dockerfile
# $2 name of docker component
define find-docker-targets
$2_DOCKER_TARGETS := $(shell grep -i -E '^FROM\s+[a-zA-Z\-_\/:0-9\.]+\s+AS\s+[a-zA-Z0-9\-_]+' $1 | cut -f4 -d' ')

$(foreach target,\
	$(shell grep -i -E '^FROM\s+[a-zA-Z\-_\/:0-9\.]+\s+AS\s+[a-zA-Z0-9\-_]+' $1 | cut -f4 -d' '),\
	$(eval $(call target-factor,$2.$(target),$2,$2/Dockerfile,$(target))))
endef

DOCKER_FILES := $(shell find * -maxdepth 1 -mindepth 1 -name "Dockerfile")
$(foreach file,$(DOCKER_FILES),$(eval $(call find-docker-targets,$(file),$(shell dirname $(file)))))
